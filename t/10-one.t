use strict;
use warnings;

use Test::More tests => 24;
use Number::Phone;
use Number::Phone::FR;


my @nums_intl = qw(
  +33627362306
  +33148901515
);

foreach (@nums_intl) {
    ok(Number::Phone::FR::is_valid($_), qq'"$_" is valid');
    isa_ok(Number::Phone->new($_), 'Number::Phone::FR', $_);
}


my @nums_FR_ok = qw(
  15
  17
  18
  112
  115
  116000
  118712
);

foreach (@nums_FR_ok) {
    ok(Number::Phone::FR::is_valid($_), qq'"$_" is valid');
    isa_ok(Number::Phone::FR->new($_), 'Number::Phone::FR', $_);
}


my @nums_FR_ko = qw(
  150
  170
  180
);

foreach (@nums_FR_ko) {
  ok( ! Number::Phone::FR::is_valid($_), qq'"$_" is invalid');
  is( Number::Phone::FR->new($_), undef, qq'"$_" can not be created');
}

