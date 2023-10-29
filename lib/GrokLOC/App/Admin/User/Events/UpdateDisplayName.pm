package GrokLOC::App::Admin::User::Events::UpdateDisplayName;
use v5.38;
use Mojo::Base -base;
use strictures 2;
use Carp qw( croak );
use Crypt::Misc qw( is_v4uuid );
use Readonly ();
use GrokLOC::Safe::Scalar qw( varchar );

# ABSTRACT: User update display name event.

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

our Readonly::Scalar $EVENT_VERSION => 0;

has ['id', 'display_name'] => q{};

sub build ($self) {
  return $self;
}

sub validate ($self) {
  unless (is_v4uuid $self->id) {
    LOG_ERROR(id => 'not is_v4uuid');
    croak 'id is not v4uuid';
  }
  unless (varchar $self->display_name) {
    LOG_ERROR(varchar => 'display_name');
    croak 'display_name fails';
  }
  return $self;
}

sub TO_JSON ($self) {
  {
    id => $self->id,
    display_name => $self->display_name,
  }
}

__END__
