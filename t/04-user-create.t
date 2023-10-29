package main;
use v5.38;
use Crypt::Misc qw( random_v4uuid );
use English qw(-no_match_vars);
use Test2::V0 qw( done_testing note ok );
use Test2::Tools::Exception qw( dies lives );
use GrokLOC::App::Admin::User::Events::Create ();
use GrokLOC::Crypt qw( rand_argon2_password );

# ABSTRACT: user Create event tests

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

ok(
  lives {
    my %args = (
      display_name => random_v4uuid,
      email => random_v4uuid,
      org => random_v4uuid,
      password => rand_argon2_password,
      );
    GrokLOC::App::Admin::User::Events::Create->new(%args)->build->validate
  },
  ) or note($EVAL_ERROR);

ok(
  dies {
    my %args = (
      email => random_v4uuid,
      org => random_v4uuid,
      password => rand_argon2_password,
      );
    GrokLOC::App::Admin::User::Events::Create->new(%args)->build->validate
  },
  ) or note($EVAL_ERROR);

ok(
  dies {
    my %args = (
      display_name => random_v4uuid,
      org => random_v4uuid,
      password => rand_argon2_password,
      );
    GrokLOC::App::Admin::User::Events::Create->new(%args)->build->validate
  },
  ) or note($EVAL_ERROR);

ok(
  dies {
    my %args = (
      display_name => random_v4uuid,
      email => random_v4uuid,
      password => rand_argon2_password,
      );
    GrokLOC::App::Admin::User::Events::Create->new(%args)->build->validate
  },
  ) or note($EVAL_ERROR);

ok(
  dies {
    my %args = (
      display_name => random_v4uuid,
      email => random_v4uuid,
      org => random_v4uuid,
      );
    GrokLOC::App::Admin::User::Events::Create->new(%args)->build->validate
  },
  ) or note($EVAL_ERROR);

done_testing;
