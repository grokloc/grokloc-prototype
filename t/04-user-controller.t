package main;
use v5.38;
use Crypt::Misc qw( random_v4uuid );
use English qw(-no_match_vars);
use Test2::V0 qw( done_testing is isnt note ok );
use Test2::Tools::Exception qw( lives );
use strictures 2;
use GrokLOC qw( $ENV_UNIT $RESPONSE_OK $ROLE_TEST $STATUS_INACTIVE );
use GrokLOC::App::Admin::Org ();
use GrokLOC::App::Admin::User::Controller ();
use GrokLOC::App::Admin::User::Events::Create ();
use GrokLOC::App::Admin::User::Events::Read ();
use GrokLOC::App::Admin::User::Events::UpdateDisplayName ();
use GrokLOC::App::Admin::User::Events::UpdatePassword ();
use GrokLOC::App::Admin::User::Events::UpdateStatus ();
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
    $controller = GrokLOC::App::Admin::User::Controller->new(st => $st)->build()->validate();
  },
  ) or note($EVAL_ERROR);

# create tests

my $o;

ok(
  lives {
    $o = GrokLOC::App::Admin::Org->create(
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

isnt($o, undef);

my $u;

ok(
  lives {
    my $event = GrokLOC::App::Admin::User::Events::Create->new(
      display_name => random_v4uuid,
      email => random_v4uuid,
      org => $o->id,
      password => rand_argon2_password,
      );
    $u = $controller->create($event);
  },
  ) or note($EVAL_ERROR);

isnt($u, undef);

my $u_read;

ok(
  lives {
    my $event = GrokLOC::App::Admin::User::Events::Read->new(id => $u->id);
    $u_read = $controller->read($event);
  },
  ) or note($EVAL_ERROR);

is($u, $u_read);

# update display name tests

my $update_resp;
my $display_name = random_v4uuid;

ok(
  lives {
    my $event = GrokLOC::App::Admin::User::Events::UpdateDisplayName->new(
      id => $u->id,
      display_name => $display_name,
      );
    $update_resp = $controller->update_display_name($event);
  },
  ) or note($EVAL_ERROR);

is($update_resp, $RESPONSE_OK);

ok(
  lives {
    my $event = GrokLOC::App::Admin::User::Events::Read->new(id => $u->id);
    $u_read = $controller->read($event);
  },
  ) or note($EVAL_ERROR);

is($u_read->display_name, $display_name);

# update password tests

my $password = rand_argon2_password;

ok(
  lives {
    my $event = GrokLOC::App::Admin::User::Events::UpdatePassword->new(
      id => $u->id,
      password => $password,
      );
    $update_resp = $controller->update_password($event);
  },
  ) or note($EVAL_ERROR);

is($update_resp, $RESPONSE_OK);

ok(
  lives {
    my $event = GrokLOC::App::Admin::User::Events::Read->new(id => $u->id);
    $u_read = $controller->read($event);
  },
  ) or note($EVAL_ERROR);

is($u_read->password, $password);

# update status tests

ok(
  lives {
    my $event = GrokLOC::App::Admin::User::Events::UpdateStatus->new(
      id => $u->id,
      status => $STATUS_INACTIVE,
      );
    $update_resp = $controller->update_status($event);
  },
  ) or note($EVAL_ERROR);

is($update_resp, $RESPONSE_OK);

ok(
  lives {
    my $event = GrokLOC::App::Admin::User::Events::Read->new(id => $u->id);
    $u_read = $controller->read($event);
  },
  ) or note($EVAL_ERROR);

is($u_read->status, $STATUS_INACTIVE);

done_testing;
