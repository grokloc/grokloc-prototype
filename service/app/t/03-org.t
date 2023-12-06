package main;
use v5.38;
use Crypt::Misc qw( random_v4uuid );
use English qw(-no_match_vars);
use Test::Mojo;
use Test2::V0 qw( bail_out done_testing is isnt like lives note ok );
use GrokLOC qw( $STATUS_ACTIVE $STATUS_INACTIVE );
use GrokLOC::App::Client ();
use GrokLOC::App::Admin::Org ();
use GrokLOC::App::Admin::User ();
use GrokLOC::App::State::Global qw( $ST );
use GrokLOC::Crypt qw( rand_argon2_password );

# ABSTRACT: test org handlers

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

ok(
  lives {
    $client->token_request;
  },
  'token request',
  ) or note($EVAL_ERROR);

# only root can create a new org
my $create_org_response;
my $org_name = random_v4uuid;
my $password = rand_argon2_password;

ok(
  lives {
    my %args = (
      name => $org_name,
      owner_display_name => random_v4uuid,
      owner_email => random_v4uuid,
      owner_password => $password,
      );
    $create_org_response = $client->org_create(%args);
  },
  'org create',
  ) or note($EVAL_ERROR);

is($create_org_response->code, 201, 'org create');

like($create_org_response->headers->location,
  qr/\/\S+\/\S+\/\S+\/\S+/x, 'location path');

my $org_id;
if ($create_org_response->headers->location =~ /\/\S+\/\S+\/\S+\/(\S+)/x) {
  $org_id = $1;
}
else {
  bail_out 'cannot extract id from ' . $create_org_response->headers->location;
}

is($org_id, $create_org_response->json->{id});

# try creating a duplicate to test conflict detection
my $create_org_duplicate_response;

ok(
  lives {
    my %args = (
      name => $org_name,
      owner_display_name => random_v4uuid,
      owner_email => random_v4uuid,
      owner_password => $password,
      );
    $create_org_duplicate_response = $client->org_create(%args);
  },
  'org create',
  ) or note($EVAL_ERROR);

is($create_org_duplicate_response->code, 409, 'org create duplicate');

# use the low-level api to read the user who is the owner of the
# org just created...this user is not root and will not be able to create orgs
my $nonroot_user;

ok(
  lives {
    $nonroot_user = GrokLOC::App::Admin::User->read( $ST->master, $ST->version_key,
      $create_org_response->json->{owner} );
  },
  'user read',
  ) or note($EVAL_ERROR);

is(ref($nonroot_user), 'GrokLOC::App::Admin::User', 'user ref');

my $nonroot_client;

ok(
  lives {
    $nonroot_client = GrokLOC::App::Client->new(
      id => $nonroot_user->id,
      api_secret => $nonroot_user->api_secret,
      url => $t->ua->server->url->to_string,
      ua => $t->ua,
      )->build->validate;
  },
  'nonroot client',
  ) or note($EVAL_ERROR);

# non-root user can't create an org
my $fail_create_org_response;

ok(
  lives {
    my %args = (
      name => random_v4uuid,
      owner_display_name => random_v4uuid,
      owner_email => random_v4uuid,
      owner_password => $password,
      );
    $fail_create_org_response = $nonroot_client->org_create(%args);
  },
  'org create',
  ) or note($EVAL_ERROR);

# fails
is($fail_create_org_response->code, 403, 'fail org create');

# the root client will also fail to create an org if there is missing info
ok(
  lives {
    my %args = (    # missing 'name'
      owner_display_name => random_v4uuid,
      owner_email => random_v4uuid,
      owner_password => $password,
      );
    $fail_create_org_response = $client->org_create(%args);
  },
  'org create',
  ) or note($EVAL_ERROR);

# fails
is($fail_create_org_response->code, 400, 'fail org create');

# get tests

my $org_read_response;

# root can read any existing org
ok(
  lives {
    $org_read_response = $client->org_read($org_id);
  },
  'org read',
  ) or note($EVAL_ERROR);

is($org_read_response->code, 200);
is($org_read_response->json->{id}, $org_id);

