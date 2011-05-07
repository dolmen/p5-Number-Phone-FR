#! perl
use strict;
use Test::More tests => 2;

use Number::Phone::FR 'Simple';

pass(':Simple loading');
is(Number::Phone::FR::Simple->country, 'FR', ":Simple loading success");
