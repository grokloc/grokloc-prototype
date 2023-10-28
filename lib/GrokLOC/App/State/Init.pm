package GrokLOC::App::State::Init;
use v5.38;
use Carp qw( croak );
use strictures 2;
use GrokLOC qw( $ENV_UNIT );
use GrokLOC::App::State::Global qw( $ST );
use GrokLOC::App::State::Unit ();

# ABSTRACT: Initialize State instances for an environment.

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

use base qw(Exporter);

sub state_from_env ($env) {
  if ($env eq $ENV_UNIT) {
    $ST = GrokLOC::App::State::Unit::new;
    return $ST;
  }
  croak "no support yet for env $env";
}

our @EXPORT_OK = qw(state_from_env);

__END__
