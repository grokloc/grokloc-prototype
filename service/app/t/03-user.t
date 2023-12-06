package main;
use v5.38;
use Crypt::Misc qw( random_v4uuid );
use English qw(-no_match_vars);
use Test::Mojo;
use Test2::V0 qw( bail_out done_testing is like lives note ok );
use GrokLOC qw( $ROLE_TEST $STATUS_ACTIVE $STATUS_INACTIVE );
use GrokLOC::App::Client ();
use GrokLOC::App::Admin::Org ();
use GrokLOC::App::Admin::User ();
use GrokLOC::App::State::Global qw( $ST );
use GrokLOC::Crypt qw( rand_argon2_password );

# ABSTRACT: test user handlers

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

my $t = Test::Mojo->new('App');

# post tests

# read root user object from root user id to get to other fields
my $ru;

ok(
  lives {
    $ru = GrokLOC::App::Admin::User->read($ST->master, $ST->version_key, $ST->root_user);
  },
  'root user',
  ) or note($EVAL_ERROR);

my $client;

ok(
  lives {
    $client = GrokLOC::App::Client->new(
      id         => $ST->root_user,
      api_secret => $ru->api_secret,
      url        => $t->ua->server->url->to_string,
      ua         => $t->ua,
      )->build->validate;
  },
  'root client',
  ) or note($EVAL_ERROR);

# make an org to create users in

my $org;

ok(
  lives {
    $org = GrokLOC::App::Admin::Org->create(
      $ST->master,
      $ST->version_key,
      name => random_v4uuid,
      owner_display_name => random_v4uuid,
      owner_email => random_v4uuid,
      owner_password => rand_argon2_password,
      role => $ROLE_TEST,
      );
  },
  ) or note($EVAL_ERROR);

my $create_user_response;

# root can create a user in any org
ok(
  lives {
    my %args = (
      display_name => random_v4uuid,
      email => random_v4uuid,
      org => $org->id,
      password => rand_argon2_password,
      );
    $create_user_response = $client->user_create(%args);
  },
  'user create',
  ) or note($EVAL_ERROR);

is($create_user_response->code, 201, 'user create');

like($create_user_response->headers->location,
  qr/\/\S+\/\S+\/\S+\/\S+/x, 'location path');

my $user_id;
if ($create_user_response->headers->location =~ /\/\S+\/\S+\/\S+\/(\S+)/x) {
  $user_id = $1;
}
else {
  bail_out 'cannot extract id from ' . $create_user_response->headers->location;
}

# make a client for the org owner
my $owner;

ok(
  lives {
    $owner = GrokLOC::App::Admin::User->read($ST->master, $ST->version_key, $org->owner);
  },
  'org owner',
  ) or note($EVAL_ERROR);

my $owner_client;

ok(
  lives {
    $owner_client = GrokLOC::App::Client->new(
      id         => $owner->id,
      api_secret => $owner->api_secret,
      url        => $t->ua->server->url->to_string,
      ua         => $t->ua,
      )->build->validate;
  },
  'org owner client',
  ) or note($EVAL_ERROR);

# owner can create users in their own org
ok(
  lives {
    my %args = (
      display_name => random_v4uuid,
      email => random_v4uuid,
      org => $org->id,
      password => rand_argon2_password,
      );
    $create_user_response = $owner_client->user_create(%args);
  },
  'user create by owner',
  ) or note($EVAL_ERROR);

is($create_user_response->code, 201, 'user create by owner');

# owner cannot create users in any other org
ok(
  lives {
    my %args = (
      display_name => random_v4uuid,
      email => random_v4uuid,
      org => $ST->root_org,
      password => rand_argon2_password,
      );
    $create_user_response = $owner_client->user_create(%args);
  },
  'user create by owner',
  ) or note($EVAL_ERROR);

is($create_user_response->code, 403, 'user create by owner');

# create client for user created earlier identified by $user_id

my $user;

ok(
  lives {
    $user = GrokLOC::App::Admin::User->read($ST->master, $ST->version_key, $user_id);
    $user->update_status($ST->master, $ST->version_key, $STATUS_ACTIVE);
  },
  'user',
  ) or note($EVAL_ERROR);

my $user_client;

ok(
  lives {
    $user_client = GrokLOC::App::Client->new(
      id         => $user->id,
      api_secret => $user->api_secret,
      url        => $t->ua->server->url->to_string,
      ua         => $t->ua,
      )->build->validate;
  },
  'user client',
  ) or note($EVAL_ERROR);

