# vim: ts=2 sw=2 syn=perl :
package main;
use v5.38;
use Crypt::Misc qw( random_v4uuid );
use English qw(-no_match_vars);
use Test2::V0 qw( done_testing is note ok );
use Test2::Tools::Ref qw( ref_ok );
use Test2::Tools::Exception qw( lives );
use strictures 2;
use GrokLOC::App::JWT qw(
  decode_token
  encode_token
  encode_token_request
  token_from_header_val
  token_to_header_val
  verify_token_request
  );

# ABSTRACT: JWT testing

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

my $id         = random_v4uuid;
my $key        = random_v4uuid;
my $api_secret = random_v4uuid;

my $encoded_request;

ok(
  lives {
    $encoded_request = encode_token_request($id, $api_secret);
  },
  ) or note($EVAL_ERROR);

is(1, verify_token_request($encoded_request, $id, $api_secret));

my $jwt;

ok(
  lives {
    $jwt = encode_token($id, $key);
  },
  ) or note($EVAL_ERROR);

my $decoded;

ok(
  lives {
    $decoded = decode_token($jwt, $key)
  },
  ) or note($EVAL_ERROR);

ref_ok($decoded, 'HASH');

is($jwt, token_from_header_val(token_to_header_val($jwt)));

done_testing;
