use strict;
use warnings;
use inc::Module::Install;

name 'MooseX-Params-Validate';
all_from 'lib/MooseX/Params/Validate.pm';


requires 'Carp'             => '0';
requires 'Moose'            => '0.58';
requires 'Params::Validate' => '0.88';
requires 'Scalar::Util'     => '0';
requires 'Sub::Exporter'    => '0';

build_requires 'Test::More'      => '0.62';
build_requires 'Test::Exception' => '0.21';

license 'Perl';

WriteAll();