ok(
  lives {
    my %args = (
      display_name => random_v4uuid,
      email => random_v4uuid,
      org => $org->id,
      password => rand_argon2_password,
      );
    $create_user_response = $user_client->user_create(%args);
  },
  'user create by owner',
  ) or note($EVAL_ERROR);

is($create_user_response->code, 403, 'user create by user');

# get tests

my $user_read_response;

# root can read any user
ok(
  lives {
    $user_read_response = $client->user_read($user_id);
  },
  'user read by root',
  ) or note($EVAL_ERROR);

is($user_read_response->code, 200);
is($user_read_response->json->{id}, $user_id);

# an org owner can read a user in their org
ok(
  lives {
    $user_read_response = $owner_client->user_read($user_id);
  },
  'user read by org owner',
  ) or note($EVAL_ERROR);

is($user_read_response->code, 200);
is($user_read_response->json->{id}, $user_id);

# a user can read their own record
ok(
  lives {
    $user_read_response = $user_client->user_read($user_id);
  },
  'user read by user',
  ) or note($EVAL_ERROR);

is($user_read_response->code, 200);
is($user_read_response->json->{id}, $user_id);

# user not found
ok(
  lives {
    $user_read_response = $client->user_read(random_v4uuid);
  },
  'user read by root',
  ) or note($EVAL_ERROR);

is($user_read_response->code, 404);

# org owner cannot read users in another org
ok(
  lives {
    $user_read_response = $owner_client->user_read($ST->root_user);
  },
  'user read by org owner',
  ) or note($EVAL_ERROR);

is($user_read_response->code, 403);

# regular user cannot even read other users in their org
ok(
  lives {
    $user_read_response = $user_client->user_read($owner->id);
  },
  'user read by user',
  ) or note($EVAL_ERROR);

is($user_read_response->code, 403);

# put tests

my $user_update_response;

# root change a user's display name
my $display_name = random_v4uuid;

ok(
  lives {
    $user_update_response = $client->user_update($user_id, display_name => $display_name);
  },
  'user update display name by root',
  ) or note($EVAL_ERROR);

is($user_update_response->code, 204);

my $read_user;

ok(
  lives {
    $read_user = GrokLOC::App::Admin::User->read($ST->master, $ST->version_key, $user_id);
  },
  'read user',
  ) or note($EVAL_ERROR);

is($read_user->display_name, $display_name);

# org owner can change a user's display name
$display_name = random_v4uuid;

ok(
  lives {
    $user_update_response = $owner_client->user_update($user_id, display_name => $display_name);
  },
  'user update display name by org owner',
  ) or note($EVAL_ERROR);

is($user_update_response->code, 204);

ok(
  lives {
    $read_user = GrokLOC::App::Admin::User->read($ST->master, $ST->version_key, $user_id);
  },
  'read user',
  ) or note($EVAL_ERROR);

is($read_user->display_name, $display_name);

# org owner cannot change display name of user in different org
ok(
  lives {
    $user_update_response = $owner_client->user_update($ST->root_user, display_name => $display_name);
  },
  'user update display_name by org owner',
  ) or note($EVAL_ERROR);

is($user_update_response->code, 403);

# user can change their own display name
$display_name = random_v4uuid;

ok(
  lives {
    $user_update_response = $user_client->user_update($user_id, display_name => $display_name);
  },
  'user update display name by user',
  ) or note($EVAL_ERROR);

is($user_update_response->code, 204);

ok(
  lives {
    $read_user = GrokLOC::App::Admin::User->read($ST->master, $ST->version_key, $user_id);
  },
  'read user',
  ) or note($EVAL_ERROR);

is($read_user->display_name, $display_name);

# root change a user's password
my $password = rand_argon2_password;

ok(
  lives {
    $user_update_response = $client->user_update($user_id, password => $password);
  },
  'user update password by root',
  ) or note($EVAL_ERROR);

is($user_update_response->code, 204);

ok(
  lives {
    $read_user = GrokLOC::App::Admin::User->read($ST->master, $ST->version_key, $user_id);
  },
  'read user',
  ) or note($EVAL_ERROR);

is($read_user->password, $password);

# org owner can change a user's password
$password = rand_argon2_password;

ok(
  lives {
    $user_update_response = $owner_client->user_update($user_id, password => $password);
  },
  'user update password by org owner',
  ) or note($EVAL_ERROR);

is($user_update_response->code, 204);

