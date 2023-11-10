package main;
use v5.38;
use Crypt::Digest::SHA256 qw( sha256_hex );
use Crypt::Misc qw( is_v4uuid random_v4uuid );
use English qw(-no_match_vars);
use Test2::V0 qw( done_testing is isnt note ok );
use Test2::Tools::Exception qw( dies lives );
use strictures 2;
use GrokLOC qw(
  $ENV_UNIT
  $RESPONSE_CONFLICT
  $RESPONSE_OK
  $ROLE_TEST
  $STATUS_ACTIVE
  $STATUS_UNCONFIRMED
  );
use GrokLOC::App::Admin::Org ();
use GrokLOC::App::Admin::User ();
use GrokLOC::App::State::Init qw( state_from_env );
use GrokLOC::Crypt qw( decrypt_hex rand_aes_key rand_argon2_password );

# ABSTRACT: user tests

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

# constructor tests

# ok, minimal args
ok(
  lives {
    GrokLOC::App::Admin::User->new(
      display_name => random_v4uuid,
      email => random_v4uuid,
      org => random_v4uuid,
      password => rand_argon2_password,
      )->build->validate;
  },
  ) or note($EVAL_ERROR);

# api_secret_digest, but no api_secret
ok(
  dies {
    GrokLOC::App::Admin::User->new(
      api_secret_digest => random_v4uuid,
      display_name => random_v4uuid,
      email => random_v4uuid,
      org => random_v4uuid,
      password => rand_argon2_password,
      )->build->validate;
  },
  ) or note($EVAL_ERROR);

# api_secret, but no api_secret_digest (note: lives)
ok(
  lives {
    GrokLOC::App::Admin::User->new(
      api_secret => random_v4uuid,
      display_name => random_v4uuid,
      email => random_v4uuid,
      org => random_v4uuid,
      password => rand_argon2_password,
      )->build->validate;
  },
  ) or note($EVAL_ERROR);

# api_secret_digest != sha256_hex(api_secret)
ok(
  dies {
    GrokLOC::App::Admin::User->new(
      api_secret => random_v4uuid,
      api_secret_digest => random_v4uuid,
      display_name => random_v4uuid,
      email => random_v4uuid,
      org => random_v4uuid,
      password => rand_argon2_password,
      )->build->validate;
  },
  ) or note($EVAL_ERROR);

# ok, api_secret_digest == sha256_hex(api_secret)
ok(
  lives {
    my $api_secret = random_v4uuid;
    GrokLOC::App::Admin::User->new(
      api_secret => $api_secret,
      api_secret_digest => sha256_hex($api_secret),
      display_name => random_v4uuid,
      email => random_v4uuid,
      org => random_v4uuid,
      password => rand_argon2_password,
      )->build->validate;
  },
  ) or note($EVAL_ERROR);

# no display_name
ok(
  dies {
    GrokLOC::App::Admin::User->new(
      email => random_v4uuid,
      org => random_v4uuid,
      password => rand_argon2_password,
      )->build->validate;
  },
  ) or note($EVAL_ERROR);

# display_name_digest, but no display_name
ok(
  dies {
    GrokLOC::App::Admin::User->new(
      display_name_digest => random_v4uuid,
      email => random_v4uuid,
      org => random_v4uuid,
      password => rand_argon2_password,
      )->build->validate;
  },
  ) or note($EVAL_ERROR);

# display_name_digest != sha256_hex(display_name)
ok(
  dies {
    GrokLOC::App::Admin::User->new(
      display_name => random_v4uuid,
      display_name_digest => random_v4uuid,
      email => random_v4uuid,
      org => random_v4uuid,
      password => rand_argon2_password,
      )->build->validate;
  },
  ) or note($EVAL_ERROR);

# ok, display_name_digest == sha256_hex(display_name)
ok(
  lives {
    my $display_name = random_v4uuid;
    GrokLOC::App::Admin::User->new(
      display_name => $display_name,
      display_name_digest => sha256_hex($display_name),
      email => random_v4uuid,
      org => random_v4uuid,
      password => rand_argon2_password,
      )->build->validate;
  },
  ) or note($EVAL_ERROR);

# missing email
ok(
  dies {
    GrokLOC::App::Admin::User->new(
      display_name => random_v4uuid,
      org => random_v4uuid,
      password => rand_argon2_password,
      )->build->validate;
  },
  ) or note($EVAL_ERROR);

# email_digest != sha256_hex(email)
ok(
  dies {
    GrokLOC::App::Admin::User->new(
      display_name => random_v4uuid,
      email => random_v4uuid,
      email_digest => random_v4uuid,
      org => random_v4uuid,
      password => rand_argon2_password,
      )->build->validate;
  },
  ) or note($EVAL_ERROR);

# ok, email_digest == sha256_hex(email)
ok(
  lives {
    my $email = random_v4uuid;
    GrokLOC::App::Admin::User->new(
      display_name => random_v4uuid,
      email => $email,
      email_digest => sha256_hex($email),
      org => random_v4uuid,
      password => rand_argon2_password,
      )->build->validate;
  },
  ) or note($EVAL_ERROR);

# missing org
ok(
  dies {
    GrokLOC::App::Admin::User->new(
      display_name => random_v4uuid,
      email => random_v4uuid,
      password => rand_argon2_password,
      )->build->validate;
  },
  ) or note($EVAL_ERROR);

