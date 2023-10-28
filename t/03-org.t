package main;
use v5.38;
use Crypt::Misc qw( random_v4uuid );
use English qw(-no_match_vars);
use Test2::V0 qw( done_testing is isnt note ok );
use Test2::Tools::Exception qw( dies lives );
use strictures 2;
use GrokLOC qw(
  $ENV_UNIT
  $RESPONSE_CONFLICT
  $RESPONSE_NO_ROWS
  $RESPONSE_OK
  $ROLE_TEST
  $STATUS_ACTIVE
  $STATUS_UNCONFIRMED
  );
use GrokLOC::App::Admin::Org ();
use GrokLOC::App::Admin::User ();
use GrokLOC::App::State::Init qw( state_from_env );
use GrokLOC::Crypt qw( rand_argon2_password );

# ABSTRACT: org tests

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

# constructor tests

# ok, minimal args

my $o;

ok(
  lives {
    $o = GrokLOC::App::Admin::Org->new(
      name => random_v4uuid,
      owner => random_v4uuid,
      )->build->validate;
  },
  ) or note($EVAL_ERROR);

# empty name
ok(
  dies {
    GrokLOC::App::Admin::Org->new(
      name => q{},
      owner => random_v4uuid,
      )->build->validate;
  },
  ) or note($EVAL_ERROR);

# empty owner
ok(
  dies {
    GrokLOC::App::Admin::Org->new(
      name => random_v4uuid,
      owner => q{},
      )->build->validate;
  },
  ) or note($EVAL_ERROR);

# insert tests

my $st;

ok(
  lives {
    $st = state_from_env($ENV_UNIT);
  },
  ) or note($EVAL_ERROR);

my $key_version = $st->version_key->current;
my $key = $st->version_key->keymap->{$st->version_key->current};

my $resp;

ok(
  lives {
    $resp = $o->insert($st->master);
  },
  ) or note($EVAL_ERROR);

is($resp, $RESPONSE_OK);

ok(
  lives {
    $resp = $o->insert($st->master);
  },
  ) or note($EVAL_ERROR);

is($resp, $RESPONSE_CONFLICT);

# read tests

my $o_read;

ok(
  lives {
    $o_read = GrokLOC::App::Admin::Org->read($st->master, $o->id);
  },
  ) or note($EVAL_ERROR);

is($o_read->id, $o->id);
is($o_read->name, $o->name);
is($o_read->owner, $o->owner);
isnt($o_read->ctime, $o->ctime);
isnt($o_read->mtime, $o->mtime);
is($o_read->role, $o->role);
is($o_read->schema_version, $o->schema_version);
isnt($o_read->signature, $o->signature); # new signature on insert
is($o_read->status, $o->status);

# read miss
ok(
  lives {
    $o_read = GrokLOC::App::Admin::Org->read($st->master, random_v4uuid);
  },
  ) or note($EVAL_ERROR);

is($o_read, undef);

# create tests

my $o_create;

ok(
  lives {
    $o_create = GrokLOC::App::Admin::Org->create(
      $st->master,
      $st->version_key,
      name => random_v4uuid,
      owner_display_name => random_v4uuid,
      owner_email => random_v4uuid,
      owner_password => rand_argon2_password,
      role => $ROLE_TEST,
      );
  },
  ) or note($EVAL_ERROR);

isnt($o_create, undef);
is($o_create->role, $ROLE_TEST);
is($o_create->status, $STATUS_ACTIVE);

my $owner;

ok(
  lives {
    $owner = GrokLOC::App::Admin::User->read($st->master, $st->version_key, $o_create->owner);
  },
  ) or note($EVAL_ERROR);

isnt($owner, undef);
is($owner->role, $ROLE_TEST);
is($owner->status, $STATUS_ACTIVE);

# update_owner tests

# create new user to be owner
my $u_new_owner;

ok(
  lives {
    $u_new_owner = GrokLOC::App::Admin::User->create(
      $st->master,
      $st->version_key,
      display_name => random_v4uuid,
      email => random_v4uuid,
      org => $o_create->id,
      password => rand_argon2_password,
      );
  },
  ) or note($EVAL_ERROR);

# owner needs to be STATUS_ACTIVE to be new owner...
is($u_new_owner->status, $STATUS_UNCONFIRMED);

ok(
  lives {
    $resp = $o_create->update_owner(
      $st->master,
      $u_new_owner->id,
      );
  },
  ) or note($EVAL_ERROR);

is($resp, $RESPONSE_NO_ROWS);

# change to active
ok(
  lives {
    $u_new_owner->update_status(
      $st->master,
      $st->version_key,
      $STATUS_ACTIVE,
      );
  },
  ) or note($EVAL_ERROR);

# now should work
ok(
  lives {
    $resp = $o_create->update_owner(
      $st->master,
      $u_new_owner->id,
      );
  },
  ) or note($EVAL_ERROR);

is($resp, $RESPONSE_OK);
is($o_create->owner, $u_new_owner->id);

# update_status tests

ok(
  lives {
    $resp = $o_create->update_status(
      $st->master,
      $STATUS_UNCONFIRMED,
      );
  },
  ) or note($EVAL_ERROR);

is($resp, $RESPONSE_OK);
is($o_create->status, $STATUS_UNCONFIRMED);

done_testing;
