package GrokLOC::App::Admin::User;
use v5.38;
use Mojo::Base 'GrokLOC::Models::Base';
use strictures 2;
use Carp qw( croak );
use Crypt::Digest::SHA256 qw( sha256_hex );
use Crypt::Misc qw( is_v4uuid random_v4uuid );
use GrokLOC qw( $RESPONSE_CONFLICT $RESPONSE_OK );
use GrokLOC::App::Audit qw(
  $AUDIT_STATUS
  $AUDIT_USER_DISPLAY_NAME
  $AUDIT_USER_INSERT
  $AUDIT_USER_PASSWORD
  create_audit
  );
use GrokLOC::Crypt qw(
  decrypt_hex
  encrypt_hex
  is_aes_key
  is_argon2_password
  );
use GrokLOC::Log qw( LOG_ERROR LOG_WARNING );
use GrokLOC::Safe::Scalar qw( varchar );
use feature 'try';
no warnings 'experimental::try';

# ABSTRACT: User model.

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

our $SCHEMA_VERSION = 0;

has api_secret => sub { random_v4uuid };
has ['api_secret_digest', 'display_name', 'display_name_digest',
  'email', 'email_digest', 'key_version', 'org', 'password'] => q{};

sub build ($self) {
  if (length $self->api_secret_digest == 0) {
    $self->api_secret_digest(sha256_hex($self->api_secret));
  }
  if (length $self->display_name_digest == 0) {
    $self->display_name_digest(sha256_hex($self->display_name));
  }
  if (length $self->email_digest == 0) {
    $self->email_digest(sha256_hex($self->email));
  }
  return $self;
}

sub validate ($self) {
  $self->SUPER::validate;
  unless (is_v4uuid $self->api_secret) {
    LOG_ERROR(api_secret => 'not is_v4uuid');
    croak 'api_secret fails';
  }
  unless (sha256_hex($self->api_secret) eq $self->api_secret_digest) {
    LOG_ERROR(api_secret_digest => $self->api_secret_digest);
    croak 'api_secret_digest fails';
  }
  unless (varchar $self->display_name) {
    LOG_ERROR(varchar => 'display_name');
    croak 'display_name fails';
  }
  unless (sha256_hex($self->display_name) eq $self->display_name_digest) {
    LOG_ERROR(display_name_digest => $self->display_name_digest);
    croak 'display_name_digest fails';
  }
  unless (varchar $self->email) {
    LOG_ERROR(varchar => 'email');
    croak 'email fails';
  }
  unless (sha256_hex($self->email) eq $self->email_digest) {
    LOG_ERROR(email_digest => $self->email_digest);
    croak 'email_digest fails';
  }
  if (length $self->key_version != 0 && (!is_v4uuid $self->key_version)) {
    LOG_ERROR(key_version => $self->key_version);
    croak 'key_version fails';
  }
  unless (is_v4uuid $self->org) {
    LOG_ERROR(org => $self->org);
    croak 'org fails';
  }
  unless (is_argon2_password $self->password) {
    LOG_ERROR(password => 'not argon2');
    croak 'password fails';
  }
  return $self;
}

sub encrypt ($self, $key, $key_version) {
  croak 'key fails' unless is_aes_key $key;
  croak 'key_version fails' unless is_v4uuid $key_version;
  $self->api_secret(encrypt_hex($self->api_secret, $key));
  $self->display_name(encrypt_hex($self->display_name, $key));
  $self->email(encrypt_hex($self->email, $key));
  $self->key_version($key_version);
  return $self;
}

sub insert ($self, $master) {
  try {
    $master->db->insert(
      'users',
      {
        id => $self->id,
        api_secret => $self->api_secret,
        api_secret_digest => $self->api_secret_digest,
        display_name => $self->display_name,
        display_name_digest => $self->display_name_digest,
        email => $self->email,
        email_digest => $self->email_digest,
        key_version => $self->key_version,
        org => $self->org,
        password => $self->password,
        role => $self->role,
        schema_version => $self->schema_version,
        status => $self->status,
      },
      );
  }
  catch ($e) {
    if ($e =~ /unique/imsx) {
      LOG_WARNING(conflict => $self->id);
      return $RESPONSE_CONFLICT;
    }
    LOG_ERROR(uncaught => $e);
    croak 'uncaught:' . $e;
  }
  return $RESPONSE_OK;
}

