
package MooseX::Params::Validate;

use Moose 'blessed';
use Moose::Util::TypeConstraints ();
use Params::Validate ();

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

sub import {
    my $class = shift;
    my $pkg   = caller;
    
    return if $pkg eq 'main';
    
    return unless $pkg->can('meta')
               && $pkg->meta->isa('Class::MOP::Class');
    
    $pkg->meta->alias_method('validate' => sub {
        my ($args, %params) = @_;
        
        # prepare the parameters ...
        $params{$_} = $class->_convert_to_param_validate_spec($params{$_})
            foreach keys %params;
            
        my $instance;
        $instance = shift @$args if blessed $args->[0];
        
        my %args = Params::Validate::validate(@$args, \%params);
        
        return (($instance ? $instance : ()), %args);        
    });
}

sub _convert_to_param_validate_spec {
    my ($self, $spec) = @_;
    my %pv_spec;
    
    $pv_spec{optional} = $spec->{optional}
        if exists $spec->{optional};
        
    $pv_spec{default} = $spec->{default}
        if exists $spec->{default};
    
    if (exists $spec->{isa}) {
        my $constraint;
        
        if (blessed($spec->{isa}) && $spec->{isa}->isa('Moose::Meta::TypeConstraint')) {
			$constraint = $spec->{isa};
		}
        else {
            if ($spec->{isa} =~ /\|/) {
    	        my @types = split /\s*\|\s*/ => $spec->{isa};
    	        $constraint = Moose::Util::TypeConstraints::create_type_constraint_union(
    	            @types
    	        );
    	    }        
            else {
                # otherwise assume it is a constraint
    		    $constraint = Moose::Util::TypeConstraints::find_type_constraint($spec->{isa});	    
    		    # if the constraing it not found ....
    		    unless (defined $constraint) {
    		        # assume it is a foreign class, and make 
    		        # an anon constraint for it 
    		        $constraint = Moose::Util::TypeConstraints::subtype(
    		            'Object', 
    		            Moose::Util::TypeConstraints::where { $_->isa($spec->{isa}) }
    		        );
    		    }
            }
        }
        
        $pv_spec{callbacks} = {
            'checking type constraint' => sub { $constraint->check($_[0]) }
        };
    }
    elsif (exists $spec->{does}) {
        
        my $constraint;	    

	    if (blessed($spec->{does}) && $spec->{does}->isa('Moose::Meta::TypeConstraint')) {
			$constraint = $spec->{does};
		}
		else {
		    # otherwise assume it is a constraint
		    $constraint = Moose::Util::TypeConstraints::find_type_constraint($spec->{does});	      
		    # if the constraing it not found ....
		    unless (defined $constraint) {	  		        
		        # assume it is a foreign class, and make 
		        # an anon constraint for it 
		        $constraint = Moose::Util::TypeConstraints::subtype(
		            'Role', 
		            Moose::Util::TypeConstraints::where { $_->does($spec->{does}) }
		        );
		    }			    
		}	    
		
        $pv_spec{callbacks} = {
            'checking type constraint' => sub { $constraint->check($_[0]) }
        };	
	}
	
	# TODO:
	# add coercion here
    
    return \%pv_spec;
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
      my $self   = shift;
      my %params = validate(\@_, 
          foo => { isa => 'Foo' },                    
          baz => { isa => 'ArrayRef | HashRef', optional => 1 }                        
      );
      [ $params{foo}, $params{baz} ];
  }

=head1 DESCRIPTION

This module fills a gap in Moose by adding method parameter validation 
to Moose. This is just one of many developing options, it should be 
considered the "official" one by any means though. 

This is an early release of this module, and many things will likely 
change and get added, so watch out :)

=head1 CAVEATS

It is not possible to introspect the method parameter specs, they are 
created as needed when the method is called and tossed aside afterwards.

This is probably not the most efficient way to do this, but it works 
for what it is. 

=head1 EXPORTS

=over 4

=item B<validate (\@_, %parameter_spec)>

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

=back

The plan is to support more options in the future as well. 

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

Copyright 2007 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
