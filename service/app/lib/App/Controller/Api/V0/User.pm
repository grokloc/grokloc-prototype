package App::Controller::Api::V0::User;
use v5.38;
use strictures 2;
use Carp qw( croak );
use Mojo::Base 'Mojolicious::Controller';
use GrokLOC qw(
  $AUTH_ORG
  $AUTH_USER
  $INADEQUATE_AUTHORIZATION
  $INTERNAL_ERROR
  $READ_USER
  $RESPONSE_CONFLICT
  $RESPONSE_NO_ROWS
  $RESPONSE_OK
  $STASH_AUTH
  $STASH_ORG
  $STATUS_INACTIVE
  $USER_ROUTE
  );
use GrokLOC::App::Admin::User::Events::Create ();
use GrokLOC::App::Admin::User::Events::UpdateDisplayName ();
use GrokLOC::App::Admin::User::Events::UpdatePassword ();
use GrokLOC::App::Admin::User::Events::UpdateStatus ();
use GrokLOC::Log qw( LOG_DEBUG LOG_ERROR LOG_WARNING );

use feature 'try';
no warnings 'experimental::try';

# ABSTRACT: User handlers.

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

sub post ($c) {

  # only root or org owner can create a user
  if ($c->stash($STASH_AUTH) == $AUTH_USER) {
    $c->render(
      format => 'json',
      json => { error => $INADEQUATE_AUTHORIZATION },
      status => 403,
      );
    return undef;
  }

  my %args = %{$c->req->json};

  # if caller is org owner, must be the owner of the same org user will
  # be created in
  if ($c->stash($STASH_AUTH) == $AUTH_ORG) {
    if ($c->stash($STASH_ORG)->id ne $args{org}) {
      $c->render(
        format => 'json',
        json => { error => 'candidate user org does not match owner org' },
        status => 403,
        );
      return undef;
    }
  }

  my $create_event;
  try {
    $create_event = GrokLOC::App::Admin::User::Events::Create->new(%args)->build->validate;
  }
  catch ($e) {
    LOG_DEBUG(create_event => $e);
    $c->render(
      format => 'json',
      json => {error => 'user args missing or malformed'},
      status => 400,
      );
    return undef;
  }

  my $user;
  try {
    $user = $c->user_controller->create($create_event);
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

  $c->res->headers->header('Location' => $USER_ROUTE . qw{/} . $user->id);
  return $c->render(
    format => 'json',
    json => $user->TO_JSON,
    status => 201,
    );
}

sub get ($c) {

  # with_user_id middleware populates read user as $READ_USER
  return $c->render(
    format => 'json',
    json => $c->stash($READ_USER)->TO_JSON,
    status => 200,
    );
}

sub put ($c) {
  my %args = %{$c->req->json};
  my $update_event;

  if (defined $args{display_name}) {
    try {
      $update_event = GrokLOC::App::Admin::User::Events::UpdateDisplayName->new(id => $c->param('id'), display_name => $args{display_name})->build->validate;
    }
    catch ($e) {
      LOG_DEBUG(update_event => $e);
      $c->render(
        format => 'json',
        json => {error => 'update display name args missing or malformed'},
        status => 400,
        );
      return undef;
    }
  } elsif (defined $args{password}) {
    try {
      $update_event = GrokLOC::App::Admin::User::Events::UpdatePassword->new(id => $c->param('id'), password => $args{password})->build->validate;
    }
    catch ($e) {
      LOG_DEBUG(update_event => $e);
      $c->render(
        format => 'json',
        json => {error => 'update status args missing or malformed'},
        status => 400,
        );
      return undef;
    }
  } elsif (defined $args{status}) {

    # regular user cannot change their own status
    if ($c->stash($STASH_AUTH) == $AUTH_USER) {
      $c->render(
        format => 'json',
        json => { error => $INADEQUATE_AUTHORIZATION },
        status => 403,
        );
      return undef;
    }

    try {
      $update_event = GrokLOC::App::Admin::User::Events::UpdateStatus->new(id => $c->param('id'), status => $args{status})->build->validate;
    }
    catch ($e) {
      LOG_DEBUG(update_event => $e);
      $c->render(
        format => 'json',
        json => {error => 'update status args missing or malformed'},
        status => 400,
        );
      return undef;
    }
  } else {
    LOG_DEBUG(unknown_update => join(q{,}, keys %args));
    $c->render(
      format => 'json',
      json => {error => 'no matching update found'},
      status => 400,
      );
    return undef;
  }

  my $update_resp;

  try {
    if ($update_event isa GrokLOC::App::Admin::User::Events::UpdateDisplayName) {
      $update_resp = $c->user_controller->update_display_name($update_event);
    } elsif ($update_event isa GrokLOC::App::Admin::User::Events::UpdatePassword) {
      $update_resp = $c->user_controller->update_password($update_event);
    } elsif ($update_event isa GrokLOC::App::Admin::User::Events::UpdateStatus) {
      $update_resp = $c->user_controller->update_status($update_event);
    } else {
      LOG_ERROR(unknown_event => $update_event);
      croak 'update event unknown';
    }
  }
  catch ($e) {
    LOG_ERROR(update_user => $c->param('id'), caught => $e);
    $c->render(
      format => 'json',
      json => {error => $INTERNAL_ERROR},
      status => 500,
      );
    return undef;
  }

  if ($update_resp == $RESPONSE_OK) {
    return $c->render(data => q{}, status => 204);
  }
  if ($update_resp == $RESPONSE_NO_ROWS) {
    LOG_WARNING(update_fail => 'no rows updated');
    $c->render(
      format => 'json',
      json => {error => 'no update performed'},
      status => 400,
      );
    return undef;
  }

  # unknown response
  LOG_ERROR(update_org => $c->param('id'), resp => $update_resp);
  $c->render(
    format => 'json',
    json => {error => $INTERNAL_ERROR},
    status => 500,
    );
  return undef;
}

sub del ($c) {

  # regular user cannot change their own status
  if ($c->stash($STASH_AUTH) == $AUTH_USER) {
    $c->render(
      format => 'json',
      json => { error => $INADEQUATE_AUTHORIZATION },
      status => 403,
      );
    return undef;
  }

  my $update_event;

  try {
    $update_event = GrokLOC::App::Admin::User::Events::UpdateStatus->new(id => $c->param('id'), status => $STATUS_INACTIVE)->build->validate;
  }
  catch ($e) {
    LOG_DEBUG(update_event => $e);
    $c->render(
      format => 'json',
      json => {error => 'update status args missing or malformed'},
      status => 400,
      );
    return undef;
  }

  my $update_resp;

  try {
    $update_resp = $c->user_controller->update_status($update_event);
  }
  catch ($e) {
    LOG_ERROR(update_user => $c->param('id'), caught => $e);
    $c->render(
      format => 'json',
      json => {error => $INTERNAL_ERROR},
      status => 500,
      );
    return undef;
  }

  if ($update_resp == $RESPONSE_OK) {
    return $c->render(data => q{}, status => 204);
  }
  if ($update_resp == $RESPONSE_NO_ROWS) {
    LOG_WARNING(update_fail => 'no rows updated');
    $c->render(
      format => 'json',
      json => {error => 'no update performed'},
      status => 400,
      );
    return undef;
  }

  # unknown response
  LOG_ERROR(update_user => $c->param('id'), resp => $update_resp);
  $c->render(
    format => 'json',
    json => {error => $INTERNAL_ERROR},
    status => 500,
    );
  return undef;
}

__END__
