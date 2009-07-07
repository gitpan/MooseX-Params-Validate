#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;

{
    package Foo;
    use Moose;
    use MooseX::Params::Validate;

    sub foo {
        my $self   = shift;
        my %params = validated_hash(
            \@_,
            foo   => { isa => 'Str' },
        );
        return $params{foo};
    }

    around 'foo' => sub {
        my $orig = shift;
        my $self = shift;
        my %p    = @_;

        my @args = ( bar => delete $p{bar} );

        my %params = validated_hash(
                                   \@args,
                                    bar => { isa => 'Str' },
                                   );

        $params{bar}, $self->$orig(%p);
    };

    around 'foo' => sub {
        my $orig = shift;
        my $self = shift;
        my %p    = @_;

        my @args = ( quux => delete $p{quux} );

        my %params = validated_hash(
                                   \@args,
                                    quux => { isa => 'Str' },
                                   );

        $params{quux}, $self->$orig(%p);
    };
}

{
    my $foo = Foo->new;

    is_deeply( [ $foo->foo( foo => 1, bar => 2, quux => 3 ) ],
               [ 3, 2, 1 ],
               'multiple around wrappers can safely be cached' );

    is_deeply( [ $foo->foo( foo => 1, bar => 2, quux => 3 ) ],
               [ 3, 2, 1 ],
               'multiple around wrappers can safely be cached (2nd time)' );
}

