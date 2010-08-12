use strict;
use warnings;

use Test::More tests => 56;
use Number::Phone;
use Number::Phone::FR;


my @nums_intl = qw(
  +33148901515
  +33627362306
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
  1014
  0148901515
  0627362306
  0033148901515
  0033627362306
);

foreach (@nums_FR_ok) {
    ok(Number::Phone::FR::is_valid($_), qq'"$_" is valid');
    isa_ok(Number::Phone::FR->new($_), 'Number::Phone::FR', $_);
}


my @nums_FR_ko = qw(
  150
  170
  180
  +3317
  00330148901515
  +330148901515
  +33014890151
);

foreach (@nums_FR_ko) {
  ok( ! Number::Phone::FR::is_valid($_), qq'"$_" is invalid');
  is( Number::Phone::FR->new($_), undef, qq'"$_" can not be created with Number::Phone::FR');
  is( Number::Phone->new('FR', $_), undef, qq'"$_" can not be created with Number::Phone');
  is( Number::Phone->new($_), undef, qq'"$_" can not be created with Number::Phone');
}


