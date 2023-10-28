package main;
use v5.38;
use Crypt::Misc qw( random_v4uuid );
use English qw(-no_match_vars);
use Test2::V0 qw( done_testing is note ok );
use Test2::Tools::Exception qw( dies lives );
use strictures 2;
use GrokLOC::Crypt::VersionKey ();

# ABSTRACT: scalar and object safety tests

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

# keymap is not HASH
ok(
  dies {
    GrokLOC::Crypt::VersionKey->new->build->validate;
  },
  ) or note($EVAL_ERROR);

# current is not a key in keymap
ok(
  dies {
    my $current = random_v4uuid;
    GrokLOC::Crypt::VersionKey->new(keymap => { $current => random_v4uuid },
      current => random_v4uuid)->build->validate;
  },
  ) or note($EVAL_ERROR);

# ok
ok(
  lives {
    my $current = random_v4uuid;
    my $key = random_v4uuid;
    GrokLOC::Crypt::VersionKey->new(keymap => { $current => $key },
      current => $current)->build->validate;
  },
  ) or note($EVAL_ERROR);

my $current = random_v4uuid;
my $key = random_v4uuid;
my $vk = GrokLOC::Crypt::VersionKey->new(keymap => { $current => $key },
  current => $current)->build->validate;

is($vk->keymap->{random_v4uuid}, undef);
is($vk->keymap->{$current}, $key);

done_testing;
