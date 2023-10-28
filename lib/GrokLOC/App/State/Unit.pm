package GrokLOC::App::State::Unit;
use v5.38;
use strictures 2;
use Carp qw( croak );
use Crypt::Misc qw( random_v4uuid );
use English qw(-no_match_vars);
use Mojo::Pg ();
use GrokLOC qw( $ROLE_TEST );
use GrokLOC::App::Admin::Org ();
use GrokLOC::App::State ();
use GrokLOC::Crypt qw( rand_aes_key rand_argon2_password );
use GrokLOC::Crypt::VersionKey ();

# ABSTRACT: Initialize State instance for the unit environment.

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

sub new {
  my $db = $ENV{POSTGRES_APP_URL} // croak 'POSTGRES_APP_URL not found in env';
  my $master = Mojo::Pg->new($db) // croak "new db: $ERRNO";
  my $repository_base = $ENV{REPOSITORY_BASE} // croak 'REPOSITORY_BASE not found in env';

  my $current_key = random_v4uuid;

  # in addition to the current_key, insert a random key which is "old"
  my $version_key = GrokLOC::Crypt::VersionKey->new(
    current => $current_key,
    keymap => { $current_key => rand_aes_key, random_v4uuid() => rand_aes_key },
    )->build->validate;

  my $root_org_obj = GrokLOC::App::Admin::Org->create(
    $master,
    $version_key,
    name => random_v4uuid,
    owner_display_name => random_v4uuid,
    owner_email => random_v4uuid,
    owner_password => rand_argon2_password,
    role => $ROLE_TEST,
    );

  return GrokLOC::App::State->new(
    master => $master,
    replicas => [$master],
    kdf_iterations => 1,
    repository_base => $repository_base,
    signing_key => random_v4uuid,
    version_key => $version_key,
    root_org => $root_org_obj->id,
    root_user => $root_org_obj->owner,
    )->build->validate;
}

__END__