ok(
  lives {
    $read_user = GrokLOC::App::Admin::User->read($ST->master, $ST->version_key, $user_id);
  },
  'read user',
  ) or note($EVAL_ERROR);

is($read_user->password, $password);

# org owner cannot change password of user in different org
ok(
  lives {
    $user_update_response = $owner_client->user_update($ST->root_user, password => $password);
  },
  'user update password by org owner',
  ) or note($EVAL_ERROR);

is($user_update_response->code, 403);

# user can change their own password
$password = rand_argon2_password;

ok(
  lives {
    $user_update_response = $user_client->user_update($user_id, password => $password);
  },
  'user update password by user',
  ) or note($EVAL_ERROR);

is($user_update_response->code, 204);

ok(
  lives {
    $read_user = GrokLOC::App::Admin::User->read($ST->master, $ST->version_key, $user_id);
  },
  'read user',
  ) or note($EVAL_ERROR);

is($read_user->password, $password);

# root change a user's status
my $status = $STATUS_INACTIVE;

ok(
  lives {
    $user_update_response = $client->user_update($user_id, status => $status);
  },
  'user update status by root',
  ) or note($EVAL_ERROR);

is($user_update_response->code, 204);

ok(
  lives {
    $read_user = GrokLOC::App::Admin::User->read($ST->master, $ST->version_key, $user_id);
  },
  'read user',
  ) or note($EVAL_ERROR);

is($read_user->status, $status);

# org owner can change a user's status
$status = $STATUS_ACTIVE;

ok(
  lives {
    $user_update_response = $owner_client->user_update($user_id, status => $status);
  },
  'user update status by org owner',
  ) or note($EVAL_ERROR);

is($user_update_response->code, 204);

ok(
  lives {
    $read_user = GrokLOC::App::Admin::User->read($ST->master, $ST->version_key, $user_id);
  },
  'read user',
  ) or note($EVAL_ERROR);

is($read_user->status, $status);

# org owner cannot change status of user in different org
ok(
  lives {
    $user_update_response = $owner_client->user_update($ST->root_user, status => $status);
  },
  'user update status by org owner',
  ) or note($EVAL_ERROR);

is($user_update_response->code, 403);

# a user cannot change their own status
ok(
  lives {
    $user_update_response = $user_client->user_update($user_id, status => $status);
  },
  'user update status by user',
  ) or note($EVAL_ERROR);

is($user_update_response->code, 403);

# root delete a user
# (deleting a user means setting status to inactive)

# first set user to active

ok(
  lives {
    $user_update_response = $client->user_update($user_id, status => $STATUS_ACTIVE);
  },
  'user update status by root',
  ) or note($EVAL_ERROR);

is($user_update_response->code, 204);

# now delete
ok(
  lives {
    $user_update_response = $client->user_delete($user_id);
  },
  'user deleted by root',
  ) or note($EVAL_ERROR);

is($user_update_response->code, 204);

ok(
  lives {
    $read_user = GrokLOC::App::Admin::User->read($ST->master, $ST->version_key, $user_id);
  },
  'read user',
  ) or note($EVAL_ERROR);

is($read_user->status, $STATUS_INACTIVE);

# set back to active for next test
ok(
  lives {
    $user_update_response = $client->user_update($user_id, status => $STATUS_ACTIVE);
  },
  'user update status by root',
  ) or note($EVAL_ERROR);

is($user_update_response->code, 204);

# org owner can delete a user
ok(
  lives {
    $user_update_response = $owner_client->user_delete($user_id);
  },
  'user update status by org owner',
  ) or note($EVAL_ERROR);

is($user_update_response->code, 204);

ok(
  lives {
    $read_user = GrokLOC::App::Admin::User->read($ST->master, $ST->version_key, $user_id);
  },
  'read user',
  ) or note($EVAL_ERROR);

is($read_user->status, $STATUS_INACTIVE);

# org owner cannot delete user in different org
ok(
  lives {
    $user_update_response = $owner_client->user_delete($ST->root_user);
  },
  'user delete by org owner',
  ) or note($EVAL_ERROR);

is($user_update_response->code, 403);

ok(
  lives {
    $user_update_response = $client->user_update($user_id, status => $STATUS_ACTIVE);
  },
  'user update status by root',
  ) or note($EVAL_ERROR);

is($user_update_response->code, 204);

# a user cannot change their own status
ok(
  lives {
    $user_update_response = $user_client->user_delete($user_id);
  },
  'user delete by user',
  ) or note($EVAL_ERROR);

is($user_update_response->code, 403);

done_testing;
