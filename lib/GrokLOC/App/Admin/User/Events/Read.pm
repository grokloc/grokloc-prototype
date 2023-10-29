package GrokLOC::App::Admin::User::Events::Read;
use v5.38;
use Mojo::Base -base;
use strictures 2;
use Carp qw( croak );
use Crypt::Misc qw( is_v4uuid );
use Readonly ();

# ABSTRACT: User read event.

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

our Readonly::Scalar $EVENT_VERSION => 0;

has id => q{};
has master => 0;

sub build ($self) {
  return $self;
}

sub validate ($self) {
  unless (is_v4uuid $self->id) {
    LOG_ERROR(id => 'not is_v4uuid');
    croak 'id is not v4uuid';
  }
  unless ($self->master == 0 || $self->master == 1) {
    LOG_ERROR(master => 'not 0 or 1');
    croak 'master is not 0 or 1';
  }
  return $self;
}

sub TO_JSON ($self) {
  {
    id => $self->id,
    master => $self->master,
  }
}

__END__
