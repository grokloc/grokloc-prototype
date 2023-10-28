package main;
use v5.38;
use Test2::V0 qw( done_testing isnt );
use strictures 2;
use GrokLOC::Safe::Scalar qw( varchar );

# ABSTRACT: scalar and object safety tests

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:bclawsie';

isnt(varchar(q{}), 1);
isnt(varchar(q{""}), 1);
isnt(varchar('<'), 1);
isnt(varchar('>'), 1);
isnt(varchar('window.'), 1);
isnt(varchar('drop table'), 1);
isnt(varchar('insert into'), 1);

done_testing;
