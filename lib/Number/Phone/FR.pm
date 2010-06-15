package Number::Phone::FR;

use strict;
use warnings;

our $VERSION = '0.01';

use base 'Number::Phone';
$Number::Phone::subclasses{country_code()} = __PACKAGE__;

use Scalar::Util 'blessed';

{
sub RE() {
  qr{
  ^ (?:
    1 (?:
        0[0-9]{2}  # Op�rateur
      | 5          # SAMU
      | 7          # Police/gendarmerie
      | 8          # Pompiers
      | 1 (?:
            2      # Num�ro d'urgence europ�en
          | 5      # Urgences sociales
	  | [68][0-9]{3}  # 116000 : Enfance maltrait�e
                          # 118XYZ : Renseignements t�l�phoniques
	  | 9      # Enfance maltrait�e
	  )
      )
  | 3([0-9]{3})
  |
     ( \+33        # Pr�fixe international
     | [04789]     # Transporteur par d�faut (0) ou S�lection du transporteur
     | 16 [0-9]{2} # S�lection du transporteur
     )
     [1-9]{9}      # Num�ro de ligne
  ) $
  }xs
}

}

sub country_code() { 33 }



sub new
{
    my $class = shift;
    my $number = shift;
    croak "No number given to ".__PACKAGE__."->new()\n" unless defined $number;
    croak "Invalid phone number (scalar expected)" if ref $number;
    my $num = $number;
    $num =~ s/[^+0-9]//g;
    return Number::Phone->new("+$1") if $num =~ /^(?:\+|00)((?:[^3]|3[^3]).*)$/;

    return is_valid($number) ? bless(\$number, $class)
                             : undef;
}


my 


sub _parse
{
    my $number = (@_);
    $number =~ s/[^0-9+]//g;
    if ($number !~ RE) return undef;
}

sub is_valid
{
    my $number = (@_);
    return 1 if(blessed($number) && $number->isa(__PACKAGE__));
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

Copyright E<copy> 2010 Olivier Mengu�

=cut