# nonroot can also read their own org
ok(
  lives {
    $org_read_response = $nonroot_client->org_read($org_id);
  },
  'org read',
  ) or note($EVAL_ERROR);

is($org_read_response->code, 200);
is($org_read_response->json->{id}, $org_id);

# root gets a 404 on trying to read a missing org
ok(
  lives {
    $org_read_response = $client->org_read(random_v4uuid);
  },
  'org read',
  ) or note($EVAL_ERROR);

is($org_read_response->code, 404);

# nonroot cannot learn of a missing org, only a 403 auth fail
ok(
  lives {
    $org_read_response = $nonroot_client->org_read(random_v4uuid);
  },
  'org nonroot read',
  ) or note($EVAL_ERROR);

is($org_read_response->code, 403);

# put tests

my $org_update_response;

# update status

# bad value
ok(
  lives {
    $org_update_response = $client->org_update($org_id, status => 'bad value');
  },
  'org update',
  ) or note($EVAL_ERROR);

is($org_update_response->code, 400);

# works
ok(
  lives {
    $org_update_response = $client->org_update($org_id, status => $STATUS_INACTIVE);
  },
  'org update',
  ) or note($EVAL_ERROR);

is($org_update_response->code, 204);

# confirm
ok(
  lives {
    $org_read_response = $client->org_read($org_id);
  },
  'org read',
  ) or note($EVAL_ERROR);

is($org_read_response->json->{status}, $STATUS_INACTIVE);

# change it back
ok(
  lives {
    $org_update_response = $client->org_update($org_id, status => $STATUS_ACTIVE);
  },
  'org update',
  ) or note($EVAL_ERROR);

is($org_update_response->code, 204);

# confirm
ok(
  lives {
    $org_read_response = $client->org_read($org_id);
  },
  'org read',
  ) or note($EVAL_ERROR);

is($org_read_response->json->{status}, $STATUS_ACTIVE);

# nonroot (org owner) cannot update their own org, only root can
#
# only need to test this for one kind of update, they are all the same code path
ok(
  lives {
    $org_update_response = $nonroot_client->org_update($org_id, status => $STATUS_ACTIVE);
  },
  'org nonroot update',
  ) or note($EVAL_ERROR);

is($org_update_response->code, 403);

# update owner

# first, create a new active user in the org
my $new_owner;

ok(
  lives {
    $new_owner = GrokLOC::App::Admin::User->create(
      $ST->master,
      $ST->version_key,
      display_name => random_v4uuid,
      email => random_v4uuid,
      org => $org_id,
      password => rand_argon2_password,
      status => $STATUS_ACTIVE,
      );
  },
  ) or note($EVAL_ERROR);

isnt($new_owner, undef);
is($new_owner->status, $STATUS_ACTIVE);

# bad value
ok(
  lives {
    $org_update_response = $client->org_update($org_id, owner => 'bad value');
  },
  'org update',
  ) or note($EVAL_ERROR);

is($org_update_response->code, 400);

# works
ok(
  lives {
    $org_update_response = $client->org_update($org_id, owner => $new_owner->id);
  },
  'org update',
  ) or note($EVAL_ERROR);

is($org_update_response->code, 204);

# confirm
ok(
  lives {
    $org_read_response = $client->org_read($org_id);
  },
  'org read',
  ) or note($EVAL_ERROR);

is($org_read_response->json->{owner}, $new_owner->id);

# delete tests (set to inactive)

my $org_delete_response;

# nonroot cannot delete
ok(
  lives {
    $org_delete_response = $nonroot_client->org_delete($org_id);
  },
  'org nonroot delete',
  ) or note($EVAL_ERROR);

is($org_delete_response->code, 403);

# root can delete
ok(
  lives {
    $org_delete_response = $client->org_delete($org_id);
  },
  'org delete',
  ) or note($EVAL_ERROR);

is($org_delete_response->code, 204);

# confirm
ok(
  lives {
    $org_read_response = $client->org_read($org_id);
  },
  'org read',
  ) or note($EVAL_ERROR);

is($org_read_response->json->{status}, $STATUS_INACTIVE);

done_testing;
