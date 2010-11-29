#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
    # this module doesn't export to main
    package Testing;
    ::use_ok('MooseX::Params::Validate');
}

done_testing();
