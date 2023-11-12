package GrokLOC::App::Client;
use v5.38;
use strictures 2;
use Carp qw( croak );
use Crypt::Misc qw( is_v4uuid );
use Mojo::JSON qw( decode_json );
use Mojo::Base -base;
use URI ();
use GrokLOC qw(
  $AUTHORIZATION_HEADER
  $OK_ROUTE
  $ORG_ROUTE
  $STATUS_ROUTE
  $TOKEN_REQUEST_ROUTE
  $X_GROKLOC_ID_HEADER
  $X_GROKLOC_TOKEN_REQUEST_HEADER
  );
use GrokLOC::App::JWT qw( encode_token_request token_to_header_val );
use GrokLOC::Log qw( LOG_ERROR );

# ABSTRACT: Client library for app webservice.

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

has ['id', 'api_secret', 'token', 'url'] => q{};
has token_expires => 0;
has ua => undef;

sub build ($self) {
  my $u = $self->url // croak 'missing url';
  $u =~ s/\/$//xo; # rm trailing /
  $self->url($u);
  return $self;
}

sub validate ($self) {

  # token can remain q{}, token_expires can be 0
  unless (is_v4uuid $self->id) {
    LOG_ERROR(id => 'not is_v4uuid');
    croak 'id fails';
  }
  unless (is_v4uuid $self->api_secret) {
    LOG_ERROR(api_secret => 'not is_v4uuid');
    croak 'api_secret fails';
  }
  unless ($self->ua isa 'Mojo::UserAgent') {
    LOG_ERROR(ua => 'malformed');
    croak 'ua fails';
  }
  unless (defined $self->url && URI->new($self->url)->has_recognized_scheme) {
    LOG_ERROR(url => 'malformed');
    croak 'url fails';
  }
  return $self;
}

sub token_request ($self) {
  my $now = time;
  if (defined $self->token && defined $self->token_expires && $self->token_expires > $now) {

    # token is present and not expired
    return {
      $X_GROKLOC_ID_HEADER => $self->id,
      $AUTHORIZATION_HEADER => token_to_header_val($self->token),
      };
  } else {

    # otherwise, get a new one
    my $headers = {
      $X_GROKLOC_ID_HEADER => $self->id,
      $X_GROKLOC_TOKEN_REQUEST_HEADER =>
        encode_token_request($self->id, $self->api_secret),
      };

    my $route = $self->url . $TOKEN_REQUEST_ROUTE;
    my $result = $self->ua->post($route => $headers)->result;
    if (200 != $result->code) {
      croak 'token request code ' . $result->code;
    }

    my $token_fields = decode_json $result->body;
    croak 'body parse'
      unless (defined $token_fields && ref $token_fields eq 'HASH');
    croak 'missing token' unless (exists $token_fields->{token});
    croak 'missing expires' unless (exists $token_fields->{expires});
    $self->token($token_fields->{token});
    $self->token_expires($token_fields->{expires});
    return {
      $X_GROKLOC_ID_HEADER => $self->id,
      $AUTHORIZATION_HEADER => token_to_header_val($self->token),
      };
  }
}

sub ok ($self) {
  my $route = $self->url . $OK_ROUTE;
  my $result = $self->ua->get($route)->result;
  croak 'status code ' . $result->code if (200 != $result->code);
  return $result->json;
}

sub status ($self) {
  my $headers = $self->token_request;
  my $route = $self->url . $STATUS_ROUTE;
  my $result = $self->ua->get($route => $headers)->result;
  croak 'status code ' . $result->code if (200 != $result->code);
  return $result->json;
}

# org related
sub org_create ($self, %args) {
  my $headers = $self->token_request;
  my $route = $self->url . $ORG_ROUTE;
  return $self->ua->post($route => $headers => json => \%args)->result;
}

sub org_read ($self, $id) {
  my $headers = $self->token_request;
  my $route   = $self->url . $ORG_ROUTE . q{/} . $id;
  return $self->ua->get($route => $headers)->result;
}

sub org_update ($self, $id, %args) {
  my $headers = $self->token_request;
  my $route   = $self->url . $ORG_ROUTE . q{/} . $id;
  return $self->ua->put($route => $headers => json => \%args)->result;
}

sub org_delete ($self, $id) {
  my $headers = $self->token_request;
  my $route   = $self->url . $ORG_ROUTE . q{/} . $id;
  return $self->ua->delete($route => $headers)->result;
}

__END__
