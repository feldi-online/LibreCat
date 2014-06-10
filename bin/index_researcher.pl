#!/usr/local/bin/perl

use lib qw(/srv/www/sbcat/lib /srv/www/sbcat/lib/extension /srv/www/sbcat/lib/default /home/bup/perl5/lib/perl5);
use lib qw(/srv/www/app-catalog/lib);
use Catmandu::Sane;
use Catmandu -all;
use Getopt::Std;
use Data::Dumper;

getopts('u:m:i:');
our $opt_u;
# m for multiple indices
our $opt_m;
our $opt_i;

my $home = "/srv/www/app-catalog/";#$ENV{BACKEND};

my $index_name = "backend";
if ( $opt_m ) {
	if ($opt_m eq "backend1" || $opt_m eq "backend2" ) {
		$index_name = $opt_m;
	} else {
		die "$opt_m is not an valid option";
	}
}

Catmandu->load(':up');
my $conf = Catmandu->config;
my $mongoBag = Catmandu->store('authority')->bag('admin');
my $bag = Catmandu->store('search')->bag('researcher');

my $pre_fixer = Catmandu::Fix->new(fixes => [
			'add_num_of_publs()',
			'copy_field("_id","oId")',
		]);

sub add_to_index {
	my $rec = shift;

	$pre_fixer->fix($rec);
  	$bag->add($rec);
}


if ($opt_i){
	my $researcher = $mongoBag->get($opt_i);
	add_to_index($researcher) if $researcher;
}
else { # initial indexing

	my $allResearchers = $mongoBag->to_array;
	foreach(@$allResearchers){
		add_to_index($_);
		#print Dumper $_;
	}
}

$bag->commit;

=head1 SYNOPSIS

Script for indexing project data

=head2 Initial indexing

perl index_project.pl

# fetches all data from project mongodb and pushes it into the search store

=head2 Update process

perl index_project.pl -u 'ID'

# fetches one record with the id 'ID' and pushes it into the search storej or deletes it if 'ID' not found anymore

=head1 VERSION

0.02, Oct. 2012

=cut
