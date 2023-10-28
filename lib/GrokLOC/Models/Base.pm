package GrokLOC::Models::Base;
use v5.38;
use Mojo::Base -base;
use strictures 2;
use Carp qw( croak );
use Crypt::Misc qw( is_v4uuid random_v4uuid );
use GrokLOC qw(
  is_role
  is_status
  $MAX_SCHEMAVERSION
  $MAX_UNIXTIME
  $MIN_SCHEMAVERSION
  $MIN_UNIXTIME
  $ROLE_NORMAL
  $STATUS_UNCONFIRMED
  );
use GrokLOC::Log qw( LOG_ERROR );

# ABSTRACT: Base model class for all model instances.

our $VERSION = '0.0.1';
our $AUTHORITY = 'cpan:bclawsie';

has id => sub { random_v4uuid };
has ['ctime', 'mtime', 'schema_version'] => 0;
has role => $ROLE_NORMAL;
has signature => q{};
has status => $STATUS_UNCONFIRMED;

sub validate ($self) {
  unless (is_v4uuid($self->id)) {
    LOG_ERROR(id => $self->id);
    croak 'id fails';
  }
  if (($self->ctime !~ /^\d+$/x) ||
    (($self->ctime != 0) &&
      (!( $MIN_UNIXTIME <= $self->ctime <= $MAX_UNIXTIME)))) {
    LOG_ERROR(ctime => $self->ctime);
    croak 'ctime fails';
  }
  if (($self->mtime !~ /^\d+$/x) ||
    (($self->mtime != 0) &&
      (!( $MIN_UNIXTIME <= $self->mtime <= $MAX_UNIXTIME)))) {
    LOG_ERROR(mtime => $self->mtime);
    croak 'mtime fails';
  }
  unless (is_role $self->role) {
    LOG_ERROR(role => $self->role);
    croak 'role fails';
  }
  if (($self->schema_version !~ /^\d+$/x) ||
    (!($MIN_SCHEMAVERSION <= $self->schema_version <= $MAX_SCHEMAVERSION))) {
    LOG_ERROR(schema_version => $self->schema_version);
    croak 'schema_version fails';
  }
  if ((length $self->signature != 0) && (!is_v4uuid($self->signature))) {
    LOG_ERROR(signature => $self->signature);
    croak 'signature fails';
  }
  unless (is_status $self->status) {
    LOG_ERROR(status => $self->status);
    croak 'status fails';
  }
  return $self;
}

__END__
