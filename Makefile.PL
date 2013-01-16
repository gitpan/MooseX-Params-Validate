
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "an extension of Params::Validate using Moose's types",
  "AUTHOR" => "Stevan Little <stevan.little\@iinteractive.com>",
  "BUILD_REQUIRES" => {
    "Moose" => 0,
    "Moose::Role" => 0,
    "Roles::Blah" => 0,
    "Test::Fatal" => 0,
    "Test::More" => 0,
    "overload" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "MooseX-Params-Validate",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "MooseX::Params::Validate",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Devel::Caller" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "Params::Validate" => 0,
    "Scalar::Util" => 0,
    "Sub::Exporter" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.17",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



