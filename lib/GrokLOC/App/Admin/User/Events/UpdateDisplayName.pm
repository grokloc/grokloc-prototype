package GrokLOC::App::Admin::User::Events::UpdateDisplayName;
use v5.38;
use Mojo::Base -base;
use strictures 2;
use Readonly ();

# ABSTRACT: User update display name event.

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

our Readonly::Scalar $EVENT_VERSION => 0;

has ['id', 'display_name'] => q{};

sub TO_JSON ($self) {
  {
    id => $self->id,
    display_name => $self->display_name,
  }
}

__END__
