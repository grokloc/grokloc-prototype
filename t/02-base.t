package main;
use v5.38;
use Crypt::Misc qw( random_v4uuid );
use English qw(-no_match_vars);
use Test2::V0 qw( done_testing is note ok );
use Test2::Tools::Exception qw( dies lives );
use strictures 2;
use GrokLOC qw(
  $MAX_SCHEMAVERSION
  $MAX_UNIXTIME
  $MIN_SCHEMAVERSION
  $MIN_UNIXTIME
  $ROLE_NORMAL
  $ROLE_TEST
  $STATUS_ACTIVE
  $STATUS_INACTIVE
  $STATUS_UNCONFIRMED
  );
use GrokLOC::Models::Base ();

# ABSTRACT: model base tests

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

# ok

my $b;
my $id = random_v4uuid;
my $signature = random_v4uuid;

ok(
  lives {
    $b = GrokLOC::Models::Base->new(
      id => $id,
      ctime => $MIN_UNIXTIME,
      mtime => $MAX_UNIXTIME,
      role => $ROLE_NORMAL,
      schema_version => $MIN_SCHEMAVERSION,
      signature => $signature,
      status => $STATUS_ACTIVE,
      )->validate;
  },
  ) or note($EVAL_ERROR);

is($b->id, $id);
is($b->ctime, $MIN_UNIXTIME);
is($b->mtime, $MAX_UNIXTIME);
is($b->role, $ROLE_NORMAL);
is($b->schema_version, $MIN_SCHEMAVERSION);
is($b->signature, $signature);
is($b->status, $STATUS_ACTIVE);

# bad id
ok(
  dies {
    GrokLOC::Models::Base->new(
      id => 'hello',
      ctime => $MIN_UNIXTIME,
      mtime => $MAX_UNIXTIME,
      role => $ROLE_NORMAL,
      schema_version => $MIN_SCHEMAVERSION,
      signature => random_v4uuid,
      status => $STATUS_UNCONFIRMED,
      )->validate;
  },
  ) or note($EVAL_ERROR);

# ctime underflow
ok(
  dies {
    GrokLOC::Models::Base->new(
      id => random_v4uuid,
      ctime => $MIN_UNIXTIME-1,
      mtime => $MAX_UNIXTIME,
      role => $ROLE_NORMAL,
      schema_version => $MIN_SCHEMAVERSION,
      signature => random_v4uuid,
      status => $STATUS_UNCONFIRMED,
      )->validate;
  },
  ) or note($EVAL_ERROR);

# ctime overflow
ok(
  dies {
    GrokLOC::Models::Base->new(
      id => random_v4uuid,
      ctime => $MAX_UNIXTIME+1,
      mtime => $MAX_UNIXTIME,
      role => $ROLE_NORMAL,
      schema_version => $MIN_SCHEMAVERSION,
      signature => random_v4uuid,
      status => $STATUS_UNCONFIRMED,
      )->validate;
  },
  ) or note($EVAL_ERROR);

# mtime underflow
ok(
  dies {
    GrokLOC::Models::Base->new(
      id => random_v4uuid,
      ctime => $MIN_UNIXTIME,
      mtime => $MIN_UNIXTIME-1,
      role => $ROLE_NORMAL,
      schema_version => $MIN_SCHEMAVERSION,
      signature => random_v4uuid,
      status => $STATUS_UNCONFIRMED,
      )->validate;
  },
  ) or note($EVAL_ERROR);

# mtime overflow
ok(
  dies {
    GrokLOC::Models::Base->new(
      id => random_v4uuid,
      ctime => $MIN_UNIXTIME,
      mtime => $MAX_UNIXTIME+1,
      role => $ROLE_NORMAL,
      schema_version => $MIN_SCHEMAVERSION,
      signature => random_v4uuid,
      status => $STATUS_UNCONFIRMED,
      )->validate;
  },
  ) or note($EVAL_ERROR);

# role underflow
ok(
  dies {
    GrokLOC::Models::Base->new(
      id => random_v4uuid,
      ctime => $MIN_UNIXTIME,
      mtime => $MAX_UNIXTIME,
      role => $ROLE_NORMAL-1,
      schema_version => $MIN_SCHEMAVERSION,
      signature => random_v4uuid,
      status => $STATUS_UNCONFIRMED,
      )->validate;
  },
  ) or note($EVAL_ERROR);

# role overflow
ok(
  dies {
    GrokLOC::Models::Base->new(
      id => random_v4uuid,
      ctime => $MIN_UNIXTIME,
      mtime => $MAX_UNIXTIME,
      role => $ROLE_TEST+1,
      schema_version => $MIN_SCHEMAVERSION,
      signature => random_v4uuid,
      status => $STATUS_UNCONFIRMED,
      )->validate;
  },
  ) or note($EVAL_ERROR);

# schemaversion underflow
ok(
  dies {
    GrokLOC::Models::Base->new(
      id => random_v4uuid,
      ctime => $MIN_UNIXTIME,
      mtime => $MAX_UNIXTIME,
      role => $ROLE_TEST,
      schema_version => $MIN_SCHEMAVERSION-1,
      signature => random_v4uuid,
      status => $STATUS_UNCONFIRMED,
      )->validate;
  },
  ) or note($EVAL_ERROR);

# schemaversion overflow
ok(
  dies {
    GrokLOC::Models::Base->new(
      id => random_v4uuid,
      ctime => $MIN_UNIXTIME,
      mtime => $MAX_UNIXTIME,
      role => $ROLE_TEST,
      schema_version => $MAX_SCHEMAVERSION+1,
      signature => random_v4uuid,
      status => $STATUS_UNCONFIRMED,
      )->validate;
  },
  ) or note($EVAL_ERROR);

# bad signature
ok(
  dies {
    GrokLOC::Models::Base->new(
      id => random_v4uuid,
      ctime => $MIN_UNIXTIME,
      mtime => $MAX_UNIXTIME,
      role => $ROLE_TEST,
      schema_version => $MAX_SCHEMAVERSION,
      signature => 'hello',
      status => $STATUS_UNCONFIRMED,
      )->validate;
  },
  ) or note($EVAL_ERROR);

# status underflow
ok(
  dies {
    GrokLOC::Models::Base->new(
      id => random_v4uuid,
      ctime => $MIN_UNIXTIME,
      mtime => $MAX_UNIXTIME,
      role => $ROLE_TEST,
      schema_version => $MAX_SCHEMAVERSION,
      signature => random_v4uuid,
      status => $STATUS_UNCONFIRMED-1,
      )->validate;
  },
  ) or note($EVAL_ERROR);

# status overflow
ok(
  dies {
    GrokLOC::Models::Base->new(
      id => random_v4uuid,
      ctime => $MIN_UNIXTIME,
      mtime => $MAX_UNIXTIME,
      role => $ROLE_TEST,
      schema_version => $MAX_SCHEMAVERSION,
      signature => random_v4uuid,
      status => $STATUS_INACTIVE+1,
      )->validate;
  },
  ) or note($EVAL_ERROR);

done_testing;
