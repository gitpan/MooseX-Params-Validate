use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;

{
    package Foo;

    use Moose;
    use MooseX::Params::Validate qw( :deprecated );

}

ok( Foo->can('validate'), ':deprecated tag exports validate' );
ok( Foo->can('validatep'), ':deprecated tag exports validatep' );
