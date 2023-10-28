package main;
use v5.38;
use Crypt::Misc qw( random_v4uuid );
use English qw(-no_match_vars);
use Test2::V0 qw( done_testing note ok );
use Test2::Tools::Exception qw( dies lives );
use GrokLOC::App::Admin::Org::Events::Read ();

# ABSTRACT: org Read event tests

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

ok(
  lives {
    my %args = (
      id => random_v4uuid,
      master => 1,
      );
    GrokLOC::App::Admin::Org::Events::Read->new(%args)->build->validate
  },
  ) or note($EVAL_ERROR);

ok(
  dies {
    my %args = (
      master => 1,
      );
    GrokLOC::App::Admin::Org::Events::Read->new(%args)->build->validate
  },
  ) or note($EVAL_ERROR);

ok(
  dies {
    my %args = (
      id => random_v4uuid,
      master => 3,
      );
    GrokLOC::App::Admin::Org::Events::Read->new(%args)->build->validate
  },
  ) or note($EVAL_ERROR);

done_testing;
