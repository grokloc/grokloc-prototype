package GrokLOC::App::Admin::User::Events::Create;
use v5.38;
use Mojo::Base -base;
use strictures 2;
use Carp qw( croak );
use Crypt::Misc qw( is_v4uuid );
use Readonly ();
use GrokLOC::Crypt qw( is_argon2_password );
use GrokLOC::Log qw( LOG_ERROR );
use GrokLOC::Safe::Scalar qw( varchar );

# ABSTRACT: User create event.

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

our Readonly::Scalar $EVENT_VERSION => 0;

has ['display_name', 'email', 'org', 'password'] => q{};

sub build ($self) {
  return $self;
}

sub validate ($self) {
  unless (varchar $self->display_name) {
    LOG_ERROR(varchar => 'display_name');
    croak 'display_name fails';
  }
  unless (varchar $self->email) {
    LOG_ERROR(varchar => 'email');
    croak 'email fails';
  }
  unless (is_v4uuid $self->org) {
    LOG_ERROR(org => 'not is_v4uuid');
    croak 'org is not v4uuid';
  }
  unless (is_argon2_password $self->password) {
    LOG_ERROR(password => 'argon2');
    croak 'password fails';
  }
  return $self;
}

sub TO_JSON ($self) {
  {
    api_secret => $self->api_secret,
    display_name => $self->display_name,
    email => $self->email,
    org => $self->org,
    password => $self->password,
  }
}

__END__
