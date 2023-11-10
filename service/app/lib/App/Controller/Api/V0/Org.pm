package App::Controller::Api::V0::Org;
use v5.38;
use strictures 2;
use Mojo::Base 'Mojolicious::Controller';
use Carp qw( croak );
use GrokLOC qw(
  $AUTH_ROOT
  $INADEQUATE_AUTHORIZATION
  $INTERNAL_ERROR
  $ORG_ROUTE
  $RESPONSE_CONFLICT
  $RESPONSE_NO_ROWS
  $RESPONSE_OK
  $STASH_AUTH
  $STASH_ORG
  );
use GrokLOC::App::Admin::Org::Events::Create ();
use GrokLOC::App::Admin::Org::Events::Read ();
use GrokLOC::App::Admin::Org::Events::UpdateOwner ();
use GrokLOC::App::Admin::Org::Events::UpdateStatus ();
use GrokLOC::Log qw( LOG_DEBUG LOG_ERROR LOG_WARNING );

use feature 'try';
no warnings 'experimental::try';

# ABSTRACT: Org handlers.

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

sub post ($c) {

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
    LOG_DEBUG(create_event => $e);
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

sub get ($c) {

  # the org is normally stashed already from the with_user middleware,
  # but if the caller is root, the requested org to be read could be any
  if ($c->stash($STASH_AUTH) == $AUTH_ROOT) {
    my $read_event = GrokLOC::App::Admin::Org::Events::Read->new(id => $c->param('id'));
    my $org;
    try {
      $org = $c->org_controller->read($read_event);
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

    unless (defined $org) {
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
  #
  # even if the org requested is fictitious, do not leak this
  # to non-root caller with a 404...all they need to know is 403
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

sub put ($c) {

  # only root can update an org
  if ($c->stash($STASH_AUTH) != $AUTH_ROOT) {
    $c->render(
      format => 'json',
      json => { error => $INADEQUATE_AUTHORIZATION },
      status => 403,
      );
    return undef;
  }

  my %args = %{$c->req->json};
  my $update_event;

  if (defined $args{owner}) {
    try {
      $update_event = GrokLOC::App::Admin::Org::Events::UpdateOwner->new(id => $c->param('id'), owner => $args{owner})->build->validate;
    }
    catch ($e) {
      LOG_DEBUG(update_event => $e);
      $c->render(
        format => 'json',
        json => {error => 'update owner args missing or malformed'},
        status => 400,
        );
      return undef;
    }
  } elsif (defined $args{status}) {
    try {
      $update_event = GrokLOC::App::Admin::Org::Events::UpdateStatus->new(id => $c->param('id'), status => $args{status})->build->validate;
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
    if ($update_event isa GrokLOC::App::Admin::Org::Events::UpdateOwner) {
      $update_resp = $c->org_controller->update_owner($update_event);
    } elsif ($update_event isa GrokLOC::App::Admin::Org::Events::UpdateStatus) {
      $update_resp = $c->org_controller->update_status($update_event);
    } else {
      LOG_ERROR(unknown_event => $update_event);
      croak 'update event unknown';
    }
  }
  catch ($e) {
    LOG_ERROR(update_org => $c->param('id'), caught => $e);
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

__END__
