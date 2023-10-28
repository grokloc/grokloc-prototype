package GrokLOC::App::Admin::Org::Controller;
use v5.38;
use Mojo::Base 'GrokLOC::App::Controller';
use strictures 2;
use Carp qw( croak );
use GrokLOC qw( $RESPONSE_NO_ROWS );
use GrokLOC::App::Admin::Org;
use GrokLOC::Log qw( LOG_ERROR );

# ABSTRACT: Org controller.

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

sub build ($self) {
  return $self;
}

sub validate ($self) {
  $self->SUPER::validate;
  return $self;
}

sub create ($self, $event) {
  unless ((defined $event) &&
    ($event isa 'GrokLOC::App::Admin::Org::Events::Create')) {
    LOG_ERROR(event => 'not GrokLOC::App::Admin::Org::Events::Create');
    croak('event not GrokLOC::App::Admin::Org::Events::Create');
  }
  return GrokLOC::App::Admin::Org->create(
    $self->st->master,
    $self->st->version_key,
    name => $event->name,
    owner_display_name => $event->owner_display_name,
    owner_email => $event->owner_email,
    owner_password => $event->owner_password,
    role => $event->role,
    );
}

sub read ($self, $event) {
  unless ((defined $event) &&
    ($event isa 'GrokLOC::App::Admin::Org::Events::Read')) {
    LOG_ERROR(event => 'not GrokLOC::App::Admin::Org::Events::Read');
    croak('event not GrokLOC::App::Admin::Org::Events::Read');
  }
  my $dbo = $self->st->master;
  if ($event->master != 1) {
    $dbo = $self->st->random_replica;
  }
  return GrokLOC::App::Admin::Org->read($dbo, $event->id);
}

sub update_owner ($self, $event) {
  unless ((defined $event) &&
    ($event isa 'GrokLOC::App::Admin::Org::Events::UpdateOwner')) {
    LOG_ERROR(event => 'not GrokLOC::App::Admin::Org::Events::UpdateOwner');
    croak('event not GrokLOC::App::Admin::Org::Events::UpdateOwner');
  }
  my $org = GrokLOC::App::Admin::Org->read($self->st->master, $event->id) //
    return $RESPONSE_NO_ROWS;
  return $org->update_owner($self->st->master, $event->owner);
}

sub update_status ($self, $event) {
  unless ((defined $event) &&
    ($event isa 'GrokLOC::App::Admin::Org::Events::UpdateStatus')) {
    LOG_ERROR(event => 'not GrokLOC::App::Admin::Org::Events::UpdateStatus');
    croak('event not GrokLOC::App::Admin::Org::Events::UpdateStatus');
  }
  my $org = GrokLOC::App::Admin::Org->read($self->st->master, $event->id) //
    return $RESPONSE_NO_ROWS;
  return $org->update_status($self->st->master, $event->status);
}

__END__
