#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 9;
use Test::Exception;

{
    package Foo;
    use Moose;
    use Moose::Util::TypeConstraints;
    use MooseX::Params::Validate;

    subtype 'Size'
        => as 'Int'
        => where { $_ >= 0 };

    coerce 'Size'
        => from 'ArrayRef'
        => via { scalar @{ $_ } };

    sub bar {
        my $self   = shift;
        my %params = validate(\@_,
            size1  => { isa => 'Size', coerce => 1 },
            size2  => { isa => 'Size', coerce => 0 },
            number => { isa => 'Num',  coerce => 1 },
        );
        [ $params{size1}, $params{size2}, $params{number} ];
    }

    sub baz {
        my $self   = shift;
        my ( $size1, $size2, $number ) = validatep(\@_,
            size1  => { isa => 'Size', coerce => 1 },
            size2  => { isa => 'Size', coerce => 0 },
            number => { isa => 'Num',  coerce => 1 },
        );
        [ $size1, $size2, $number ];
    }
}


my $foo = Foo->new;
isa_ok($foo, 'Foo');

is_deeply(
$foo->bar( size1 => 10, size2 => 20, number => 30 ),
[ 10, 20, 30 ],
'got the return value right without coercions');

is_deeply(
$foo->bar( size1 => [ 1, 2, 3 ], size2 => 20, number => 30 ),
[ 3, 20, 30 ],
'got the return value right with coercions for size1');

dies_ok
{ $foo->bar( size1 => 30, size2 => [ 1, 2, 3], number => 30 ) }
'... the size2 param cannot be coerced';

dies_ok
{ $foo->bar( size1 => 30, size2 => 10, number => 'something' ) }
'... the number param cannot be coerced';

is_deeply(
$foo->baz( size1 => 10, size2 => 20, number => 30 ),
[ 10, 20, 30 ],
'got the return value right without coercions');

is_deeply(
$foo->baz( size1 => [ 1, 2, 3 ], size2 => 20, number => 30 ),
[ 3, 20, 30 ],
'got the return value right with coercions for size1');

dies_ok
{ $foo->baz( size1 => 30, size2 => [ 1, 2, 3], number => 30 ) }
'... the size2 param cannot be coerced';

dies_ok
{ $foo->baz( size1 => 30, size2 => 10, number => 'something' ) }
'... the number param cannot be coerced';
