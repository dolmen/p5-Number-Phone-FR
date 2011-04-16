package Numeros;

our @network = qw(
  15
  17
  18
  112
  115
  119
  116000
  118712
  1014
);

our @lignes_mobiles = qw(
  627362306
);

our @lignes_geo = qw(
  148901515
);

our @lignes = (@lignes_geo, @lignes_mobiles);

our @intl = map { "+33$_" } @lignes;

our @prefixes = qw(0 4 36510 1633 +33);
our @avec_prefixe = map { my $n = $_; (map { "$_$n" } @prefixes) } @lignes;

our @ok = (
  @network,
  @avec_prefixe
);

our @ko = (
  (map { $_.'0' } @lignes),
  qw(
    +3317
    00330148901515
    +330148901515
    +33014890151
  )
);

1;