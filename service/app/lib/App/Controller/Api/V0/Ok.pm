package App::Controller::Api::V0::Ok;
use v5.38;
use strictures 2;
use Mojo::Base 'Mojolicious::Controller';

# ABSTRACT: Ok (unathenticated ping) handler.

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

sub ok ( $c ) {
  return $c->render(
    format => 'json',
    json   => {ping => 'ok'},
    status => 200,
    );
}

__END__
