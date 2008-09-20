#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    # this module doesn't export to main
    package Testing;
    ::use_ok('MooseX::Params::Validate');
}
