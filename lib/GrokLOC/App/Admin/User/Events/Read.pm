package GrokLOC::App::Admin::User::Events::Read;
use v5.38;
use Mojo::Base -base;
use strictures 2;
use Readonly ();

# ABSTRACT: User read event.

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

our Readonly::Scalar $EVENT_VERSION => 0;

has id => q{};
has master => 0;

sub TO_JSON ($self) {
  {
    id => $self->id,
    master => $self->master,
  }
}

__END__
