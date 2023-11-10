package GrokLOC::App::Admin::Org;
use v5.38;
use Mojo::Base 'GrokLOC::Models::Base';
use strictures 2;
use Carp qw( croak );
use Crypt::Misc qw( is_v4uuid );
use GrokLOC qw(
  $RESPONSE_CONFLICT
  $RESPONSE_NO_ROWS
  $RESPONSE_OK
  $ROLE_NORMAL
  $STATUS_ACTIVE
  );
use GrokLOC::App::Admin::User ();
use GrokLOC::App::Audit qw(
  $AUDIT_ORG_INSERT
  $AUDIT_ORG_OWNER
  $AUDIT_STATUS
  $AUDIT_USER_INSERT
  create_audit
  );
use GrokLOC::Log qw( LOG_ERROR LOG_WARNING );
use GrokLOC::Safe::Scalar qw( varchar );
use feature 'try';
no warnings 'experimental::try';

# ABSTRACT: Org model.

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

our $SCHEMA_VERSION = 0;

has ['name', 'owner'] => q{};

sub build ($self) {
  return $self;
}

sub validate ($self) {
  $self->SUPER::validate;
  unless (varchar $self->name) {
    LOG_ERROR(varchar => 'name');
    croak 'name fails';
  }
  unless (is_v4uuid $self->owner) {
    LOG_ERROR(owner => 'not is_v4uuid');
    croak 'owner fails';
  }
  return $self;
}

sub insert ($self, $master) {
  try {
    $master->db->insert(
      'orgs',
      {
        id => $self->id,
        name => $self->name,
        owner => $self->owner,
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

sub read ($class, $dbo, $id) {
  my $v =
    $dbo->db->select( 'orgs', [qw{*}], { id => $id } )->hash;
  return undef unless defined $v; # not found == undef

  # for now, treat schema mismatches as fatal
  if ($v->{schema_version} != $SCHEMA_VERSION) {
    LOG_ERROR(id => $id, schema_version => $v->{schema_version});
    croak 'org schema version mismatch';
  }

  # no need to validate - data was validated at time of original row creation
  return $class->new(
    id => $id,
    name => $v->{name},
    owner => $v->{owner},
    ctime => $v->{ctime},
    mtime => $v->{mtime},
    role => $v->{role},
    schema_version => $v->{schema_version},
    signature => $v->{signature},
    status => $v->{status},
    );
}

sub create ($class, $master, $version_key, %args) {
  my $role = $args{role} // $ROLE_NORMAL;

  my $key;
  if (defined $version_key->keymap->{$version_key->current}) {
    $key = $version_key->keymap->{$version_key->current};
  } else {
    LOG_ERROR(missing => $version_key->current);
    croak 'current key not found in version_key';
  }

  # org initially cannot know owner id (owner not created yet),
  my $org = $class->new(
    name => $args{name},
    role => $role,
    status => $STATUS_ACTIVE,
    );

  my $owner = GrokLOC::App::Admin::User->
    new(
    display_name => $args{owner_display_name},
    email => $args{owner_email},
    org => $org->id,
    password => $args{owner_password},
    role => $role,
    status => $STATUS_ACTIVE,
    )->build->validate->encrypt($key, $version_key->current);

  # validated owner id is now known, so populate org owner and validate org
  $org->owner($owner->id)->build->validate;

  my $txn = $master->db->begin;

  my $org_resp = $org->insert($master);
  if ($org_resp != $RESPONSE_OK) {
    LOG_ERROR(insert => 'org');
    croak $org_resp;
  }

  my $owner_resp = $owner->insert($master);
  if ($owner_resp != $RESPONSE_OK) {
    LOG_ERROR(insert => 'user');
    croak $owner_resp;
  }

  my $audit_org_resp =
    create_audit($master, code => $AUDIT_ORG_INSERT,
    source => 'orgs', source_id => $org->id);
  if ($audit_org_resp != $RESPONSE_OK) {
    LOG_WARNING(audit => 'org_insert');
  }

  my $audit_owner_resp =
    create_audit($master, code => $AUDIT_USER_INSERT,
    source => 'users', source_id => $owner->id);
  if ($audit_owner_resp != $RESPONSE_OK) {
    LOG_WARNING(audit => 'user_insert');
  }

  $txn->commit;

  # populate meta
  return $class->read($master, $org->id);
}

sub refresh ($self, $dbo) {
  my $v =
    $dbo->db->select( 'orgs',
    [qw{owner mtime signature status}],
    { id => $self->id } )->hash;
  unless (defined $v) {

    # v undef means row not found which should not be possible
    # for an object previously instantiated
    LOG_ERROR(missing => $self->id);
    croak 'previously read orgs row now missing';
  }

  # only update columns that can possibly change
  $self->owner($v->{owner});
  $self->mtime($v->{mtime});
  $self->signature($v->{signature});
  $self->status($v->{status});

  return $RESPONSE_OK;
}

sub update_owner ($self, $master, $new_owner) {
  my $update_owner_query = <<'UPDATE_OWNER_QUERY';
  update orgs set owner =
  (select id from users where
    id = $1
    and
    org = $2
    and
    status = $3)
    where id = $4
UPDATE_OWNER_QUERY

  my $txn = $master->db->begin;
  my $rows;
  try {
    $rows = $master->db->query(
      $update_owner_query,
      $new_owner, $self->id,
      $STATUS_ACTIVE, $self->id,
      )->rows;
  }
  catch ($e) {

    # a constraint message means NULL was attempted to be assigned
    # to the owner column, which cannot be NULL, which means
    # the select criteria was not met (user in org, and active)
    return $RESPONSE_NO_ROWS if ($e =~ /constraint/imsx);
    LOG_ERROR(uncaught => $e);
    croak 'uncaught:' . $e;
  }

  # $self->id should refer to a row, so this is bad
  if ($rows == 0) {
    LOG_ERROR(missing => $self->id);
    croak 'no rows match update';
  }

  my $audit_owner_resp = create_audit(
    $master, code => $AUDIT_ORG_OWNER,
    source => 'orgs', source_id => $self->id);
  if ($audit_owner_resp != $RESPONSE_OK) {
    LOG_WARNING(audit => 'org_owner');
  }

  $txn->commit;

  return $self->refresh($master);
}

sub update_status ($self, $master, $status) {
  my $txn = $master->db->begin;
  my $rows;
  try {
    $rows =
      $master->db->update('orgs',
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
    LOG_WARNING(audit => 'org_status');
  }

  $txn->commit;

  return $self->refresh($master);
}

sub TO_JSON ($self) {
  {
    id => $self->id,
    name => $self->name,
    owner => $self->owner,
    status => $self->status,
    ctime => $self->ctime,
    mtime => $self->mtime,
  }
}

__END__
