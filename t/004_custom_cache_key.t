#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;
use Scalar::Util;

{
    package Foo;
    use Moose;
    use MooseX::Params::Validate;

    sub bar {
        my ( $self, $args, $params ) = @_;
        $params->{MX_PARAMS_VALIDATE_CACHE_KEY}
            = Scalar::Util::refaddr($self);
        return validated_hash( $args, %$params );
    }
}

my $foo = Foo->new;
isa_ok( $foo, 'Foo' );

lives_ok {
    $foo->bar( [ baz => 1 ], { baz => { isa => 'Int' } } );
}
'... successfully applied the parameter validation';

throws_ok {
    $foo->bar( [ baz => [ 1, 2, 3 ] ], { baz => { isa => 'ArrayRef' } } );
} qr/\QThe 'baz' parameter/,
'... successfully re-used the parameter validation for this instance';

my $foo2 = Foo->new;
isa_ok( $foo2, 'Foo' );

lives_ok {
    $foo2->bar( [ baz => [ 1, 2, 3 ] ], { baz => { isa => 'ArrayRef' } } );
}
'... successfully applied the parameter validation';

throws_ok {
    $foo2->bar( [ baz => 1 ], { baz => { isa => 'Int' } } );
} qr/\QThe 'baz' parameter/,
'... successfully re-used the parameter validation for this instance';

lives_ok {
    $foo->bar( [ baz => 1 ], { baz => { isa => 'Int' } } );
}
'... successfully applied the parameter validation (just checking)';

