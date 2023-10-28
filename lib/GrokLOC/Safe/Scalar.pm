package GrokLOC::Safe::Scalar;
use v5.38;
use strictures 2;
use Readonly ();

# ABSTRACT: Verify safety of non-string scalar types of interest.

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

use base qw(Exporter);

# value limits
Readonly::Scalar our $STR_MAX => 8192;

# varchar finds strings unwelcome in dbs or webpages
sub varchar ($s) {
  return undef unless (defined $s);
  return undef if length $s == 0;
  return undef if length $s > $STR_MAX;
  return undef if ($s =~ /[\<\>\'\"\`]/msx);
  return undef if ($s =~ /drop\s/imsx);
  return undef if ($s =~ /create\s/imsx);
  return undef if ($s =~ /insert\s/imsx);
  return undef if ($s =~ /update\s/imsx);
  return undef if ($s =~ /\&gt\;/imsx);
  return undef if ($s =~ /\&lt\;/imsx);
  return undef if ($s =~ /window[.]/msx);
  return 1;
}

our @EXPORT_OK = qw(
  varchar
  );

__END__
