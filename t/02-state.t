package main;
use v5.38;
use English qw(-no_match_vars);
use Test2::V0 qw( done_testing note ok );
use Test2::Tools::Exception qw( lives );
use strictures 2;
use GrokLOC qw( $ENV_UNIT );
use GrokLOC::App::State::Init qw( state_from_env );

# ABSTRACT: state setup tests

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

# ok
ok(
  lives {
    state_from_env($ENV_UNIT);
  },
  ) or note($EVAL_ERROR);

done_testing;
