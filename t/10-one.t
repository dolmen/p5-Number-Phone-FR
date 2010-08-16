use strict;
use warnings;

use Test::More tests => 84;
use Number::Phone;
use Number::Phone::FR;



my @network_FR = qw(
  15
  17
  18
  112
  115
  116000
  118712
  1014
);

my @prefixes_FR = qw(0 4 36510 1633 +33);
my @lignes_FR = qw(
  148901515
  627362306
);

my @nums_intl = map { "+33$_" } @lignes_FR;

my @nums_FR = map { my $n = $_; (map { "$_$n" } @prefixes_FR) } @lignes_FR;

my @nums_FR_ok = (
    @network_FR,
    @nums_FR
);


foreach (@nums_FR_ok) {
    ok(Number::Phone::FR::is_valid($_), qq'"$_" is valid');
    isa_ok(Number::Phone::FR->new($_), 'Number::Phone::FR', $_);
}

foreach (@nums_intl) {
    ok(Number::Phone::FR::is_valid($_), qq'"$_" is valid');
    isa_ok(Number::Phone->new($_), 'Number::Phone::FR', $_);
}


my @nums_FR_ko = (
    (map { $_.'0' } @lignes_FR),
    qw(
  +3317
  00330148901515
  +330148901515
  +33014890151
));

foreach (@nums_FR_ko) {
  ok( ! Number::Phone::FR::is_valid($_), qq'"$_" is invalid');
  is( Number::Phone::FR->new($_), undef, qq'"$_" can not be created with Number::Phone::FR');
  is( Number::Phone->new('FR', $_), undef, qq'"$_" can not be created with Number::Phone');
  is( Number::Phone->new($_), undef, qq'"$_" can not be created with Number::Phone');
}

for my $num (@lignes_FR) {
    for (map { "$_$num" } @prefixes_FR) {
	is( Number::Phone::FR->new($_)->subscriber, $num, "subscriber($_) is $num");
	is( Number::Phone::FR->subscriber($_), $num, "subscriber($_) is $num");
    }
}

