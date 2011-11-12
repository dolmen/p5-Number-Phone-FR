use v5.010;
use strict;
use warnings;

package inc::Build::Author;

=head1 NAME

inc::Build::Author - custom build actions for L<Number::Phone::FR>

=head1 SYNOPSIS

See C<Build.PL>.

=head1 DESCRIPTION

This modules provides additional commands for C<Build.PL> to rebuild
L<Number::Phone::FR> from the latest data from ARCEP (telephony market
regulation autority in France).

Ce module fournit des commandes supplE<eacute>mentaires E<agrave>
C<Build.PL> pour reconstruire L<Number::Phone::FR> E<agrave> partir des
donnE<eacute>es les plus rE<eacute>centes de l'ARCEP.

=cut

use feature 'switch';
use Module::Build;
our @ISA;
BEGIN {
    push @ISA, 'Module::Build';
}

sub WOPNUM() { 'wopnum.xls' }

sub new
{
    my $self = $_[0]->SUPER::new(@_[1..$#_]);
    $self->add_to_cleanup(WOPNUM);
    return $self;
}


my %build_requires = (
    'LWP::UserAgent' => '0',
    'HTTP::Date' => '0',
    'Spreadsheet::ParseExcel' => 0,
    'Regexp::Assemble' => 0,
    'Template' => 0,
);

sub ACTION_installdeps
{
    my $self = shift;
    # Merge mainainer build_requires
    foreach my $mod (keys %build_requires) {
	$self->_add_prereq('build_requires', $mod, $build_requires{$mod});
    }

    $self->SUPER::ACTION_installdeps(@_);
}

sub _fetch
{
    my ($self, $url, $file) = @_;
    require LWP::UserAgent;
    require HTTP::Date;
    require File::Copy;
    require File::Spec;

    my $ua = LWP::UserAgent->new;
    $ua->agent($self->dist_name.'/'.$self->dist_name);
    $ua->env_proxy;
    my $rsp = $ua->get($url, ':content_file' => $file);
    die "$file: @{[ $rsp->status_line ]}\n" unless $rsp->is_success;
    my $t = HTTP::Date::str2time($rsp->header('Last-Modified'));
    utime $t, $t, $file;

    my @t = localtime($t);
    my @f = ($file =~ m/\A(.*)\.([^.]*)\z/);
    my $f = sprintf('%s.%04d-%02u-%02u.%s', $f[0], 1900+$t[5], $t[4]+1, $t[3], $f[1]);
    unless (-f $f) {
        File::Copy::syscopy($file, $f);
        print $f, "\n";
    }

    utime $t, $t, $file, $f;
}

=head1 ACTIONS

=head2 fetch

RE<eacute>cupE<egrave>re la derniE<egrave>re version du fichier du
plan de numE<eacute>rotation publiE<eacute> par l'ARCEP:

L<http://www.arcep.fr/fileadmin/wopnum.xls>

=cut

sub ACTION_fetch
{
    my $self = shift;
    $self->_fetch('http://www.arcep.fr/fileadmin/wopnum.xls', WOPNUM);
    return 1;
}


sub _add_op
{
    my ($op_num, $op, $num) = @_;

    die "Le code opérateur devrait être sur 4 caractères ($op)" if length($op) > 4;

    $num =~ s/\A0//;

    $op .= ' ' x (4 - length $op) if length $op < 4;
    if (exists $op_num->{$op}) {
	push @{ $op_num->{$op} }, $num;
    } else {
	$op_num->{$op} = [ $num ];
    }
}

=head2 parse

Lit le fichier L<wopnum.xls> et construit L<Number::Phone::FR:Full>.

=cut

sub ACTION_parse
{
    my $self = shift;
    -f WOPNUM or $self->SUPER::depends_on('fetch');
    require Spreadsheet::ParseExcel;
    require Regexp::Assemble::Compressed;
    require Template;

    my $re_0 = Regexp::Assemble::Compressed->new(chomp => 0);
    my $re_full = Regexp::Assemble::Compressed->new(chomp => 0);
    my $re_network = Regexp::Assemble::Compressed->new(chomp => 0);
    $re_network->add('1[578]', '11[259]', '116000');
    my $re_pfx = Regexp::Assemble::Compressed->new(chomp => 0);
    $re_pfx->add('\+33', '0033', '(?:3651)?0');
    my $op_num = {};

    my $wopnum_time = (stat WOPNUM)[9];

    my $parser = Spreadsheet::ParseExcel->new;
    my $worksheet = $parser->parse(WOPNUM)->worksheet(0);
    my ($min_row, $max_row) = $worksheet->row_range;
    my ($col0, undef) = $worksheet->col_range;
    print "$max_row lignes.\n";
    for my $row ($min_row+1..$max_row) {
        given ($worksheet->get_cell($row, $col0)->value) {
            when (/\A0/) {
                my $num_re = substr($_, 1).('[0-9]'x(10-length($_)));
                $re_0->add($num_re);
                _add_op($op_num,
                        $worksheet->get_cell($row, $col0+2)->value,
                        $num_re);
            }
            when (/\A(?:[2-9]|16[0-9]{2})\z/) {
                $re_pfx->add("(?:3651)?$_");
            }
            when (/\A3...\z/) {
                $re_full->add($_);
                _add_op($op_num,
                        $worksheet->get_cell($row, $col0+2)->value,
                        $_.('_'x5));
            }
	    when (/\A1/) { $re_network->add($_); }
        }
    }

    my $re_all = Regexp::Assemble::Compressed->new;
    $re_all->add("$re_network|$re_full|$re_pfx(?:$re_0)");
    #$re_all->add($re_network, $re_full, "$re_pfx(?:$re_0)");
    #$re_all->add($re_network);
    #$re_all->add($re_full);
    #$re_all->add("$re_pfx$re_0");
    #eval 'qr/'.$re_network->as_string.'/;1' or die $@;
    #eval 'qr/'.$re_full->as_string.'/;1' or die $@;
    eval 'qr/'.$re_all->as_string.'/;1' or die $@;

    # Compte le nombre de blocs de numéro pour chaque opérateur
    my %blocks_count = map { ($_ => scalar @{$op_num->{$_}}) } keys %$op_num;
    require JSON;
    say JSON->new->encode(\%blocks_count);
    # Trie les opérateurs par ordre décroissant du nombre de blocks gérés
    my @ops = sort { $blocks_count{$b} <=> $blocks_count{$a} || $a cmp $b } keys %blocks_count;
    my $re_ops = Regexp::Assemble::Compressed->new(chomp => 0);
    my $n = 0;
    foreach my $op (@ops) {
	$n += 4;
	my $suffix = ".{$n}";
	foreach my $num (sort @{$op_num->{$op}}) {
	    $re_ops->add($num . $suffix);
	}
    }
    $re_ops = $re_ops->as_string;
    # Supprime "(?:"...")" redondant avec "("...")" que l'on ajoute après
    $re_ops =~ s/^\(\?:// && $re_ops =~ s/\)$//;


    # Nettoyage du résultat boggué de Regexp::Assemble :
    #  remplace "\d" par "[0-9]" (car pas équivalent dans le monde Unicode)
    ($re_0, $re_full, $re_network, $re_pfx, $re_ops, $re_all) = map {
            my $re = ref $_ ? $_->as_string : $_;
	    $re =~ s/\\d/[0-9]/g;
	    $re
	} ($re_0, $re_full, $re_network, $re_pfx, $re_ops, $re_all);

    my $re_subscriber = "($re_full)|$re_pfx($re_0)";

    use lib 'lib';
    require Number::Phone::FR;
    my $version = Number::Phone::FR->VERSION().POSIX::strftime('%2y%3j', localtime($wopnum_time));

    my %vars = (
	VERSION => $version,
        RE_0 => $re_0,
        RE_FULL => $re_all,
        RE_PFX => $re_pfx,
        RE_SUBSCRIBER => $re_subscriber,
        RE_OPERATOR => $re_ops,
        STR_OPERATORS => join('', @ops),
    );

    my $tt2 = Template->new(
    );
    print "Creating Number::Phone::FR::Full...\n";
    $tt2->process('inc/Build/Number-Phone-FR-Full.tt2',
                  \%vars,
                  "lib/Number/Phone/FR/Full.pm",
                  binmode => ':utf8');

    print "Checking source code validity...\n";
    my $exit_status = system $^X $^X, qw/-Ilib -MNumber::Phone::FR=Full -e1/;
    ($exit_status >> 8 == 0) or die "Erreur de validation du source genere: $exit_status\n";
    if ($version ne $self->dist_version) {
	# Force a "./Build" deprecation (redo "perl Build.PL")
	# as the distribution must be rebuilt
        unlink $_ for grep { -e $_ } qw(Build Build.bat Build.COM build.com BUILD.COM);
        print 'Version updated ', $self->dist_version, " => $version\n",
              "Build script removed. Redo 'perl Build.PL'.\n";
    }
}

=head2 update

C<fetch> + C<parse>

Met E<agrave> les donnE<eacute>es de l'ARCEP et reconstruit
L<Number::Phone::FR>.

=cut

sub ACTION_update
{
    my $self = shift;
    $self->SUPER::depends_on(qw'fetch parse');
}

sub ACTION_tag
{
    my $self = shift;
    print 'git tag -a -m "CPAN release '.$self->dist_version.'" release-'.$self->dist_version."\n";
    print "git push github --tags\n";
}

1;
__END__

=head1 SEE ALSO

=over 4

=item *

L<Number::Phone::FR>

=item *

L<http://www.arcep.fr/>

=back

=head1 AUTHOR

Olivier MenguE<eacute>, C<<<dolmen@cpan.org>>>

