package App::Controller::Api::V0::Status;
use v5.38;
use strictures 2;
use Mojo::Base 'Mojolicious::Controller';
use GrokLOC qw( $AUTH_ROOT $INADEQUATE_AUTHORIZATION $STASH_AUTH );

# ABSTRACT: Status handler.

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

sub status ($c) {

  # only show runtime details to root
  if ($c->stash($STASH_AUTH) != $AUTH_ROOT) {
    $c->render(
      format => 'json',
      json   => {error => $INADEQUATE_AUTHORIZATION},
      status => 403,
      );
    return undef;
  }
  return $c->render(
    format => 'json',
    json   => {started_at => $c->started_at},
    status => 200,
    );
}

__END__