sub read ($class, $dbo, $version_key, $id) {
  my $v =
    $dbo->db->select('users', [qw{*}], { id => $id })->hash;
  return undef unless ( defined $v ); # not found == undef

  # for now, treat schema mismatches as fatal
  if ($v->{schema_version} != $SCHEMA_VERSION) {
    LOG_ERROR(id => $id, schema_version => $v->{schema_version});
    croak 'org schema version mismatch';
  }

  # version_key isa VersionKey
  my $key;
  if (defined $version_key->keymap->{$v->{key_version}}) {
    $key = $version_key->keymap->{$v->{key_version}};
  } else {
    LOG_ERROR(id => $id, missing => $v->{key_version});
    croak 'key not found in version_key';
  }

  my $api_secret = decrypt_hex($v->{api_secret}, $key);
  unless (sha256_hex($api_secret) eq $v->{api_secret_digest}) {
    LOG_ERROR(id => $id, decrypt => 'api_secret');
    croak 'decrypt api_secret';
  }
  my $display_name = decrypt_hex($v->{display_name}, $key);
  unless (sha256_hex($display_name) eq $v->{display_name_digest}) {
    LOG_ERROR(id => $id, decrypt => 'display_name');
    croak 'decrypt display_name';
  }
  my $email = decrypt_hex($v->{email}, $key);
  unless (sha256_hex($email) eq $v->{email_digest}) {
    LOG_ERROR(id => $id, decrypt => 'email');
    croak 'decrypt email';
  }

  # no need to validate - data was validated at time of original row creation
  return $class->new(
    id => $id,
    api_secret => $api_secret,
    api_secret_digest => $v->{api_secret_digest},
    display_name => $display_name,
    display_name_digest => $v->{display_name_digest},
    email => $email,
    email_digest => $v->{email_digest},
    key_version => $v->{key_version},
    org => $v->{org},
    password => $v->{password},
    ctime => $v->{ctime},
    mtime => $v->{mtime},
    role => $v->{role},
    schema_version => $v->{schema_version},
    signature => $v->{signature},
    status => $v->{status},
    );
}

sub create ($class, $master, $version_key, %args) {

  # version_key isa VersionKey
  my $key;
  if (defined $version_key->keymap->{$version_key->current}) {
    $key = $version_key->keymap->{$version_key->current};
  } else {
    LOG_ERROR(missing => 'version_key->current');
    croak 'current key not found in version_key';
  }

  # validate org before lookup
  if (!is_v4uuid $args{org}) {
    LOG_ERROR(missing => 'org');
    croak 'org fails';
  }

  my $txn = $master->db->begin;

  my $verify_org =
    $master->db->select('orgs',
    [qw{role status}],
    {id => $args{org}})->hash;

  unless (defined $verify_org) {
    LOG_WARNING('org not found' => $args{org});
    croak 'org not found';
  }

  # inherit org role
  $args{role} = $verify_org->{role};
  my $user = $class->new(%args)->build->validate->encrypt($key, $version_key->current);

  my $user_resp = $user->insert($master);
  if ($user_resp != $RESPONSE_OK) {
    LOG_ERROR(insert => 'user');
    say $user_resp;
  }

  my $audit_user_resp =
    create_audit($master, code => $AUDIT_USER_INSERT,
    source => 'users', source_id => $user->id);
  if ($audit_user_resp != $RESPONSE_OK) {
    LOG_WARNING(audit => 'user_insert');
  }

  $txn->commit;

  # populate meta
  return $class->read($master, $version_key, $user->id);
}

sub refresh ($self, $dbo, $version_key) {

  # version_key isa VersionKey
  my $key;
  if (defined $version_key->keymap->{$self->{key_version}}) {
    $key = $version_key->keymap->{$self->{key_version}};
  } else {
    LOG_ERROR(id => $self->id, missing => $self->{key_version});
    croak 'key not found in version_key';
  }

  my $v =
    $dbo->db->select('users',
    [qw{display_name display_name_digest
        password mtime signature status}],
    { id => $self->id })->hash;
  if (!defined $v) {

    # v undef means row not found which should not be possible
    # for an object previously instantiated
    LOG_ERROR(missing => $self->id);
    croak 'previously read users row now missing';
  }

  # only update columns that can possibly change
  my $display_name = decrypt_hex($v->{display_name}, $key);
  unless (sha256_hex($display_name) eq $v->{display_name_digest}) {
    LOG_ERROR(id => $self->id, decrypt => 'display_name');
    croak 'decrypt display_name';
  }

  $self->display_name($display_name);
  $self->display_name_digest($v->{display_name_digest});
  $self->mtime($v->{mtime});
  $self->password($v->{password});
  $self->signature($v->{signature});
  $self->status($v->{status});

  return $RESPONSE_OK;
}

