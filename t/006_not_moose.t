#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;

eval <<'EOF';
{
    package Foo;
    use MooseX::Params::Validate;
}
EOF

is( $@, '',
    'loading MX::Params::Validate in a non-Moose class does not blow up' );
ok( Foo->can('validate'), 'validate() sub was added to Foo package' );
