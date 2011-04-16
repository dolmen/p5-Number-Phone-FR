use strict;
use warnings;

use Test::More tests => 162;
use Number::Phone;
use Number::Phone::FR;

use lib 't/lib';
use Numeros;


foreach (@Numeros::ok) {
    ok(Number::Phone::FR::is_valid($_), qq'"$_" is valid');
    my $num = Number::Phone::FR->new($_);
    isa_ok($num, 'Number::Phone::FR', "'$_'");
    is($num->country, 'FR', "$_->country is 'FR'");
    is($num->country_code, 33, "$_->country_code is 33");
    # Number::Phone does support the 2-args syntax only for international format (+33...)
    next unless /^\+33/;
    $num = Number::Phone->new('FR', $_);
    isa_ok($num, 'Number::Phone::FR', "'$_'");
    is($num->country, 'FR', "$_->country is 'FR'");
    is($num->country_code, 33, "$_->country_code is 33");
}

foreach (@Numeros::intl) {
    ok(Number::Phone::FR::is_valid($_), qq'"$_" is valid');
    isa_ok(Number::Phone->new($_), 'Number::Phone::FR', $_);
}


foreach (@Numeros::ko) {
  ok( ! Number::Phone::FR::is_valid($_), qq'"$_" is invalid');
  is( Number::Phone::FR->new($_), undef, qq'"$_" can not be created with Number::Phone::FR');
  is( Number::Phone->new('FR', $_), undef, qq'"$_" can not be created with Number::Phone');
  #is( Number::Phone->new($_), undef, qq'"$_" can not be created with Number::Phone') or diag(Number::Phone->new($_)->country);
}

for my $num (@Numeros::lignes) {
    for (map { "$_$num" } @Numeros::prefixes) {
	is( Number::Phone::FR->new($_)->subscriber, $num, "subscriber($_) is $num");
	is( Number::Phone::FR->subscriber($_), $num, "subscriber($_) is $num");
    }
}

for (@Numeros::network) {
    is( Number::Phone::FR->new($_)->is_network_service, 1, "$_ is network");
    is( Number::Phone::FR->is_network_service($_), 1, "$_ is network");
}

for my $num (@Numeros::lignes_mobiles) {
    for (map { "$_$num" } @Numeros::prefixes) {
	is( Number::Phone::FR->new($_)->is_mobile, 1, "$_ is mobile");
	is( Number::Phone::FR->is_mobile($_), 1, "$_ is mobile");
	isnt( Number::Phone::FR->new($_)->is_geographic, 1, "$_ is mobile");
	isnt( Number::Phone::FR->is_geographic($_), 1, "$_ is mobile");
    }
}
