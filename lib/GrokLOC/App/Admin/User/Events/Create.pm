package GrokLOC::App::Admin::User::Events::Create;
use v5.38;
use Mojo::Base -base;
use strictures 2;
use Readonly ();

# ABSTRACT: User create event.

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

our Readonly::Scalar $EVENT_VERSION => 0;

has ['api_secret', 'display_name', 'email', 'org', 'password'] => q{};

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
