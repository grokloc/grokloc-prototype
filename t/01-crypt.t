package main;
use v5.38;
use GrokLOC::Crypt qw(
  $AES_IV_LEN
  $AES_KEY_LEN
  $ARGON2_SALT_LEN
  decrypt_hex
  encrypt_hex
  is_aes_key
  is_argon2_password
  is_argon2_salt
  kdf
  kdf_verify
  rand_aes_iv
  rand_aes_key
  rand_argon2_password
  rand_argon2_salt
  );
use Crypt::Misc qw( random_v4uuid );
use Test2::V0 qw( done_testing is isnt );
use strictures 2;

# ABSTRACT: crypt tests

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

isnt(is_aes_key(q{}), 1);
isnt(is_argon2_salt(q{}), 1);

my $iv = rand_aes_iv;
my $key = rand_aes_key;

is(length $iv, $AES_IV_LEN);
is(length $key, $AES_KEY_LEN);

my $plain = random_v4uuid;
my $crypted = encrypt_hex($plain, $key);
my $decrypted = decrypt_hex($crypted, $key);
is($plain, $decrypted);

my $salt = rand_argon2_salt;
is(length $salt, $ARGON2_SALT_LEN);

my $derived = kdf($plain, $salt, 1);
is(kdf_verify($derived, $plain), 1);
isnt(kdf_verify($derived, random_v4uuid), 1);
is(is_argon2_password($derived), 1);
isnt(is_argon2_password(random_v4uuid), 1);

is(is_argon2_password(rand_argon2_password), 1);

done_testing;
