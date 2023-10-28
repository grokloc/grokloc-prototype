package main;
use v5.38;
use Crypt::Misc qw( random_v4uuid );
use English qw(-no_match_vars);
use Test::Mojo;
use Test2::V0 qw( bail_out done_testing is like lives note ok );
use GrokLOC ();
use GrokLOC::App::Client ();
use GrokLOC::App::Admin::User ();
use GrokLOC::App::State::Global qw( $ST );
use GrokLOC::Crypt qw( rand_argon2_password );

# ABSTRACT: test /ok

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

my $t = Test::Mojo->new('App');

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
my $create_org_result;
my $org_name = random_v4uuid;
my $password = rand_argon2_password;

ok(
  lives {
    my %args = (
      name               => $org_name,
      owner_display_name => random_v4uuid,
      owner_email        => random_v4uuid,
      owner_password     => $password,
      );
    $create_org_result = $client->org_create(%args);
  },
  'org create',
  ) or note($EVAL_ERROR);

is($create_org_result->code, 201, 'org create');

like($create_org_result->headers->location,
  qr/\/\S+\/\S+\/\S+\/\S+/x, 'location path');

my $org_id;
if ($create_org_result->headers->location =~ /\/\S+\/\S+\/\S+\/(\S+)/x) {
  $org_id = $1;
}
else {
  bail_out 'cannot extract id from ' . $create_org_result->headers->location;
}

# try creating a duplicate to test conflict detection
my $create_org_duplicate_result;

ok(
  lives {
    my %args = (
      name => $org_name,
      owner_display_name => random_v4uuid,
      owner_email => random_v4uuid,
      owner_password => $password,
      );
    $create_org_duplicate_result = $client->org_create(%args);
  },
  'org create',
  ) or note($EVAL_ERROR);

is($create_org_duplicate_result->code, 409, 'org create duplicate');

# use the low-level api to read the user who is the owner of the
# org just created...this user is not root and will not be able to create orgs
my $nonroot_user;

ok(
  lives {
    $nonroot_user = GrokLOC::App::Admin::User->read( $ST->master, $ST->version_key,
      $create_org_result->json->{owner} );
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
my $fail_create_org_result;

ok(
  lives {
    my %args = (
      name => random_v4uuid,
      owner_display_name => random_v4uuid,
      owner_email => random_v4uuid,
      owner_password => $password,
      );
    $fail_create_org_result = $nonroot_client->org_create(%args);
  },
  'org create',
  ) or note($EVAL_ERROR);

# fails
is($fail_create_org_result->code, 403, 'fail org create');

# the root client will also fail to create an org if there is missing info
ok(
  lives {
    my %args = (    # missing 'name'
      owner_display_name => random_v4uuid,
      owner_email => random_v4uuid,
      owner_password => $password,
      );
    $fail_create_org_result = $client->org_create(%args);
  },
  'org create',
  ) or note($EVAL_ERROR);

# fails
is($fail_create_org_result->code, 400, 'fail org create');

done_testing;
