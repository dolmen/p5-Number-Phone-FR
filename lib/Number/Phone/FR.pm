use utf8;
use strict;
use warnings;

package Number::Phone::FR;

our $VERSION = '0.01';

use Carp;
use Number::Phone;

use parent 'Number::Phone';


our $Class = __PACKAGE__;



sub country_code() { 33 }

#$Number::Phone::subclasses{country_code()} = __PACKAGE__;

use Scalar::Util 'blessed';

use constant RE_SUBSCRIBER =>
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
    $class = ref $class if ref $class;

    # Select the implementation based on $Number::Phone::FR::Class
    # The $Class will be loaded below when is_valid is called
    $class = $Class;

    croak "No number given to ".__PACKAGE__."->new()\n" unless defined $number;
    croak "Invalid phone number (scalar expected)" if ref $number;

    my $num = $number;
    $num =~ s/[^+0-9]//g;
    return Number::Phone->new("+$1") if $num =~ /^(?:\+|00)((?:[^3]|3[^3]).*)$/;

    return is_valid($number) ? bless(\$num, $class) : undef;
}


sub _load_class
{
    my $p = $Class;
    $p =~ s!::|'!/!g;
    $p .= '.pm';
    #print "$p\n";
    eval ' require $p; 1 ' unless exists $INC{$p};
}

sub is_valid
{
    my ($number) = (@_);
    return 1 if blessed($number) && $number->isa(__PACKAGE__);

    _load_class unless $Class eq __PACKAGE__;
    return $number =~ $Class->RE_FULL;
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
    my $num = shift;
    my $class = ref $num;
    if ($class) {
	$num = ${$num};
    } else {
	$class = $Class;
	$num = shift;
    }
    return 0 unless $num =~ $class->RE_SUBSCRIBER;
    my $line = $1;
    return 1 if $line =~ shift;
    undef
}

sub is_geographic
{
}

sub is_fixed_line
{
    return _check_line(@_, qr/^[12345]/)
}

sub is_mobile
{
    return _check_line(@_, qr/^[67]/)
}

sub is_pager
{
    undef
}

sub is_ipphone
{
    return _check_line(@_, qr/^9/)
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
    undef
}

sub is_specialrate
{
    # FIXME Gérer les préfixes
    return 0 unless $_[1] =~ /^08[0-9]{8}$/;
    1
}

sub is_adult
{
    return 0 unless _check_line(@_, qr/^8/);
    undef
}

sub is_personal
{
    undef
}

sub is_corporate
{
    undef
}

sub is_government
{
    undef
}

sub is_international
{
    my $num = shift; $num = ref $num ? ${$num} : shift;
    undef
}

sub is_network_service
{
    my $num = shift; $num = ref $num ? ${$num} : shift;
    return 1 if $num =~ /^1(?:|[578]|0[0-9]{2}|1(?:[259]|6000|8[0-9]{3}))$/;
    return 0;
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
    my $num = shift;
    my $class = ref $num;
    if ($class) {
	$num = ${$num};
    } else {
	$class = $Class;
	$num = shift;
    }
    return $1 if $num =~ $class->RE_SUBSCRIBER;
    #print "# $1\n";
    undef;
}

my %length_to_format = (
    # 2 => as is
    4 => sub { s/^(..)(..)/$1 $2/ },
    6 => sub { s/^(...)(...)/$1 $2/ },
    10 => sub { s/(\d\d)(?=.)/$1 /g },
    13 => sub {
	       s/^(00)(33)(.)(..)(..)(..)(..)$/+$2 $3 $4 $5 $6 $7/
	    || s/^(....)(.)(..)(..)(..)(..)$/+33 $1 $2 $3 $4 $5 $6/
	  },
    14 => sub { s/^(....)(..)(..)(..)(..)(..)$/$1 $2 $3 $4 $5 $6/ },
    12 => sub { s/^(\+33)(.)(..)(..)(..)(..)$/$1 $2 $3 $4 $5 $6/ },
    16 => sub { s/^(\+33)(....)(.)(..)(..)(..)(..)$/$1 $2 $3 $4 $5 $6 $7/ },
);

sub format
{
    my $num = shift;
    my $class = ref $num;
    if ($class) {
	$num = ${$num};
    } else {
	$class = $Class;
	$num = shift;
    }
    my $l = length $num;
    my $fmt = $length_to_format{$l};
    return defined $fmt
	?   do {
		local $_ = $num;
		$fmt->();
		$_;
	    }
	: $num;
}



1;
__END__
=head1 NAME

Number::Phone::FR - Phone number information for France (+33)

=head1 SYNOPSIS

    use Number::Phone;

=head1 DESCRIPTION

This is a subclass of L<Number::Phone> that provide information for phone numbers in France.

=head1 DATA SOURCES

L<http://www.arcep.fr/index.php?id=8992>

=head1 SEE ALSO

=over 4

=item *

L<http://fr.wikipedia.org/wiki/Plan_de_num%C3%A9rotation_t%C3%A9l%C3%A9phonique_en_France>

=item *

L<Number::Phone>

=back

=head1 SUPPORT

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Number-Phone-FR>

=head1 AUTHOR

Copyright E<copy> 2010-2011 Olivier MenguE<eacute>

=cut
