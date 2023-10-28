package GrokLOC::App::State::Global;
use v5.38;
use strictures 2;

# ABSTRACT: A global state ref.

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

use base qw(Exporter);

# make the state instance available as a pkg var - this aids testing
#
# should be undef unless running in UNIT env
our $ST;
our @EXPORT_OK = qw($ST);

__END__
