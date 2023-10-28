package main;
use v5.38;
use English qw(-no_match_vars);
use Test::Mojo;
use Test2::V0 qw( done_testing is lives note ok );
use GrokLOC qw( $OK_ROUTE );
use GrokLOC::App::Client ();
use GrokLOC::App::Admin::User ();
use GrokLOC::App::State::Global qw( $ST );

# ABSTRACT: test /ok

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

my $t = Test::Mojo->new('App');

# GET /ok with mojo api

$t->get_ok($OK_ROUTE)->status_is(200)->content_like(qr/ok/i);

# GET /ok with Client instance

# read root user object from root user id to get to other fields
my $ru;

ok(
  lives {
    $ru = GrokLOC::App::Admin::User->read( $ST->master, $ST->version_key, $ST->root_user );
  },
  'root user',
  ) or note($EVAL_ERROR);

my $root_client;

ok(
  lives {
    $root_client = GrokLOC::App::Client->new(
      id         => $ST->root_user,
      api_secret => $ru->api_secret,
      url        => $t->ua->server->url->to_string,
      ua         => $t->ua,
      )->build->validate;
  },
  'root client',
  ) or note($EVAL_ERROR);

is( ref($root_client), 'GrokLOC::App::Client', 'client ref' );

ok(
  lives {
    $root_client->ok;
  },
  'client get /ok',
  ) or note($EVAL_ERROR);

done_testing;

1;
