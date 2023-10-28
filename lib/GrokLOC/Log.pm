package GrokLOC::Log;
use v5.38;
use DateTime ();
use Mojo::JSON qw( encode_json );
use Mojo::Log;

# ABSTRACT: Global logging.

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

use base qw(Exporter);

# replace this at runtime with a dispatcher of your choosing
# levels are: qw( debug info warning error )
#
# default of fatal means nothing will be printed for default case of unit tests
our $LOGGER = Mojo::Log->new(level => 'fatal');

$LOGGER->format(

  # msg_lines can be 'string', ['a', 'b'], {x => 1, y => 2} etc
  sub ( $time, $level, @msg_lines ) {
    return (encode_json { date => DateTime->from_epoch( epoch => int($time) ),
        level => $level,
        msg => @msg_lines }) . "\n";
    } );

sub format_caller ($pkg, $unused, $line) {
  return q{[} . $pkg . q{:} . $line . q{]};
}

sub LOG_DEBUG (%payload) {
  $payload{loc} = format_caller(caller);
  $LOGGER->debug(\%payload);
}

sub LOG_INFO (%payload) {
  $payload{loc} = format_caller(caller);
  $LOGGER->info(\%payload);
}

sub LOG_WARNING (%payload) {
  $payload{loc} = format_caller(caller);
  $LOGGER->warn(\%payload);
}

sub LOG_ERROR (%payload) {
  $payload{loc} = format_caller(caller);
  $LOGGER->error(\%payload);
}

our @EXPORT_OK = qw( $LOGGER LOG_DEBUG LOG_INFO LOG_WARNING LOG_ERROR );
our %EXPORT_TAGS = (all => \@EXPORT_OK);

__END__
