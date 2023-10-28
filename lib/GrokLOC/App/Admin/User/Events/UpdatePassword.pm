package GrokLOC::App::Admin::User::Events::UpdatePassword;
use v5.38;
use Mojo::Base -base;
use strictures 2;
use Readonly ();

# ABSTRACT: User update password event.

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

our Readonly::Scalar $EVENT_VERSION => 0;

has ['id', 'password'] => q{};

sub TO_JSON ($self) {
  {
    id => $self->id,
    password => $self->password,
  }
}

__END__
