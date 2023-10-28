package GrokLOC::App::Admin::Org::Events::Create;
use v5.38;
use Mojo::Base -base;
use strictures 2;
use Carp qw( croak );
use Readonly ();
use GrokLOC qw( is_role $ROLE_NORMAL );
use GrokLOC::Crypt qw( is_argon2_password );
use GrokLOC::Log qw( LOG_ERROR );
use GrokLOC::Safe::Scalar qw( varchar );

# ABSTRACT: Org create event.

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

our Readonly::Scalar $EVENT_VERSION => 0;

has ['name', 'owner_display_name', 'owner_email', 'owner_password'] => q{};
has role => $ROLE_NORMAL;

sub build ($self) {
  return $self;
}

sub validate ($self) {
  unless (varchar $self->name) {
    LOG_ERROR(varchar => 'name');
    croak 'name fails';
  }
  unless (varchar $self->owner_display_name) {
    LOG_ERROR(varchar => 'owner_display_name');
    croak 'owner_display_name fails';
  }
  unless (varchar $self->owner_email) {
    LOG_ERROR(varchar => 'owner_email');
    croak 'owner_email fails';
  }
  unless (is_argon2_password $self->owner_password) {
    LOG_ERROR(owner_password => 'argon2');
    croak 'owner_password fails';
  }
  unless (is_role $self->role) {
    LOG_ERROR(role => 'invalid');
    croak 'role fails';
  }
  return $self;
}

sub TO_JSON ($self) {
  {
    name => $self->name,
    owner_display_name => $self->owner_display_name,
    owner_email => $self->owner_email,
    owner_password => $self->owner_password,
    role => $self->role,
  }
}

__END__
