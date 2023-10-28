package main;
use v5.38;
use Crypt::Misc qw( random_v4uuid );
use English qw(-no_match_vars);
use Test2::V0 qw( done_testing is isnt note ok );
use Test2::Tools::Exception qw( lives );
use strictures 2;
use GrokLOC qw(
  $ENV_UNIT
  $RESPONSE_OK
  $ROLE_TEST
  $STATUS_ACTIVE
  $STATUS_INACTIVE
  );
use GrokLOC::App::Admin::Org::Controller ();
use GrokLOC::App::Admin::Org::Events::Create ();
use GrokLOC::App::Admin::Org::Events::Read ();
use GrokLOC::App::Admin::Org::Events::UpdateOwner ();
use GrokLOC::App::Admin::Org::Events::UpdateStatus ();
use GrokLOC::App::Admin::User ();
use GrokLOC::App::State::Init qw( state_from_env );
use GrokLOC::Crypt qw( rand_argon2_password );

# ABSTRACT: org controller tests

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

# constructor tests

my $st;
my $controller;

ok(
  lives {
    $st = state_from_env($ENV_UNIT);
    $controller = GrokLOC::App::Admin::Org::Controller->new(st => $st)->build()->validate();
  },
  ) or note($EVAL_ERROR);

# create tests

my $o;

ok(
  lives {
    my $event = GrokLOC::App::Admin::Org::Events::Create->new(
      name => random_v4uuid,
      owner_display_name => random_v4uuid,
      owner_email => random_v4uuid,
      owner_password => rand_argon2_password,
      role => $ROLE_TEST,
      );
    $o = $controller->create($event);
  },
  ) or note($EVAL_ERROR);

my $o_read;

ok(
  lives {
    my $event = GrokLOC::App::Admin::Org::Events::Read->new(id => $o->id);
    $o_read = $controller->read($event);
  },
  ) or note($EVAL_ERROR);

is($o, $o_read);

# update owner tests

# need a new user in org that can be made the new owner

my $u_owner;

ok(
  lives {
    $u_owner = GrokLOC::App::Admin::User->create(
      $st->master,
      $st->version_key,
      display_name => random_v4uuid,
      email => random_v4uuid,
      org => $o->id,
      password => rand_argon2_password,
      status => $STATUS_ACTIVE,
      );
  },
  ) or note($EVAL_ERROR);

isnt($u_owner, undef);

my $update_resp;

ok(
  lives {
    my $event = GrokLOC::App::Admin::Org::Events::UpdateOwner->new(id => $o->id, owner => $u_owner->id);
    $update_resp = $controller->update_owner($event);
  },
  ) or note($EVAL_ERROR);

is($update_resp, $RESPONSE_OK);

ok(
  lives {
    my $event = GrokLOC::App::Admin::Org::Events::Read->new(id => $o->id);
    $o_read = $controller->read($event);
  },
  ) or note($EVAL_ERROR);

is($o_read->owner, $u_owner->id);

# update status tests

ok(
  lives {
    my $event = GrokLOC::App::Admin::Org::Events::UpdateStatus->new(id => $o->id, status => $STATUS_INACTIVE);
    $update_resp = $controller->update_status($event);
  },
  ) or note($EVAL_ERROR);

is($update_resp, $RESPONSE_OK);

ok(
  lives {
    my $event = GrokLOC::App::Admin::Org::Events::Read->new(id => $o->id);
    $o_read = $controller->read($event);
  },
  ) or note($EVAL_ERROR);

is($o_read->status, $STATUS_INACTIVE);

done_testing;
