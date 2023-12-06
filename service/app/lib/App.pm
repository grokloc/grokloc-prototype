package App;
use v5.38;
use strictures 2;
use Carp qw( croak );
use DateTime ();
use Mojo::Base 'Mojolicious';
use Mojo::JSON qw( encode_json );
use GrokLOC qw(
  $API_ROUTE
  $GROKLOC_ENV
  $INTERNAL_ERROR
  $OK_ROUTE
  $ORG_PATH
  $STATUS_PATH
  $TOKEN_REQUEST_PATH
  $USER_PATH
  );
use GrokLOC::App::Admin::Org::Controller ();
use GrokLOC::App::Admin::User::Controller ();
use GrokLOC::App::State::Init qw( state_from_env );

# ABSTRACT: App startup.

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

sub startup ($self) {
  my $level = $ENV{$GROKLOC_ENV} // croak 'level env';
  my $st = state_from_env($level);
  $self->helper( st => sub ($self) { return $st; } );
  my $started_at = time;

  # format json logging
  $self->log->format(

    # msg_lines can be 'string', ['a', 'b'], {x => 1, y => 2} etc
    # note that this is the same sub as used in GrokLOC::Log
    sub ($time, $level, @msg_lines) {
      return (encode_json { date => DateTime->from_epoch(epoch => int($time)),
          level => $level,
          msg => @msg_lines }) . "\n";
      } );

  $self->log->info('app init');

  # start time
  $self->helper(started_at => sub ($self) { return $started_at; });

  # controllers
  my $user_controller =
    GrokLOC::App::Admin::User::Controller->new(st => $st)->build()->validate();
  $self->helper(user_controller => sub ($self) { return $user_controller; });

  my $org_controller = GrokLOC::App::Admin::Org::Controller->new(st => $st)->build()->validate();
  $self->helper(org_controller => sub ($self) { return $org_controller; });

  # app serving setup
  $self->hooks_init;
  $self->routes_init;

  $self->log->info('app startup');
  return;
}

sub hooks_init ($self) {
  $self->hook(
    before_render => sub ( $c, $args ) {
      return unless my $template = $args->{template};
      return unless $template eq 'exception';
      return unless $c->accepts('json');
      $self->log->error( $c->stash('exception') );
      $args->{json} = { error => $INTERNAL_ERROR };
      },
    );
  return;
}

sub routes_init ($self) {
  my $r = $self->routes;

  # ok, no auth
  $r->get($OK_ROUTE)->to('api-v0-ok#ok');

  # all handlers under /api/v0 requires user,org,auth in the stash
  #
  # child routes of $with_user should not include the /api/v0 part
  my $with_user = $r->under($API_ROUTE)->to('api-v0-auth#with_user');

  # some handlers under /api/v0 also require a user/org/auth
  # token in the stash
  #
  # child routes of $with_token should not include the /api/v0 part
  my $with_token = $r->under($API_ROUTE)->to('api-v0-auth#with_token');

  # request a new token
  $with_user->post($TOKEN_REQUEST_PATH)->to('api-v0-auth#new_token');

  # root-authenticated status
  $with_token->get($STATUS_PATH)->to('api-v0-status#status');

  # org related
  # create a new org
  $with_token->post($ORG_PATH)->to('api-v0-org#post');

  my $org_id_path = $ORG_PATH . '/:id';

  my $with_org_id =
    $with_token->under($org_id_path)->to('api-v0-validators#with_id');

  # read an org
  $with_org_id->get(q{})->to('api-v0-org#get');

  # update an org
  $with_org_id->put(q{})->to('api-v0-org#put');

  # delete an org (set status to inactive)
  $with_org_id->delete(q{})->to('api-v0-org#del');

  # user related
  # create a new user
  $with_token->post($USER_PATH)->to('api-v0-user#post');

  my $user_id_path = $USER_PATH . '/:id';

  my $with_user_id =
    $with_token->under($user_id_path)->to('api-v0-validators#with_user_id');

  # read a user
  $with_user_id->get(q{})->to('api-v0-user#get');

  # update a user
  $with_user_id->put(q{})->to('api-v0-user#put');

  # delete a user (set status to inactive)
  $with_user_id->delete(q{})->to('api-v0-user#del');

  # catch-all not-found
  $r->any(
    '/*whatever' => { whatever => q{} } => sub ($c) {
      my $whatever = $c->param('whatever');
      $c->render(
        format => 'json',
        json   => { error => $whatever . ': not found' },
        status => 404,
        );
      return undef;
      },
    );

  return;
}

__END__
