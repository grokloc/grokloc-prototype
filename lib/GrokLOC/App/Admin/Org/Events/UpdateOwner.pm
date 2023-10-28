package GrokLOC::App::Admin::Org::Events::UpdateOwner;
use v5.38;
use Mojo::Base -base;
use strictures 2;
use Carp qw( croak );
use Crypt::Misc qw( is_v4uuid );
use Readonly ();
use GrokLOC::Safe::Scalar qw( varchar );

# ABSTRACT: Org update owner event.

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

our Readonly::Scalar $EVENT_VERSION => 0;

has ['id', 'owner'] => q{};

sub build ($self) {
  return $self;
}

sub validate ($self) {
  unless (is_v4uuid $self->id) {
    LOG_ERROR(id => 'not is_v4uuid');
    croak 'id is not v4uuid';
  }
  unless (varchar $self->owner) {
    LOG_ERROR(varchar => 'owner');
    croak 'owner fails';
  }
  return $self;
}

sub TO_JSON ($self) {
  {
    id => $self->id,
    owner => $self->owner,
  }
}

__END__
