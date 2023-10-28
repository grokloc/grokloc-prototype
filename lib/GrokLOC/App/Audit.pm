package GrokLOC::App::Audit;
use v5.38;
use strictures 2;
use Carp qw( croak );
use Crypt::Misc qw( random_v4uuid );
use Readonly ();
use GrokLOC qw( $RESPONSE_FAIL $RESPONSE_OK );
use GrokLOC::Log qw( LOG_ERROR );
use feature 'try';
no warnings 'experimental::try';

# ABSTRACT: Support for the audit table.

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

use base qw(Exporter);

Readonly::Scalar our $AUDIT_STATUS => 10;
Readonly::Scalar our $AUDIT_ORG_INSERT => 100;
Readonly::Scalar our $AUDIT_ORG_OWNER => 101;
Readonly::Scalar our $AUDIT_USER_INSERT => 200;
Readonly::Scalar our $AUDIT_USER_DISPLAY_NAME => 201;
Readonly::Scalar our $AUDIT_USER_PASSWORD => 202;
Readonly::Scalar our $AUDIT_USER_RE_ENCRYPT => 203;

Readonly::Scalar our $SCHEMA_VERSION => 0;

Readonly::Hash my %_CODES => (
  $AUDIT_STATUS => 1,
  $AUDIT_ORG_INSERT => 1,
  $AUDIT_ORG_OWNER => 1,
  $AUDIT_USER_INSERT => 1,
  $AUDIT_USER_DISPLAY_NAME => 1,
  $AUDIT_USER_PASSWORD => 1,
  $AUDIT_USER_RE_ENCRYPT => 1,
  );

sub create_audit ($master, %args) {
  unless (defined $_CODES{$args{code}}) {
    LOG_ERROR(code => $args{code});
    croak 'code fails';
  }
  unless (defined $args{source}) {
    LOG_ERROR(missing => 'source');
    croak 'source fails';
  }
  unless (defined $args{source_id}) {
    LOG_ERROR(missing => 'source_id');
    croak 'source_id fails';
  }

  try {
    $master->db->insert(
      'audit',
      {
        id             => random_v4uuid,
        code           => $args{code},
        source         => $args{source},
        source_id      => $args{source_id},
        schema_version => $SCHEMA_VERSION,
      },
      );
  } catch ($e) {
    LOG_ERROR(insert => $e);
    return $RESPONSE_FAIL;
  }
  return $RESPONSE_OK;
}

our @EXPORT_OK = qw(
  create_audit
  $AUDIT_STATUS
  $AUDIT_ORG_INSERT
  $AUDIT_ORG_OWNER
  $AUDIT_USER_INSERT
  $AUDIT_USER_DISPLAY_NAME
  $AUDIT_USER_PASSWORD
  $AUDIT_USER_RE_ENCRYPT
  );

1;

__END__
