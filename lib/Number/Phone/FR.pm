use utf8;
use strict;
use warnings;

package Number::Phone::FR;

our $VERSION = '0.01';

use Number::Phone;
use parent 'Number::Phone';

use Carp;
use Scalar::Util 'blessed';

my %pkg2impl;

# Select the implementation to use via "use Number::Phone::FR"

sub import
{
    my $class = shift;
    croak "invalid sub-class" unless $class->isa(__PACKAGE__);
    if ($class eq __PACKAGE__) {
        if (@_) {
            foreach my $impl (@_) {
                $class = $impl;
                $class =~ s/^:?(.)/\U$1/;
                substr($class, 0, 0) = __PACKAGE__.'::';
            }

            my $level = 0;
            my $pkg;
            while (($pkg = (caller $level)[0]) =~ /^Number::Phone(?:::|$)/) {
                $level++;
            }
            $pkg2impl{$pkg} = $class;

            # Load the class
            eval "require $class";
            $class->isa(__PACKAGE__) or croak "$class is not a valid class";
        }
    } else {
        #croak "unexpected arguments for import" if @_;
        my $pkg = (caller)[0];
        croak "$class is private" unless $pkg =~ m/^Number::Phone(?:::|$)/;
        $pkg2impl{$pkg} = $class;
    }
}

#END {
#    foreach (sort keys %pkg2impl) {
#        print STDERR "# $_ => $pkg2impl{$_}\n";
#    }
#}


# Select the implementation based on $pkg2impl
sub _get_class
{
    my ($class) = @_;
    return $class if defined $class && $class ne __PACKAGE__;
    my $level = 0;
    my ($pkg, $impl);
    while ($pkg = (caller $level)[0]) {
        $impl = $pkg2impl{$pkg};
        return $impl if defined $impl;
        $level++;
    }
    # Default implementation
    return __PACKAGE__;
}


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




sub country_code() { 33 }

# Number::Phone's implementation of country() does not yet allow
# clean subclassing so we explicitely implement it here
sub country() { 'FR' }


sub new
{
    my $class = shift;
    my $number = shift;
    $class = ref $class if ref $class;

    $class = _get_class($class);

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

    my $class = _get_class();
    return $number =~ $class->RE_FULL;
}


sub is_allocated
{
    undef
}

sub is_in_use
{
    undef
}

sub _num(\@)
{
    my $args = shift;
    my $num = shift @$args;
    my $class = ref $num;
    if ($class) {
	$num = ${$num};
    } else {
	$class = _get_class();
	$num = shift @$args;
    }
    return ($class, $num);
}

# Vérifie les chiffres du numéro de ligne
# Les numéros spéciaux ne matchent pas
sub _check_line
{
    my ($class, $num) = _num(@_);
    my @matches = ($num =~ $class->RE_SUBSCRIBER);
    return 0 unless @matches;
    my $line = (grep { defined } @matches)[0];
    return 1 if $line =~ shift;
    undef
}

sub is_geographic
{
    return _check_line(@_, qr/^[1-5].{8}$/)
}

sub is_fixed_line
{
    return _check_line(@_, qr/^[1-5].{8}$/)
}

sub is_mobile
{
    return _check_line(@_, qr/^[67].{8}$/)
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
    undef
}

sub is_network_service
{
    my ($class, $num) = _num(@_);
    # Les services réseau sont en direct : jamais de préfixe
    ($num =~ /^1(?:|[578]|0[0-9]{2}|1(?:[259]|6000|8[0-9]{3}))$/) ? 1 : 0
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
    my ($class, $num) = _num(@_);
    my @m = ($num =~ $class->RE_SUBSCRIBER);
    return undef unless @m;
    @m = grep { defined } @m;
    $m[0];
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
    my ($class, $num) = _num(@_);
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



package Number::Phone::FR::Simple;

use parent 'Number::Phone::FR';

1;
__END__
=head1 NAME

Number::Phone::FR - Phone number information for France (+33)

=head1 SYNOPSIS

    # Use Number::Phone::FR through Number::Phone
    use Number::Phone;
    my $num = Number::Phone->new('+33158901515');

    # Select a particular implementation
    use Number::Phone::FR 'Full';
    my $num = Number::Phone->new('+33158901515');

    use Number::Phone::FR 'Simple';
    my $num = Number::Phone->new('+33158901515');


    # One-liners
    perl -MNumber::Phone "-Esay Number::Phone->new(q!+33148901515!)->format"
    perl -MNumber::Phone::FR=Full "-Esay Number::Phone->new(q!+33148901515!)->operator"
    perl -MNumber::Phone::FR=Full "-Esay Number::Phone::FR->new(q!3949!)->operator"

=head1 DESCRIPTION

This is a subclass of L<Number::Phone> that provide information for phone numbers in France.

Two implementation are provided:

=over 4

=item *

C<Simple>

=item *

C<Full>: a more complete implementation that does checks based on information from the ARCEP.

=back

=head1 DATA SOURCES

L<http://www.arcep.fr/index.php?id=8992>

The tools for rebuilding the Number-Phone-FR CPAN distribution with updated
data are included in the distribution:

    perl Build.PL
    ./Build update
    ./Build
    ./Build test

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
