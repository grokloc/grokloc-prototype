package GrokLOC::Crypt::VersionKey;
use v5.38;
use Mojo::Base -base;
use strictures 2;
use Carp qw( croak );
use Crypt::Misc qw( is_v4uuid );

# ABSTRACT: Map encryption key ids to key values.

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

has keymap => undef;
has current => q{};

sub build ($self) {
  return $self;
}

sub validate ($self) {
  croak 'keymap must be hash ref' unless ref($self->keymap) eq 'HASH';
  croak 'current must be set in keymap' unless defined $self->keymap->{$self->current};
  for my $key (keys(%{$self->keymap})) {
    croak 'key not in uuid form' unless is_v4uuid $key;
  }
  return $self;
}

__END__
