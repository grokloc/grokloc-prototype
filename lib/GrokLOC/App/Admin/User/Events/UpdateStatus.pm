package GrokLOC::App::Admin::User::Events::UpdateStatus;
use v5.38;
use Mojo::Base -base;
use strictures 2;
use Readonly ();

# ABSTRACT: User update status event.

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

our Readonly::Scalar $EVENT_VERSION => 0;

has id => q{};
has status => -1; # an impossible status

sub TO_JSON ($self) {
  {
    id => $self->id,
    status => $self->status,
  }
}

__END__
