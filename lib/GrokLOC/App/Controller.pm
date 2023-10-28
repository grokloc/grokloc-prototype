package GrokLOC::App::Controller;
use v5.38;
use Mojo::Base -base;
use strictures 2;
use Carp qw( croak );
use GrokLOC::Log qw( LOG_ERROR );

# ABSTRACT: Controller base class.

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

has st => undef;

sub validate ($self) {
  unless ((defined $self->st) && ($self->st isa 'GrokLOC::App::State')) {
    LOG_ERROR(st => 'not GrokOC::App::State');
    croak 'st not GrokLOC::App:State';
  }
}

__END__
