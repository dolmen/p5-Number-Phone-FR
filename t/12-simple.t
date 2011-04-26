use strict;
use warnings;

use File::Spec;

use Number::Phone::FR;
$Number::Phone::FR::Class = 'Number::Phone::FR::Simple';

do File::Spec->catfile(qw[t 10-one.t]);
die $@ if $@;
