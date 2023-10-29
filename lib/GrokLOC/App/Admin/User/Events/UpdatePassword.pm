package GrokLOC::App::Admin::User::Events::UpdatePassword;
use v5.38;
use Mojo::Base -base;
use strictures 2;
use Carp qw( croak );
use Crypt::Misc qw( is_v4uuid );
use Readonly ();
use GrokLOC::Crypt qw( is_argon2_password );
use GrokLOC::Log qw( LOG_ERROR );

# ABSTRACT: User update password event.

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

our Readonly::Scalar $EVENT_VERSION => 0;

has ['id', 'password'] => q{};

sub build ($self) {
  return $self;
}

sub validate ($self) {
  unless (is_v4uuid $self->id) {
    LOG_ERROR(id => 'not is_v4uuid');
    croak 'id is not v4uuid';
  }
  unless (is_argon2_password $self->password) {
    LOG_ERROR(password => 'not is_argon2_password');
    croak 'password is not argon2 password';
  }
  return $self;
}

sub TO_JSON ($self) {
  {
    id => $self->id,
    password => $self->password,
  }
}

__END__
