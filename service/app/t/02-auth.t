package main;
use v5.38;
use Crypt::Misc qw( random_v4uuid );
use English qw(-no_match_vars);
use Test::Mojo;
use Test2::V0 qw( done_testing lives note ok );
use GrokLOC qw(
  $TOKEN_REQUEST_ROUTE
  $X_GROKLOC_ID_HEADER
  $X_GROKLOC_TOKEN_REQUEST_HEADER
  );
use GrokLOC::App::Client ();
use GrokLOC::App::JWT qw( encode_token_request );
use GrokLOC::App::Admin::User ();
use GrokLOC::App::State::Global qw( $ST );

# ABSTRACT: test status

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

my $t = Test::Mojo->new('App');

# token requests

# no headers
$t->post_ok($TOKEN_REQUEST_ROUTE)->status_is(400);

# missing ID
$t->post_ok(
  $TOKEN_REQUEST_ROUTE => {
    $X_GROKLOC_ID_HEADER => random_v4uuid,
    },
  )->status_is(404);

# bad token request
$t->post_ok(
  $TOKEN_REQUEST_ROUTE => {
    $X_GROKLOC_ID_HEADER            => $ST->root_user,
    $X_GROKLOC_TOKEN_REQUEST_HEADER => random_v4uuid,
    },
  )->status_is(401);

# read root user object from root user id to get to other fields
my $ru;

ok(
  lives {
    $ru = GrokLOC::App::Admin::User->read($ST->master, $ST->version_key, $ST->root_user);
  },
  'root user',
  ) or note($EVAL_ERROR);

# ok
my $token_request = encode_token_request($ST->root_user, $ru->api_secret);

$t->post_ok(
  $TOKEN_REQUEST_ROUTE => {
    $X_GROKLOC_ID_HEADER            => $ST->root_user,
    $X_GROKLOC_TOKEN_REQUEST_HEADER => $token_request,
    },
  )->status_is(200);

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

ok(
  lives {
    $client->ok;
  },
  'ok',
  ) or note($EVAL_ERROR);

ok(
  lives {
    $client->status;
  },
  'status',
  ) or note($EVAL_ERROR);

done_testing;

1;
