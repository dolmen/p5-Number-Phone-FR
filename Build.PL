#!/usr/bin/env perl
use utf8;   # vim:set ts=4 sw=4 sts=4:

use strict;
use warnings;

use Module::Build;

my $build_module = 'Module::Build';

# Use the extended build only in author environment
if (-d '.git') {
	print "Building in author mode\n";
	$build_module = 'inc::Build::Author';
    require inc::Build::Author;
}

my $builder = $build_module->new(
	module_name          => 'Number::Phone::FR',
	dist_author          => 'Olivier Mengué <dolmen@cpan.org>',
    dist_abstract        => 'Phone number information for France (+33)',
	license              => 'perl',
	meta_add             => {
		resources => {
			homepage => 'https://github.com/dolmen/Number-Phone-FR-perl',
			repository => 'https://github.com/dolmen/Number-Phone-FR-perl.git',
			bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Number-Phone-FR',
		},
	},
	requires => {
		'Number::Phone' => '1.7004',
		'parent' => '0.221',
	},
	configure_requires => {
		'Module::Build' => '0.36',
	},
	build_requires => {
		'Test::More' => '0.94',
	},
);

$builder->create_build_script;

