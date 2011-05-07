#! perl
use strict;
use Test::More tests => 4;

use Number::Phone::FR 'Full';

pass(':Full loading');
is(Number::Phone::FR::Full->country, 'FR', ":Full loading success");
ok(defined(Number::Phone::FR::Full->VERSION), ':Full has a VERSION');
ok(Number::Phone::FR::Full->VERSION > Number::Phone::FR->VERSION, ':Full VERSION is greater than FR');
