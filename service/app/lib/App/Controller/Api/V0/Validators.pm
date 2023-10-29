package App::Controller::Api::V0::Validators;
use v5.38;
use strictures 2;
use Mojo::Base 'Mojolicious::Controller';
use Crypt::Misc qw( is_v4uuid );

# ABSTRACT: Validation handlers.

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

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

__END__
