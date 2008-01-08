#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 34;
use Test::Exception;

BEGIN {
    use_ok('MooseX::Params::Validate');
}


{
    package Roles::Blah;
    use Moose::Role;
    use MooseX::Params::Validate;
    
    requires 'bar';
    requires 'baz';        
    
    sub foo {
        my ($self, %params) = validate(\@_, 
            bar => { isa => 'Str', default => 'Moose' },
        );
        return "Horray for $params{bar}!";
    }    
    
    package Foo;
    use Moose;
    use Moose::Util::TypeConstraints;
    use MooseX::Params::Validate;

    with 'Roles::Blah';
    
    sub bar {
        my $self   = shift;
        my %params = validate(\@_, 
            foo   => { isa => 'Foo' },                    
            baz   => { isa => 'ArrayRef | HashRef', optional => 1 },  
            gorch => { isa => 'ArrayRef[Int]', optional => 1 },                                            
        );
        [ $params{foo}, $params{baz}, $params{gorch} ];
    } 
    
    sub baz {
        my $self   = shift;
        my %params = validate(\@_,        
            foo => { isa => subtype('Object' => where { $_->isa('Foo') }), optional => 1 }, 
            bar => { does => 'Roles::Blah', optional => 1 }, 
            boo => { does => subtype('Role' => where { $_->does('Roles::Blah') }), optional => 1 },                                      
        );
        return $params{foo} || $params{bar} || $params{boo};
    }   
}


my $foo = Foo->new;
isa_ok($foo, 'Foo');

is($foo->foo, 'Horray for Moose!', '... got the right return value');
is($foo->foo(bar => 'Rolsky'), 'Horray for Rolsky!', '... got the right return value');

is($foo->baz(foo => $foo), $foo, '... foo param must be a Foo instance');

dies_ok { $foo->baz(foo => 10)    } '... the foo param in &baz must be a Foo instance';
dies_ok { $foo->baz(foo => "foo") } '... the foo param in &baz must be a Foo instance';
dies_ok { $foo->baz(foo => [])    } '... the foo param in &baz must be a Foo instance';

is($foo->baz(bar => $foo), $foo, '... bar param must do Roles::Blah');

dies_ok { $foo->baz(bar => 10)    } '... the bar param in &baz must be do Roles::Blah';
dies_ok { $foo->baz(bar => "foo") } '... the bar param in &baz must be do Roles::Blah';
dies_ok { $foo->baz(bar => [])    } '... the bar param in &baz must be do Roles::Blah';

is($foo->baz(boo => $foo), $foo, '... boo param must do Roles::Blah');

dies_ok { $foo->baz(boo => 10)    } '... the boo param in &baz must be do Roles::Blah';
dies_ok { $foo->baz(boo => "foo") } '... the boo param in &baz must be do Roles::Blah';
dies_ok { $foo->baz(boo => [])    } '... the boo param in &baz must be do Roles::Blah';

dies_ok { $foo->bar               } '... bar has a required params';
dies_ok { $foo->bar(foo => 10)    } '... the foo param in &bar must be a Foo instance';
dies_ok { $foo->bar(foo => "foo") } '... the foo param in &bar must be a Foo instance';
dies_ok { $foo->bar(foo => [])    } '... the foo param in &bar must be a Foo instance';
dies_ok { $foo->bar(baz => [])    } '... bar has a required foo param';

is_deeply(
$foo->bar(foo => $foo), 
[$foo, undef, undef], 
'... the foo param in &bar got a Foo instance');

is_deeply(
$foo->bar(foo => $foo, baz => []), 
[$foo, [], undef], 
'... the foo param and baz param in &bar got a correct args');

is_deeply(
$foo->bar(foo => $foo, baz => {}), 
[$foo, {}, undef], 
'... the foo param and baz param in &bar got a correct args');

dies_ok { $foo->bar(foo => $foo, baz => undef)      } '... baz requires a ArrayRef | HashRef';
dies_ok { $foo->bar(foo => $foo, baz => 10)         } '... baz requires a ArrayRef | HashRef';
dies_ok { $foo->bar(foo => $foo, baz => 'Foo')      } '... baz requires a ArrayRef | HashRef';
dies_ok { $foo->bar(foo => $foo, baz => \(my $var)) } '... baz requires a ArrayRef | HashRef';

is_deeply(
$foo->bar(foo => $foo, gorch => [1, 2, 3]), 
[$foo, undef, [1, 2, 3]], 
'... the foo param in &bar got a Foo instance');

dies_ok { $foo->bar(foo => $foo, gorch => undef)      } '... gorch requires a ArrayRef[Int]';
dies_ok { $foo->bar(foo => $foo, gorch => 10)         } '... gorch requires a ArrayRef[Int]';
dies_ok { $foo->bar(foo => $foo, gorch => 'Foo')      } '... gorch requires a ArrayRef[Int]';
dies_ok { $foo->bar(foo => $foo, gorch => \(my $var)) } '... gorch requires a ArrayRef[Int]';
dies_ok { $foo->bar(foo => $foo, gorch => [qw/one two three/]) } '... gorch requires a ArrayRef[Int]';

