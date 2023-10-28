package GrokLOC;
use strictures 2;
use Readonly ();
use experimental qw( signatures );

# ABSTRACT: Global symbols.

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

use base qw(Exporter);

# envs
Readonly::Scalar our $GROKLOC_ENV => 'GROKLOC_ENV';
Readonly::Scalar our $ENV_UNIT => 'UNIT';
Readonly::Scalar our $ENV_DEV => 'DEV';
Readonly::Scalar our $ENV_STAGE => 'STAGE';
Readonly::Scalar our $ENV_PROD => 'PROD';

# status
Readonly::Scalar our $STATUS_NONE => -1;
Readonly::Scalar our $STATUS_UNCONFIRMED => 0;
Readonly::Scalar our $STATUS_ACTIVE => 1;
Readonly::Scalar our $STATUS_INACTIVE => 2;

sub is_status ($status) {
  return (($status =~ /^\d+$/x) &&
      ($STATUS_UNCONFIRMED <= $status <= $STATUS_INACTIVE));
}

# role
Readonly::Scalar our $ROLE_NONE => -1;
Readonly::Scalar our $ROLE_NORMAL => 0;
Readonly::Scalar our $ROLE_ADMIN => 1;
Readonly::Scalar our $ROLE_TEST => 2;

sub is_role ($role) {
  return (($role =~ /^\d+$/x) &&
      ($ROLE_NORMAL <= $role <= $ROLE_TEST));
}

# schema version
Readonly::Scalar our $MIN_SCHEMAVERSION => 0;
Readonly::Scalar our $MAX_SCHEMAVERSION => 99_999;

# time and date - see grokloc-postgres schema where these match
Readonly::Scalar our $MIN_UNIXTIME => 1_672_578_000;
Readonly::Scalar our $MAX_UNIXTIME => 32_503_726_800;

# responses
Readonly::Scalar our $RESPONSE_OK => 0;
Readonly::Scalar our $RESPONSE_NOT_FOUND => 1;
Readonly::Scalar our $RESPONSE_CONFLICT => 2;
Readonly::Scalar our $RESPONSE_NO_ROWS => 3;
Readonly::Scalar our $RESPONSE_ORG_ERR => 4;
Readonly::Scalar our $RESPONSE_USER_ERR => 5;
Readonly::Scalar our $RESPONSE_FAIL => 99;

# routes
Readonly::Scalar our $API_PATH => '/api';
Readonly::Scalar our $API_VERSION_PATH => '/v0';
Readonly::Scalar our $API_ROUTE => $API_PATH . $API_VERSION_PATH;
Readonly::Scalar our $OK_PATH => '/ok';
Readonly::Scalar our $OK_ROUTE => $API_ROUTE . $OK_PATH;
Readonly::Scalar our $ORG_PATH => '/org';
Readonly::Scalar our $ORG_ROUTE => $API_ROUTE . $ORG_PATH;
Readonly::Scalar our $REPOSITORY_PATH => '/repository';
Readonly::Scalar our $REPOSITORY_ROUTE => $API_ROUTE . $REPOSITORY_PATH;
Readonly::Scalar our $USER_PATH => '/user';
Readonly::Scalar our $USER_ROUTE => $API_ROUTE . $USER_PATH;
Readonly::Scalar our $STATUS_PATH => '/status';
Readonly::Scalar our $STATUS_ROUTE => $API_ROUTE . $STATUS_PATH;
Readonly::Scalar our $TOKEN_REQUEST_PATH => '/token';
Readonly::Scalar our $TOKEN_REQUEST_ROUTE => $API_ROUTE . $TOKEN_REQUEST_PATH;

# http headers/related
Readonly::Scalar our $AUTHORIZATION_HEADER => 'Authorization';
Readonly::Scalar our $JWT_TYPE => 'Bearer';
Readonly::Scalar our $JWT_EXPIRATION => 86_400;
Readonly::Scalar our $X_GROKLOC_ID_HEADER => 'X-GrokLOC-ID';
Readonly::Scalar our $X_GROKLOC_TOKEN_REQUEST_HEADER =>
  'X-GrokLOC-Token-Request';

# http messages
Readonly::Scalar our $INTERNAL_ERROR => 'internal error';
Readonly::Scalar our $INADEQUATE_AUTHORIZATION => 'inadequate authorization';
Readonly::Scalar our $RESPONSE_CONFLICT_MSG => 'constraint violated:';

# http stash keys/values
Readonly::Scalar our $STASH_AUTH => 'auth';
Readonly::Scalar our $STASH_USER => 'user';
Readonly::Scalar our $STASH_ORG => 'org';

# auth values must always be monotonically increasing along with auth scope
Readonly::Scalar our $AUTH_NONE => 0;
Readonly::Scalar our $AUTH_USER => 1;
Readonly::Scalar our $AUTH_ORG => 2;
Readonly::Scalar our $AUTH_ROOT => 3;

our @EXPORT_OK = qw(
  is_role
  is_status
  $GROKLOC_ENV
  $ENV_UNIT
  $ENV_DEV
  $ENV_STAGE
  $ENV_PROD
  $MIN_SCHEMAVERSION
  $MAX_SCHEMAVERSION
  $MIN_UNIXTIME
  $MAX_UNIXTIME
  $STATUS_NONE
  $STATUS_UNCONFIRMED
  $STATUS_ACTIVE
  $STATUS_INACTIVE
  $RESPONSE_OK
  $RESPONSE_NOT_FOUND
  $RESPONSE_CONFLICT
  $RESPONSE_CONFLICT_MSG
  $RESPONSE_NO_ROWS
  $RESPONSE_ORG_ERR
  $RESPONSE_USER_ERR
  $RESPONSE_FAIL
  $ROLE_NONE
  $ROLE_NORMAL
  $ROLE_ADMIN
  $ROLE_TEST
  $API_PATH
  $API_VERSION_PATH
  $API_ROUTE
  $OK_PATH
  $OK_ROUTE
  $ORG_PATH
  $ORG_ROUTE
  $REPOSITORY_PATH
  $REPOSITORY_ROUTE
  $USER_PATH
  $USER_ROUTE
  $STATUS_PATH
  $STATUS_ROUTE
  $TOKEN_REQUEST_PATH
  $TOKEN_REQUEST_ROUTE
  $AUTHORIZATION_HEADER
  $JWT_TYPE
  $JWT_EXPIRATION
  $X_GROKLOC_ID_HEADER
  $X_GROKLOC_TOKEN_REQUEST_HEADER
  $INTERNAL_ERROR
  $INADEQUATE_AUTHORIZATION
  $STASH_AUTH
  $STASH_USER
  $STASH_ORG
  $AUTH_NONE
  $AUTH_USER
  $AUTH_ORG
  $AUTH_ROOT
  );

our %EXPORT_TAGS = (all => \@EXPORT_OK);

__END__
