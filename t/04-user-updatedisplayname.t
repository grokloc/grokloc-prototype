package main;
use v5.38;
use Crypt::Misc qw( random_v4uuid );
use English qw(-no_match_vars);
use Test2::V0 qw( done_testing note ok );
use Test2::Tools::Exception qw( dies lives );
use GrokLOC::App::Admin::User::Events::UpdateDisplayName ();

# ABSTRACT: org UpdateDisplayName event tests

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

ok(
  lives {
    my %args = (
      id => random_v4uuid,
      display_name => random_v4uuid,
      );
    GrokLOC::App::Admin::User::Events::UpdateDisplayName->new(%args)->build->validate
  },
  ) or note($EVAL_ERROR);

ok(
  dies {
    my %args = (
      display_name => random_v4uuid,
      );
    GrokLOC::App::Admin::User::Events::UpdateDisplayName->new(%args)->build->validate
  },
  ) or note($EVAL_ERROR);

ok(
  dies {
    my %args = (
      id => random_v4uuid,
      );
    GrokLOC::App::Admin::User::Events::UpdateDisplayName->new(%args)->build->validate
  },
  ) or note($EVAL_ERROR);

done_testing;
