package App::Controller::Api::V0::Auth;
use v5.38;
use strictures 2;
use Crypt::Misc qw( is_v4uuid );
use Mojo::Base 'Mojolicious::Controller';
use GrokLOC qw(
  $AUTH_NONE
  $AUTH_ORG
  $AUTH_ROOT
  $AUTH_USER
  $AUTHORIZATION_HEADER
  $INTERNAL_ERROR
  $JWT_EXPIRATION
  $STASH_AUTH
  $STASH_ORG
  $STASH_USER
  $STATUS_ACTIVE
  $X_GROKLOC_ID_HEADER
  $X_GROKLOC_TOKEN_REQUEST_HEADER
  );
use GrokLOC::App::Admin::Org::Events::Read ();
use GrokLOC::App::Admin::User::Events::Read ();
use GrokLOC::App::JWT qw(
  decode_token
  encode_token
  token_from_header_val
  verify_token_request
  );
use GrokLOC::Log qw( LOG_DEBUG LOG_ERROR LOG_INFO );

use feature 'try';
no warnings 'experimental::try';

# ABSTRACT: Authorization handlers.

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

# with_user is a middleware that will fill the stash with user and org instances
# subsequent chained handlers can be assured of a stashed user and org
# subsequent chained handlers can be assured of a minumum auth level of $AUTH_USER
# subsequent chained handlers can be assured calling user and org are $STATUS_ACTIVE
sub with_user ($c) {
  $c->stash($STASH_AUTH => $AUTH_NONE);

  # X-GrokLOC-ID header must be present in order to look up the user
  unless ($c->req->headers->header($X_GROKLOC_ID_HEADER)) {
    $c->render(
      format => 'json',
      json => {error => 'missing:' . $X_GROKLOC_ID_HEADER},
      status => 400,
      );
    return undef;
  }

  my $user_id = $c->req->headers->header($X_GROKLOC_ID_HEADER);

  unless (is_v4uuid $user_id) {
    $c->render(
      format => 'json',
      json => {error => 'id malformed'},
      status => 400,
      );
    return undef;
  }

  my $user;
  my $user_read_event = GrokLOC::App::Admin::User::Events::Read->new(id => $user_id);
  try {
    $user = $c->user_controller->read($user_read_event);
  }
  catch ($e) {
    LOG_ERROR(read_user => $user_id, caught => $e);
    $c->render(
      format => 'json',
      json => {error => $INTERNAL_ERROR},
      status => 500,
      );
    return undef;
  }

  unless (defined $user && $user->status == $STATUS_ACTIVE) {
    $c->render(
      format => 'json',
      json => {error => 'authorizing user not found or inactive'},
      status => 404,
      );
    return undef;
  }

  my $org;
  my $org_read_event = GrokLOC::App::Admin::Org::Events::Read->new(id => $user->org);
  try {
    $org = $c->org_controller->read($org_read_event);
  }
  catch ($e) {
    LOG_ERROR(read_org => $org, caught => $e);
    $c->render(
      format => 'json',
      json => {error => $INTERNAL_ERROR},
      status => 500,
      );
    return undef;
  }

  unless (defined $org && $org->status == $STATUS_ACTIVE) {
    $c->render(
      format => 'json',
      json => {error => 'authorizing org not found or inactive'},
      status => 400,
      );
    return undef;
  }

  my $auth_level = $AUTH_USER;
  if ($org->id eq $c->st->root_org) {

    # allow for multiple accounts in root org (not used in practice)
    $auth_level = $AUTH_ROOT;
  }
  elsif ($org->owner eq $user->id) {
    $auth_level = $AUTH_ORG;
  }

  $c->stash($STASH_AUTH => $auth_level);
  $c->stash($STASH_ORG => $org);
  $c->stash($STASH_USER => $user);
  return 1;
}

# with_token calls to with_user but also requires that the auth
# level include a token setting (user, org or root) to continue
sub with_token ($c) {
  unless ($c->with_user) {
    LOG_ERROR(with_user => 'failed');
    return undef;
  }

  unless ($c->req->headers->header($AUTHORIZATION_HEADER)) {
    $c->render(
      format => 'json',
      json => {error => 'missing ' . $AUTHORIZATION_HEADER},
      status => 400,
      );
    return undef;
  }

  try {
    my $encoded =
      token_from_header_val(
      $c->req->headers->header($AUTHORIZATION_HEADER));
    my $decoded = decode_token($encoded, $c->st->signing_key);
    unless ($decoded->{'sub'} eq $c->stash($STASH_USER)->id) {
      $c->render(
        format => 'json',
        json => {error => 'token contents incorrect'},
        status => 400,
        );
      return undef;
    }
    my $now = time;
    if ($decoded->{exp} < $now) {
      $c->render(
        format => 'json',
        json => {error => 'token expired'},
        status => 400,
        );
      return undef;
    }
  }
  catch ($e) {
    LOG_DEBUG(token_decode => $e);
    $c->render(
      format => 'json',
      json => {error => 'token decode error'},
      status => 400,
      );
    return undef;
  }

  return 1;
}

# new_token mints a new jwt for a user if the token request header
# validates
# should be treated as a POST handler since a new jwt is always
# minted, but note that unlike typical POSTs, there is no redirect or Location
# header in the response, only the value of the jwt
sub new_token ($c) {
  my $token_request =
    $c->req->headers->header($X_GROKLOC_TOKEN_REQUEST_HEADER);
  unless (defined $token_request) {
    $c->render(
      format => 'json',
      json => {error => 'missing:' . $X_GROKLOC_TOKEN_REQUEST_HEADER},
      status => 400,
      );
    return undef;
  }

  my $calling_user = $c->stash($STASH_USER);
  unless (
    verify_token_request($token_request, $calling_user->id, $calling_user->api_secret))
  {
    $c->render(
      format => 'json',
      json => {error => 'bad token request'},
      status => 401,
      );
    return undef;
  }

  my $now = time;
  my $token;
  try {
    $token = encode_token($calling_user->id, $c->st->signing_key);
  }
  catch ($e) {
    LOG_ERROR(encode_token => 'failed', user_id => $calling_user->id, caught => $e);
    $c->render(
      format => 'json',
      json => {error => $INTERNAL_ERROR},
      status => 500,
      );
    return undef;
  }

  LOG_INFO(user_id => $calling_user->id, token => 'newly made');
  return $c->render(
    format => 'json',
    json => {
      token => $token,
      expires => $now + $JWT_EXPIRATION - 30,
      },
    status => 200,
    );
}

__END__
