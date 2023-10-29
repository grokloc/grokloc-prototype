package GrokLOC::App::Admin::User::Events::UpdateStatus;
use v5.38;
use Mojo::Base -base;
use strictures 2;
use Carp qw( croak );
use Crypt::Misc qw( is_v4uuid );
use Readonly ();
use GrokLOC qw( is_status );

# ABSTRACT: User update status event.

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

our Readonly::Scalar $EVENT_VERSION => 0;

has id => q{};
has status => -1; # an impossible status

sub build ($self) {
  return $self;
}

sub validate ($self) {
  unless (is_v4uuid $self->id) {
    LOG_ERROR(id => 'not is_v4uuid');
    croak 'id is not v4uuid';
  }
  unless (is_status $self->status) {
    LOG_ERROR(varchar => 'status');
    croak 'status fails';
  }
  return $self;
}

sub TO_JSON ($self) {
  {
    id => $self->id,
    status => $self->status,
  }
}

__END__
