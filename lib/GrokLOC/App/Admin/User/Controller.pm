package GrokLOC::App::Admin::User::Controller;
use v5.38;
use Mojo::Base 'GrokLOC::App::Controller';
use strictures 2;
use Carp qw( croak );
use GrokLOC qw( $RESPONSE_NO_ROWS );
use GrokLOC::App::Admin::User ();
use GrokLOC::Log qw( LOG_ERROR );

# ABSTRACT: User controller.

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
    ($event isa 'GrokLOC::App::Admin::User::Events::Create')) {
    LOG_ERROR(event => 'not GrokLOC::App::Admin::User::Events::Create');
    croak('event not GrokLOC::App::Admin::User::Events::Create');
  }
  return GrokLOC::App::Admin::User->create(
    $self->st->master,
    $self->st->version_key,
    display_name => $event->display_name,
    email => $event->email,
    org => $event->org,
    password => $event->password,
    );
}

sub read ($self, $event) {
  unless ((defined $event) &&
    ($event isa 'GrokLOC::App::Admin::User::Events::Read')) {
    LOG_ERROR(event => 'not GrokLOC::App::Admin::User::Events::Read');
    croak('event not GrokLOC::App::Admin::User::Events::Read');
  }
  my $dbo = $self->st->master;
  if ($event->master != 1) {
    $dbo = $self->st->random_replica;
  }
  return GrokLOC::App::Admin::User->read($dbo, $self->st->version_key, $event->id);
}

sub update_display_name ($self, $event) {
  unless ((defined $event) &&
    ($event isa 'GrokLOC::App::Admin::User::Events::UpdateDisplayName')) {
    LOG_ERROR(event => 'not GrokLOC::App::Admin::User::Events::UpdateDisplayName');
    croak('event not GrokLOC::App::Admin::User::Events::UpdateDisplayName');
  }
  my $user = GrokLOC::App::Admin::User->read($self->st->master, $self->st->version_key, $event->id) //
    return $RESPONSE_NO_ROWS;
  return $user->update_display_name($self->st->master,
    $self->st->version_key,
    $event->display_name);
}

sub update_password ($self, $event) {
  unless ((defined $event) &&
    ($event isa 'GrokLOC::App::Admin::User::Events::UpdatePassword')) {
    LOG_ERROR(event => 'not GrokLOC::App::Admin::User::Events::UpdatePassword');
    croak('event not GrokLOC::App::Admin::User::Events::UpdatePassword');
  }
  my $user = GrokLOC::App::Admin::User->read($self->st->master, $self->st->version_key, $event->id) //
    return $RESPONSE_NO_ROWS;
  return $user->update_password($self->st->master,
    $self->st->version_key,
    $event->password);
}

sub update_status ($self, $event) {
  unless ((defined $event) &&
    ($event isa 'GrokLOC::App::Admin::User::Events::UpdateStatus')) {
    LOG_ERROR(event => 'not GrokLOC::App::Admin::User::Events::UpdateStatus');
    croak('event not GrokLOC::App::Admin::User::Events::UpdateStatus');
  }
  my $user = GrokLOC::App::Admin::User->read($self->st->master, $self->st->version_key, $event->id) //
    return $RESPONSE_NO_ROWS;
  return $user->update_status($self->st->master,
    $self->st->version_key,
    $event->status);
}

__END__
