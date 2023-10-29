package GrokLOC::App::State;
use v5.38;
use Mojo::Base -base;
use strictures 2;
use Carp qw( croak );
use Crypt::Misc qw( is_v4uuid );
use GrokLOC::Log qw( LOG_ERROR );

# ABSTRACT: State object.

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

has ['master', 'replicas'] => undef;
has kdf_iterations => 0;
has repository_base => q{};
has signing_key => q{};
has version_key => undef;
has ['root_org', 'root_user'] => q{};

sub build ($self) {
  return $self;
}

sub validate ($self) {
  unless ($self->master isa 'Mojo::Pg') {
    LOG_ERROR(master => 'isa Mojo::Pg');
    croak 'master is not Mojo::Pg';
  }
  unless (ref($self->replicas) eq 'ARRAY') {
    LOG_ERROR(replica => 'ref ARRAY');
    croak 'replicas is not array ref';
  }
  for my $obj (@{$self->replicas}) {
    unless ($obj isa 'Mojo::Pg') {
      LOG_ERROR(replica => 'isa Mojo::Pg');
      croak 'obj not Mojo::Pg';
    }
  }
  unless (-d $self->repository_base) {
    LOG_ERROR(not_dir => $self->repository_base);
    croak 'repository_base not dir';
  }
  if ($self->signing_key eq q{}) {
    LOG_ERROR(signing_key => 'not set');
    croak 'signing_key not set';
  }
  unless (is_v4uuid $self->root_org) {
    LOG_ERROR(uuid => 'root_org');
    croak 'root_org is not uuid';
  }
  unless (is_v4uuid $self->root_user) {
    LOG_ERROR(uuid => 'root_user');
    croak 'root_user is not uuid';
  }
  return $self;
}

sub random_replica ($self) {
  return $self->replicas->[int rand scalar @{$self->replicas}];
}

__END__
