use strict;
use warnings;

use File::Spec;

use Number::Phone::FR;
$Number::Phone::FR::Class = 'Number::Phone::FR::Full';

do File::Spec->catfile(qw[t 20-format.t]);
die $@ if $@;
