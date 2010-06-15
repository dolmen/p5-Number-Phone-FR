package inc::Build::Author;

use strict;
use v5.10.0;
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

sub _fetch
{
    my ($self, $url, $file) = @_;
    require LWP::UserAgent;
    require HTTP::Date;

    my $ua = LWP::UserAgent->new;
    $ua->agent($self->dist_name.'/'.$self->dist_name);
    $ua->env_proxy;
    my $rsp = $ua->get($url, ':content_file' => $file);
    die "$file: $rsp->status_line\n" unless $rsp->is_success;
    my $t = HTTP::Date::str2time($rsp->header('Last-Modified'));
    utime $t, $t, $file;
}

sub ACTION_fetch
{
    my $self = shift;
    $self->_fetch('http://www.arcep.fr/fileadmin/wopnum.xls', WOPNUM);
    return 1;
}

sub ACTION_parse
{
    my $self = shift;
    -f WOPNUM or $self->SUPER::depends_on('fetch');
    require Spreadsheet::ParseExcel;
    require Regexp::Assemble;
    require Template;

    my $re_0 = Regexp::Assemble->new;
    my $re_full = Regexp::Assemble->new;
    $re_full->add('1[578]', '11[259]', '116000');
    my $re_pfx = Regexp::Assemble->new;
    $re_pfx->add('\+33', '0');

    my $parser = Spreadsheet::ParseExcel->new;
    my $worksheet = $parser->parse(WOPNUM)->worksheet(0);
    my ($min_row, $max_row) = $worksheet->row_range;
    my ($col0, undef) = $worksheet->col_range;
    print "$max_row lignes.\n";
    for my $row ($min_row+1..$max_row) {
        given($worksheet->get_cell($row, $col0)->value) {
	    when (/^0/) { $re_0->add(substr($_, 1).('[0-9]'x(10-length($_)))); }
	    when (/^(?:[2-9]|16[0-9]{2})$/) { $re_pfx->add($_); }
	    when (/^[31]/) { $re_full->add($_); }
        }
    }
    print $re_0->as_string, "\n";
    print $re_full->as_string, "\n";
    print $re_pfx->as_string, "\n";

    my %vars = { RE_0 => "$re_0", RE_FULL => "$re_full", RE_PFX => "$re_pfx" };

    my $tt2 = Template->new(
    );
    $tt2->process('inc/Build/Number-Phone-FR-Full.tt2', \%vars, "lib/Number/Phone/FR/Full.pm");
}


1;
