package MooseX::Params::Validate;

use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed';
use Sub::Name    'subname';

use Moose::Exporter;
use Moose::Util::TypeConstraints ();
use Params::Validate             ();

our $VERSION   = '0.06';
our $AUTHORITY = 'cpan:STEVAN';

my %CACHED_PARAM_SPECS;


Moose::Exporter->setup_import_methods( as_is => [qw( validate validatep )] );

my $class = __PACKAGE__;
sub validate {
    my ( $args, %params ) = @_;

    my $cache_key;
    if ( exists $params{MX_PARAMS_VALIDATE_CACHE_KEY} ) {
        $cache_key = $params{MX_PARAMS_VALIDATE_CACHE_KEY};
        delete $params{MX_PARAMS_VALIDATE_CACHE_KEY};
    }
    else {
        $cache_key = ( caller(1) )[3];
    }

    if ( exists $CACHED_PARAM_SPECS{$cache_key} ) {
        ( ref $CACHED_PARAM_SPECS{$cache_key} eq 'HASH' )
            || confess
            "I was expecting a HASH-ref in the cached $cache_key parameter"
            . " spec, you are doing something funky, stop it!";
        %params = %{ $CACHED_PARAM_SPECS{$cache_key} };
    }
    else {
        my $should_cache
            = exists $params{MX_PARAMS_VALIDATE_NO_CACHE} ? 0 : 1;
        delete $params{MX_PARAMS_VALIDATE_NO_CACHE};

        # prepare the parameters ...
        $params{$_} = $class->_convert_to_param_validate_spec( $params{$_} )
            foreach keys %params;
        $CACHED_PARAM_SPECS{$cache_key} = \%params
            if $should_cache;
    }

    my $instance;
    $instance = shift @$args if blessed $args->[0];

    my %args = @$args;

    $class->_coerce_args( \%args, \%params )
        if grep { $params{$_}{coerce} } keys %params;

    %args = Params::Validate::validate_with(
        params => \%args,
        spec   => \%params
    );

    return ( ( $instance ? $instance : () ), %args );
}

sub validatep {
    my ( $args, @params ) = @_;

    my %params = @params;

    my $cache_key;
    if ( exists $params{MX_PARAMS_VALIDATE_CACHE_KEY} ) {
        $cache_key = $params{MX_PARAMS_VALIDATE_CACHE_KEY};
        delete $params{MX_PARAMS_VALIDATE_CACHE_KEY};
    }
    else {
        $cache_key = ( caller(1) )[3];
    }

    my @ordered_params;
    if ( exists $CACHED_PARAM_SPECS{$cache_key} ) {
        ( ref $CACHED_PARAM_SPECS{$cache_key} eq 'ARRAY' )
            || confess
            "I was expecting a ARRAY-ref in the cached $cache_key parameter"
            . " spec, you are doing something funky, stop it!";
        %params         = %{ $CACHED_PARAM_SPECS{$cache_key}->[0] };
        @ordered_params = @{ $CACHED_PARAM_SPECS{$cache_key}->[1] };
    }
    else {
        my $should_cache
            = exists $params{MX_PARAMS_VALIDATE_NO_CACHE} ? 0 : 1;
        delete $params{MX_PARAMS_VALIDATE_NO_CACHE};

        @ordered_params = grep { exists $params{$_} } @params;

        # prepare the parameters ...
        $params{$_} = $class->_convert_to_param_validate_spec( $params{$_} )
            foreach keys %params;

        $CACHED_PARAM_SPECS{$cache_key} = [ \%params, \@ordered_params ]
            if $should_cache;
    }

    my $instance;
    $instance = shift @$args if blessed $args->[0];

    my %args = @$args;

    $class->_coerce_args( \%args, \%params )
        if grep { $params{$_}{coerce} } keys %params;

    %args = Params::Validate::validate_with(
        params => \%args,
        spec   => \%params
    );

    return (
        ( $instance ? $instance : () ),
        @args{@ordered_params}
    );
}

sub _convert_to_param_validate_spec {
    my ( $self, $spec ) = @_;
    my %pv_spec;

    $pv_spec{optional} = $spec->{optional}
        if exists $spec->{optional};

    $pv_spec{default} = $spec->{default}
        if exists $spec->{default};

    $pv_spec{coerce} = $spec->{coerce}
        if exists $spec->{coerce};

    if ( exists $spec->{isa} ) {
        my $constraint;

        if ( blessed( $spec->{isa} )
            && $spec->{isa}->isa('Moose::Meta::TypeConstraint') ) {
            $constraint = $spec->{isa};
        }
        else {
            $constraint
                = Moose::Util::TypeConstraints::find_or_create_type_constraint
                (
                $spec->{isa} => {
                    parent =>
                        Moose::Util::TypeConstraints::find_type_constraint(
                        'Object'),
                    constraint => sub { $_[0]->isa( $spec->{isa} ) }
                }
                );
        }

        $pv_spec{constraint} = $constraint;

        $pv_spec{callbacks} = {
            'checking type constraint' => sub { $constraint->check( $_[0] ) }
        };
    }
    elsif ( exists $spec->{does} ) {

        my $constraint;

        if ( blessed( $spec->{does} )
            && $spec->{does}->isa('Moose::Meta::TypeConstraint') ) {
            $constraint = $spec->{does};
        }
        else {
            $constraint
                = Moose::Util::TypeConstraints::find_or_create_type_constraint
                (
                $spec->{does} => {
                    parent =>
                        Moose::Util::TypeConstraints::find_type_constraint(
                        'Role'),
                    constraint => sub { $_[0]->does( $spec->{does} ) }
                }
                );
        }

        $pv_spec{callbacks} = {
            'checking type constraint' => sub { $constraint->check( $_[0] ) }
        };
    }

    delete $pv_spec{coerce}
        unless $pv_spec{constraint} && $pv_spec{constraint}->has_coercion;

    return \%pv_spec;
}