sub update_display_name ($self, $master, $version_key, $display_name) {

  # version_key isa VersionKey
  my $key;
  if (defined $version_key->keymap->{$self->{key_version}}) {
    $key = $version_key->keymap->{$self->{key_version}};
  } else {
    LOG_ERROR(id => $self->id, missing => $self->{key_version});
    croak 'key not found in version_key';
  }

  my $encrypted_display_name = encrypt_hex($display_name, $key);
  my $display_name_digest = sha256_hex($display_name);

  my $txn = $master->db->begin;
  my $rows;
  try {
    $rows =
      $master->db->update('users',
      {
        display_name => $encrypted_display_name,
        display_name_digest => $display_name_digest,
      },
      { id => $self->id })->rows;
  }
  catch ($e) {
    LOG_ERROR(uncaught => $e);
    croak 'uncaught:' . $e;
  }

  # $self->id should refer to a row, so this is bad
  if ($rows == 0) {
    LOG_ERROR(missing => $self->id);
    croak 'no rows match update';
  }

  my $audit_display_name_resp = create_audit(
    $master, code => $AUDIT_USER_DISPLAY_NAME,
    source => 'orgs', source_id => $self->id);
  if ($audit_display_name_resp != $RESPONSE_OK) {
    LOG_WARNING(audit => 'user_display_name');
  }

  $txn->commit;

  return $self->refresh($master, $version_key);
}

# password assumed already derived
sub update_password ($self, $master, $version_key, $password) {
  my $txn = $master->db->begin;
  my $rows;
  try {
    $rows =
      $master->db->update('users',
      { password => $password },
      { id => $self->id })->rows;
  }
  catch ($e) {
    LOG_ERROR(uncaught => $e);
    croak 'uncaught:' . $e;
  }

  # $self->id should refer to a row, so this is bad
  if ($rows == 0) {
    LOG_ERROR(missing => $self->id);
    croak 'no rows match update';
  }

  my $audit_password_resp = create_audit(
    $master, code => $AUDIT_USER_PASSWORD,
    source => 'orgs', source_id => $self->id);
  if ($audit_password_resp != $RESPONSE_OK) {
    LOG_WARNING(audit => 'user_password');
  }

  $txn->commit;

  return $self->refresh($master, $version_key);
}

sub update_status ($self, $master, $version_key, $status) {
  my $txn = $master->db->begin;
  my $rows;
  try {
    $rows =
      $master->db->update('users',
      { status => $status },
      { id => $self->id })->rows;
  }
  catch ($e) {
    LOG_ERROR(uncaught => $e);
    croak 'uncaught:' . $e;
  }

  # $self->id should refer to a row, so this is bad
  if ($rows == 0) {
    LOG_ERROR(missing => $self->id);
    croak 'no rows match update';
  }

  my $audit_status_resp = create_audit(
    $master, code => $AUDIT_STATUS,
    source => 'orgs', source_id => $self->id);
  if ($audit_status_resp != $RESPONSE_OK) {
    LOG_WARNING(audit => 'user_status');
  }

  $txn->commit;

  return $self->refresh($master, $version_key);
}

sub reencrypt ($self, $master, $version_key, $key_version) {

  # version_key isa VersionKey
  my $key;
  if (defined $version_key->keymap->{$key_version}) {
    $key = $version_key->keymap->{$key_version};
  } else {
    LOG_ERROR(id => $self->id, missing => $key_version);
    croak 'key not found in version_key';
  }

  my $encrypted_api_secret = encrypt_hex($self->api_secret, $key);
  my $encrypted_display_name = encrypt_hex($self->display_name, $key);
  my $encrypted_email = encrypt_hex($self->email, $key);

  my $txn = $master->db->begin;
  my $rows;
  try {
    $rows =
      $master->db->update('users',
      {
        api_secret => $encrypted_api_secret,
        display_name => $encrypted_display_name,
        email => $encrypted_email,
        key_version => $key_version,
      },
      { id => $self->id })->rows;
  }
  catch ($e) {
    LOG_ERROR(uncaught => $e);
    croak 'uncaught:' . $e;
  }

  if ($rows == 0) {
    LOG_ERROR(missing => $self->id);
    croak 'no rows match update';
  }

  my $audit_status_resp = create_audit(
    $master, code => $AUDIT_STATUS,
    source => 'orgs', source_id => $self->id);
  if ($audit_status_resp != $RESPONSE_OK) {
    LOG_WARNING(audit => 'user_status');
  }

  $txn->commit;

  # commits made, update key_version used
  $self->key_version($key_version);

  return $self->refresh($master, $version_key);
}

sub TO_JSON ($self) {
  {
    id => $self->id,
    display_name => $self->display_name,
    email => $self->email,
    org => $self->org,
    status => $self->status,
    ctime => $self->ctime,
    mtime => $self->mtime,
  }
}

__END__
