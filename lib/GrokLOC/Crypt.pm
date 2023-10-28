package GrokLOC::Crypt;
use v5.38;
use strictures 2;
use Carp qw( croak );
use Crypt::Argon2 qw( argon2id_pass argon2id_verify );
use Crypt::Digest::SHA256 qw( sha256_b64 );
use Crypt::Misc qw( random_v4uuid );
use Crypt::Mode::CBC ();
use Crypt::Random qw( makerandom );
use Readonly ();

# ABSTRACT: Crypt methods.

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

use base qw(Exporter);

Readonly::Scalar our $AES_IV_LEN => 16;
Readonly::Scalar our $AES_KEY_LEN => 32;
Readonly::Scalar our $ARGON2_SALT_LEN => 16;
Readonly::Scalar our $RAND_SIZE => 200;
Readonly::Scalar our $RAND_STRENGTH => 1;

sub rand_aes_iv {
  my $r = makerandom(Size => $RAND_SIZE, Strength => $RAND_STRENGTH);
  return substr unpack('H*', sha256_b64($r)), 0, $AES_IV_LEN;
}

sub rand_aes_key {
  my $r = makerandom(Size => $RAND_SIZE, Strength => $RAND_STRENGTH);
  return substr unpack('H*', sha256_b64($r)), 0, $AES_KEY_LEN;
}

sub is_aes_key ($key) {
  return undef unless (defined $key);
  return undef unless (length $key == $AES_KEY_LEN);
  return 1;
}

sub rand_argon2_salt {
  my $r = makerandom(Size => $RAND_SIZE, Strength => $RAND_STRENGTH);
  return substr sha256_b64($r), 0, $ARGON2_SALT_LEN;
}

sub is_argon2_salt ($salt) {
  return undef unless (defined $salt);
  return undef unless (length $salt == $ARGON2_SALT_LEN);
  return 1;
}

sub is_argon2_password ($password) {
  return undef unless (defined $password);
  return ($password =~ /^\$argon2/x);
}

sub rand_argon2_password () {
  return argon2id_pass(random_v4uuid, rand_argon2_salt, 1, '32M', 1, 16);
}

sub is_kdf_iterations ($i) {
  return undef unless (defined $i);
  return undef if ($i !~ /^\d+$/x);
  return (0 < $i < 232);
}

sub encrypt_hex ($source, $key) {
  croak 'source is empty' if length $source == 0;
  my $cbc = Crypt::Mode::CBC->new('AES');
  my $iv = rand_aes_iv;
  return $iv . unpack('H*', $cbc->encrypt($source, $key, $iv));
}

sub decrypt_hex ($crypted, $key) {
  croak 'crypted is empty' if length $crypted == 0;
  my $cbc = Crypt::Mode::CBC->new('AES');

  # iv is prepended as the first AES_IV_LEN bytes
  # value can be taken as-is; was already hex-encoded
  my $iv = substr($crypted, 0, $AES_IV_LEN);
  return $cbc->decrypt(pack('H*', substr($crypted, $AES_IV_LEN)), $key, $iv);
}

sub kdf ($pw, $salt, $t_cost) {
  croak 'pw zero len' if (!defined($pw) || length $pw == 0);
  croak 'salt fails is_argon2_salt' unless is_argon2_salt($salt);
  croak 't_cost fails is_kdf_iterations' unless is_kdf_iterations($t_cost);
  return argon2id_pass($pw, $salt, $t_cost, '32M', 1, 16);
}

# kdf_verify determines if "guess" $pw is a match for previously $encoded pw
sub kdf_verify ($encoded, $pw) {
  return argon2id_verify($encoded, $pw);
}

our @EXPORT_OK = qw(
  $AES_KEY_LEN
  $AES_IV_LEN
  $ARGON2_SALT_LEN
  decrypt_hex
  encrypt_hex
  kdf
  kdf_verify
  is_aes_key
  is_argon2_password
  is_argon2_salt
  is_kdf_iterations
  rand_aes_iv
  rand_aes_key
  rand_argon2_password
  rand_argon2_salt
  );

our %EXPORT_TAGS = (all => \@EXPORT_OK);

__END__