sub _coerce_args {
    my ( $class, $args, $params ) = @_;

    for my $k ( grep { $params->{$_}{coerce} } keys %{ $params } ) {
        $args->{$k} = $params->{$k}{constraint}->coerce( $args->{$k} );
    }

}

1;

__END__

=pod

=head1 NAME

MooseX::Params::Validate - an extension of Params::Validate for using Moose's types

=head1 SYNOPSIS

  package Foo;
  use Moose;
  use MooseX::Params::Validate;
  
  sub foo {
      my ($self, %params) = validate(\@_, 
          bar => { isa => 'Str', default => 'Moose' },
      );
      return "Horray for $params{bar}!";
  }
  
  sub bar {
      my $self = shift;
      my ($foo, $baz, $gorch) = validatep(\@_, 
          foo   => { isa => 'Foo' },                    
          baz   => { isa => 'ArrayRef | HashRef', optional => 1 }      
          gorch => { isa => 'ArrayRef[Int]', optional => 1 }                                  
      );
      [ $foo, $baz, $gorch ];
  }

=head1 DESCRIPTION

This module fills a gap in Moose by adding method parameter validation 
to Moose. This is just one of many developing options, it should not be 
considered the "official" one by any means though. 

This is an early release of this module, and many things will likely 
change and get added, so watch out :)

=head1 CAVEATS

It is not possible to introspect the method parameter specs, they are 
created as needed when the method is called and cached for subsequent 
calls.

=head1 EXPORTS

=over 4

=item B<validate (\@_, %parameter_spec)>

This behaves similar to the standard Params::Validate C<validate> function
and returns the captured values in a HASH. The one exception being that 
if it spots an instance in the C<@_>, then it will handle it appropriately
(unlike Params::Validate which forces you to shift you C<$self> first). 

The C<%parameter_spec> accepts the following options:

=over 4

=item I<isa>

The C<isa> option can be either; class name, Moose type constraint name or
an anon Moose type constraint.

=item I<does>

The C<does> option can be either; role name or an anon Moose type constraint.

=item I<default>

This is the default value to be used if the value is not supplied.

=item I<optional>

As with Params::Validate, all options are considered required unless otherwise 
specified. This option is passed directly to Params::Validate.

=item I<coerce>

If this is true and the parameter has a type constraint which has
coercions, then the coercion will be called for this parameter. If the
type does have coercions, then this parameter is ignored.

=back

The plan is to support more options in the future as well. 

=item B<validatep (\@_, %parameter_spec)>

The C<%parameter_spec> accepts the same options as above, but returns the 
parameters as positional values instead of a HASH. This is best explained 
by example:

  sub foo {
      my ($self, $foo, $bar) = validatep(\@_, 
          foo => { isa => 'Foo' },                    
          bar => { isa => 'Bar' },        
      );
      $foo->baz($bar);
  }

We capture the order in which you defined the parameters and then return 
them as positionals in the same order. If a param is marked optional and 
not included, then it will be set to C<undef>.

=back

=head1 IMPORTANT NOTE ON CACHING

When C<validate> or C<validatep> are called the first time, the parameter
spec is prepared and cached to avoid unnecessary regeneration. It uses the
fully qualified name of the subroutine (package + subname) as the cache key. 
In 99.999% of the use cases for this module, that will be the right thing 
to do.

However, I have (ab)used this module occasionally to handle dynamic sets 
of parameters. In this special use case you can do a couple things to 
better control the caching behavior. 

=over 4

=item *

Passing in the C<MX_PARAMS_VALIDATE_NO_CACHE> flag in the parameter spec 
this will prevent the parameter spec from being cached. To see an example 
of this, take a look at F<t/003_nocache_flag.t>.

=item *

Passing in C<MX_PARAMS_VALIDATE_CACHE_KEY> with a value to be used as the
cache key will bypass the normal cache key generation. To see an example 
of this, take a look at F<t/004_custom_cache_key.t>.

=back

=head1 METHODS

=over 4

=item B<import>

=back

=head2 Introspection

=over 4

=item B<meta>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