# missing password
ok(
  dies {
    GrokLOC::App::Admin::User->new(
      display_name => random_v4uuid,
      email => random_v4uuid,
      org => random_v4uuid,
      )->build->validate;
  },
  ) or note($EVAL_ERROR);

my $u;

# ok, minimal args
ok(
  lives {
    $u = GrokLOC::App::Admin::User->new(
      display_name => random_v4uuid,
      email => random_v4uuid,
      org => random_v4uuid,
      password => rand_argon2_password,
      )->build->validate;
  },
  ) or note($EVAL_ERROR);

# make sure "auto" attributes are set
is(is_v4uuid $u->id, 1);
is(is_v4uuid $u->api_secret, 1);
is(sha256_hex($u->api_secret), $u->api_secret_digest);
is(sha256_hex($u->display_name), $u->display_name_digest);
is(sha256_hex($u->email), $u->email_digest);

# encrypt tests

my $st;

ok(
  lives {
    $st = state_from_env($ENV_UNIT);
  },
  ) or note($EVAL_ERROR);

my $key_version = $st->version_key->current;
my $key = $st->version_key->keymap->{$st->version_key->current};

isnt($u->key_version, $key_version);

ok(
  lives {
    $u->encrypt($key, $key_version);
  },
  ) or note($EVAL_ERROR);

is($u->key_version, $key_version);

ok(
  dies {
    $u->encrypt;
  },
  ) or note($EVAL_ERROR);

ok(
  dies {
    $u->encrypt(q{}, q{});
  },
  ) or note($EVAL_ERROR);

# insert tests

my $resp;

ok(
  lives {
    $resp = $u->insert($st->master);
  },
  ) or note($EVAL_ERROR);

is($resp, $RESPONSE_OK);

ok(
  lives {
    $resp = $u->insert($st->master);
  },
  ) or note($EVAL_ERROR);

is($resp, $RESPONSE_CONFLICT);

# read tests

my $u_read;

ok(
  lives {
    $u_read = GrokLOC::App::Admin::User->read($st->master, $st->version_key, $u->id);
  },
  ) or note($EVAL_ERROR);

# u_read is decrypted
is($u_read->id, $u->id);
is($u_read->api_secret_digest, $u->api_secret_digest);
is($u_read->api_secret, decrypt_hex($u->api_secret, $key));
is($u_read->display_name_digest, $u->display_name_digest);
is($u_read->display_name, decrypt_hex($u->display_name, $key));
is($u_read->email_digest, $u->email_digest);
is($u_read->email, decrypt_hex($u->email, $key));
is($u_read->org, $u->org);
is($u_read->password, $u->password);
isnt($u_read->ctime, $u->ctime); # because we gave u a made-up ctime
isnt($u_read->mtime, $u->mtime); # because we gave u a made-up mtime
is($u_read->role, $u->role);
is($u_read->schema_version, $u->schema_version);
isnt($u_read->signature, $u->signature); # new signature on insert
is($u_read->status, $u->status);

# bad version_key
ok(
  dies {
    $u_read = GrokLOC::App::Admin::User->read($st->master, {}, $u->id);
  },
  ) or note($EVAL_ERROR);

# read miss
ok(
  lives {
    $u_read = GrokLOC::App::Admin::User->read($st->master, $st->version_key, random_v4uuid);
  },
  ) or note($EVAL_ERROR);

is($u_read, undef);

# create tests

# need an org for a new user to be in

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

my $u_create;

ok(
  lives {
    $u_create = GrokLOC::App::Admin::User->create(
      $st->master,
      $st->version_key,
      display_name => random_v4uuid,
      email => random_v4uuid,
      org => $o_create->id,
      password => rand_argon2_password,
      );
  },
  ) or note($EVAL_ERROR);

isnt($u_create, undef);
is($u_create->role, $ROLE_TEST);
is($u_create->status, $STATUS_UNCONFIRMED);

# org not found
ok(
  dies {
    $u_create = GrokLOC::App::Admin::User->create(
      $st->master,
      $st->version_key,
      display_name => random_v4uuid,
      email => random_v4uuid,
      org => random_v4uuid,
      password => rand_argon2_password,
      );
  },
  ) or note($EVAL_ERROR);

# update tests

ok(
  lives {
    $u_create->update_status($st->master, $st->version_key, $STATUS_ACTIVE);
  },
  ) or note($EVAL_ERROR);

is($u_create->status, $STATUS_ACTIVE);

my $new_display_name = random_v4uuid;

ok(
  lives {
    $u_create->update_display_name($st->master, $st->version_key, $new_display_name);
  },
  ) or note($EVAL_ERROR);

is($u_create->display_name, $new_display_name);

my $new_password = rand_argon2_password;

ok(
  lives {
    $u_create->update_password($st->master, $st->version_key, $new_password);
  },
  ) or note($EVAL_ERROR);

is($u_create->password, $new_password);

# reencrypt tests

my $new_key_version = random_v4uuid;
$st->version_key->keymap->{$new_key_version} = rand_aes_key;

ok(
  lives {
    $u_create->reencrypt($st->master, $st->version_key, $new_key_version);
  },
  ) or note($EVAL_ERROR);

is($u_create->key_version, $new_key_version);

# read makes sure the re-encrypted fields come out ok
ok(
  lives {
    $u_read = GrokLOC::App::Admin::User->read($st->master, $st->version_key, $u_create->id);
  },
  ) or note($EVAL_ERROR);

done_testing;
