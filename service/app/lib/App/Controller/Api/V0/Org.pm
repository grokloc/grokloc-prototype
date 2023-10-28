package App::Controller::Api::V0::Org;
use v5.38;
use strictures 2;
use Mojo::Base 'Mojolicious::Controller';
use GrokLOC qw(
  $AUTH_ROOT
  $INADEQUATE_AUTHORIZATION
  $INTERNAL_ERROR
  $ORG_ROUTE
  $RESPONSE_CONFLICT
  $STASH_AUTH
  $STASH_ORG
  );
use GrokLOC::App::Admin::Org::Events::Create ();
use GrokLOC::App::Admin::Org::Events::Read ();
use GrokLOC::Log qw( LOG_ERROR );

use feature 'try';
no warnings 'experimental::try';

# ABSTRACT: Org handlers.

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

sub create ($c) {

  # only root can create an org
  if ($c->stash($STASH_AUTH) != $AUTH_ROOT) {
    $c->render(
      format => 'json',
      json => { error => $INADEQUATE_AUTHORIZATION },
      status => 403,
      );
    return undef;
  }

  my %args = %{$c->req->json};
  my $create_event;
  try {
    $create_event = GrokLOC::App::Admin::Org::Events::Create->new(%args)->build->validate;
  }
  catch ($e) {
    LOG_ERROR(create_event => $e);
    $c->render(
      format => 'json',
      json => {error => 'org args missing or malformed'},
      status => 400,
      );
    return undef;
  }

  my $org;
  try {
    $org = $c->org_controller->create($create_event);
  }
  catch ($e) {
    if ($e =~ /^$RESPONSE_CONFLICT/x)
    {
      $c->render(
        format => 'json',
        json => {error => $e},
        status => 409,
        );
      return undef;
    }

    # otherwise, an unknown error
    LOG_ERROR(create => $e);
    $c->render(
      format => 'json',
      json => {error => $INTERNAL_ERROR},
      status => 500,
      );
    return undef;
  }

  $c->res->headers->header('Location' => $ORG_ROUTE . qw{/} . $org->id);
  return $c->render(
    format => 'json',
    json   => $org->TO_JSON,
    status => 201,
    );
}

sub read ($c) {

  # the org is normally stashed already from the with_user middleware,
  # but if the caller is root, the requested org to be read could be any
  if ($c->stash($STASH_AUTH) == $AUTH_ROOT) {
    my $read_event = GrokLOC::App::Admin::Org::Events::Read->new(id => $c->param('id'));
    my $org;
    try {
      $org = $c->org_controller->read($c->param('id'));
    }
    catch ($e) {
      LOG_ERROR(read_org => $c->param('id'), caught => $e);
      $c->render(
        format => 'json',
        json => {error => $INTERNAL_ERROR},
        status => 500,
        );
      return undef;
    }

    if (!defined $org) {
      $c->render(
        format => 'json',
        json => {error => 'not found'},
        status => 404,
        );
      return undef;
    }

    return $c->render(
      format => 'json',
      json => $org->TO_JSON(),
      status => 200,
      );
  }

  # otherwise, if not root, the requested id must match the stashed org
  # (the caller's org detected from their user id)
  my $calling_org = $c->stash($STASH_ORG);
  if ($c->param('id') ne $calling_org->id) {
    $c->render(
      format => 'json',
      json => {error => 'not a member of requested org'},
      status => 403,
      );
    return undef;
  }

  return $c->render(
    format => 'json',
    json => $calling_org->TO_JSON(),
    status => 200,
    );
}

__END__
