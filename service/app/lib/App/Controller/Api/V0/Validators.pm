package App::Controller::Api::V0::Validators;
use v5.38;
use strictures 2;
use Mojo::Base 'Mojolicious::Controller';
use Crypt::Misc qw( is_v4uuid );
use GrokLOC qw(
  $AUTH_ORG
  $AUTH_USER
  $INTERNAL_ERROR
  $READ_USER
  $STASH_AUTH
  $STASH_ORG
  $STASH_USER
  );
use GrokLOC::App::Admin::User::Events::Read;
use GrokLOC::Log qw( LOG_DEBUG LOG_ERROR );

use feature 'try';
no warnings 'experimental::try';

# ABSTRACT: Validation handlers.

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

# with_id guarantees and id parameter of the right kind
sub with_id ($c) {
  unless (is_v4uuid $c->param('id')) {
    $c->render(
      format => 'json',
      json   => {error => 'id malformed or missing'},
      status => 400,
      );
    return undef;
  }
  return 1;
}

# with_user_id guarantees a user id parameter that
# is found and accessible by the caller
#
# the user for corresponding to param('id') will 
# be available in the stash as $READ_USER
sub with_user_id ($c) {

  # if caller is a regular user, must match the param id
  if (($c->stash($STASH_AUTH) == $AUTH_USER) &&
    ($c->stash($STASH_USER)->id ne $c->param('id'))) {
    $c->render(
      format => 'json',
      json => { error => 'user may only read their own record' },
      status => 403,
      );
    return undef;
  }

  my $read_event;
  try {
    $read_event = GrokLOC::App::Admin::User::Events::Read->new(id => $c->param('id'))->build->validate;
  }
  catch ($e) {
    LOG_DEBUG(read_event => $e);
    $c->render(
      format => 'json',
      json => {error => 'user args missing or malformed'},
      status => 400,
      );
    return undef;
  }

  my $user;
  try {
    $user = $c->user_controller->read($read_event);
  }
  catch ($e) {
    LOG_ERROR(read_user => $c->param('id'), caught => $e);
    $c->render(
      format => 'json',
      json => {error => $INTERNAL_ERROR},
      status => 500,
      );
    return undef;
  }

  if (!defined $user) {
    $c->render(
      format => 'json',
      json => {error => 'not found'},
      status => 404,
      );
    return undef;
  }

  # if caller is org owner, verify that user just read is in the same org
  if (($c->stash($STASH_AUTH) == $AUTH_ORG) &&
    ($c->stash($STASH_ORG)->id ne $user->org))  {
    $c->render(
      format => 'json',
      json => { error => 'user org does not match owner org' },
      status => 403,
      );
    return undef;
  }

  $c->stash($READ_USER => $user);
  return 1;
}

__END__
