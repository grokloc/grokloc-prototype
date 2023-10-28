package main;
use v5.38;
use Crypt::Misc qw( random_v4uuid );
use English qw(-no_match_vars);
use Test2::V0 qw( done_testing note ok );
use Test2::Tools::Exception qw( dies lives );
use GrokLOC::App::Admin::Org::Events::Create ();
use GrokLOC::Crypt qw( rand_argon2_password );

# ABSTRACT: org Create event tests

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

ok(
  lives {
    my %args = (
      name => random_v4uuid,
      owner_display_name => random_v4uuid,
      owner_email => random_v4uuid,
      owner_password => rand_argon2_password,
      );
    GrokLOC::App::Admin::Org::Events::Create->new(%args)->build->validate
  },
  ) or note($EVAL_ERROR);

ok(
  dies {
    my %args = (
      name => random_v4uuid,
      owner_email => random_v4uuid,
      owner_password => rand_argon2_password,
      );
    GrokLOC::App::Admin::Org::Events::Create->new(%args)->build->validate
  },
  ) or note($EVAL_ERROR);

ok(
  dies {
    my %args = (
      name => random_v4uuid,
      owner_display_name => random_v4uuid,
      owner_password => rand_argon2_password,
      );
    GrokLOC::App::Admin::Org::Events::Create->new(%args)->build->validate
  },
  ) or note($EVAL_ERROR);

ok(
  dies {
    my %args = (
      name => random_v4uuid,
      owner_display_name => random_v4uuid,
      owner_email => random_v4uuid,
      );
    GrokLOC::App::Admin::Org::Events::Create->new(%args)->build->validate
  },
  ) or note($EVAL_ERROR);

done_testing;
