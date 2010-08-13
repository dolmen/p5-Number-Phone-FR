use utf8;
use strict;
use warnings;

package Number::Phone::FR;

our $VERSION = '0.01';

use Carp;
use Number::Phone;

use base 'Number::Phone';


sub country_code() { 33 }

#$Number::Phone::subclasses{country_code()} = __PACKAGE__;

use Scalar::Util 'blessed';

our $use_cache = 1;
my %cache;

use constant RE_STD_LINE =>
  qr{
    ^
    (?:
       \+33          # Préfixe international (+33 numéro)
     | (?:3651)?
       (?:
         [04789]     # Transporteur par défaut (0) ou Sélection du transporteur
       | 16 [0-9]{2} # Sélection du transporteur
       ) (?:033)?    # Préfixe international (0033 numéro)
    ) ([1-9][0-9]{8})  # Numéro de ligne
    $
  }xs;

use constant RE_FULL =>
  qr{
  ^ (?:
    1 (?:
        0[0-9]{2}  # Opérateur
      | 5          # SAMU
      | 7          # Police/gendarmerie
      | 8          # Pompiers
      | 1 (?:
            2      # Numéro d'urgence européen
          | 5      # Urgences sociales
	  | 6000          # 116000 : Enfance maltraitée
          | 8[0-9]{3}     # 118XYZ : Renseignements téléphoniques
	  | 9      # Enfance maltraitée
	  )
      )
  | 3[0-9]{3}
  | (?:
       \+33          # Préfixe international (+33 numéro)
     | (?:3651)?     # Préfixe d'anonymisation
       (?:
         [04789]     # Transporteur par défaut (0) ou Sélection du transporteur
       | 16 [0-9]{2} # Sélection du transporteur
       ) (?:033)?    # Préfixe international (0033 numéro)
    ) [1-9][0-9]{8}  # Numéro de ligne
  ) $
  }xs;




sub new
{
    my $class = shift;
    my $number = shift;
    croak "No number given to ".__PACKAGE__."->new()\n" unless defined $number;
    croak "Invalid phone number (scalar expected)" if ref $number;
    my $num = $number;
    $num =~ s/[^+0-9]//g;
    return Number::Phone->new("+$1") if $num =~ /^(?:\+|00)((?:[^3]|3[^3]).*)$/;

    return is_valid($number) ? bless(\$num, $class) : undef;
}



sub is_valid
{
    my ($number) = (@_);
    return 1 if blessed($number) && $number->isa(__PACKAGE__);

    if ($use_cache && exists $cache{$number}) {
	return $cache{$number}->{is_valid};
    }
    #print "is_valid($number)\n";
    #print RE_FULL."\n";
    my $is_valid = $number =~ RE_FULL;
    $cache{$number} = {
	is_valid => $is_valid,
    };
    return $is_valid;
}


sub is_allocated
{
    undef
}

sub is_in_use
{
    undef
}

# Vérifie les chiffres du numéro de ligne
# Les numéros spéciaux ne matchent pas
sub _check_line
{
    my $num = shift; $num = shift unless ref $num;
    return 0 unless $num =~ RE_STD_LINE;
    my $line = $1;
    return 1 if $line =~ shift;
    return undef;
}

sub is_geographic
{
}

sub is_fixed_line
{
}

sub is_mobile
{
    return _check_digit(@_, qr/^[67]/)
}

sub is_pager
{
    undef
}

sub is_ipphone
{
    return _check_digit(@_, qr/^9/)
}

sub is_isdn
{
    undef
}

sub is_tollfree
{
    #return 1 
    # FIXME Gérer les préfixes
    return 0 unless $_[1] =~ /^08[0-9]{8}$/;
    return undef;
}

sub is_specialrate
{
    # FIXME Gérer les préfixes
    return 0 unless $_[1] =~ /^08[0-9]{8}$/;
    return undef;
}

sub is_adult
{
    return undef;
}

sub is_personal
{
    return undef;
}

sub is_corporate
{
    return undef;
}

sub is_government
{
    return undef;
}

sub is_international
{
    return undef;
}

sub is_network_service
{
    my $num = shift; $num = shift unless ref $num;
    return $num =~ /^1(?:0[0-9]{2}|18[0-9]{3})$/;
}

sub areacode
{
    undef
}

sub areaname
{
    undef
}

sub location
{
    undef
}

sub subscriber
{
    my $num = shift; $num = ref $num ? ${$num} : shift;
    return $1 if $num =~ RE_STD_LINE;
    print "# $1\n";
    return undef;
}

1;
__END__
=head1 NAME

Number::Phone::FR - Phone number information for France (+33)

=head1 DESCRIPTION

This is a subclass of L<Number::Phone> that provide information for phone numbers in France.

=head1 DATA SOURCES

L<http://www.arcep.fr/index.php?id=8992>

=head1 SEE ALSO

L<http://fr.wikipedia.org/wiki/Plan_de_num%C3%A9rotation_t%C3%A9l%C3%A9phonique_en_France>

=head1 SUPPORT

L<http://rt.cpan.org/>

=head1 AUTHOR

Copyright E<copy> 2010 Olivier Mengué

=cut
