#!/usr/bin/env perl
use warnings;
use strict;
use FindBin;
use Path::Class qw/dir/;
use HTTP::Tiny;
use File::Copy qw/copy/;
$|++;

# Quick & dirty script to patch P6 into the "web" dir

# Note: To restore webperl.js to the original version:
# $ git checkout web/webperl.js

my $p6url = 'https://perl6.github.io/6pad/gen/eval_code.js';

my $mydir = dir($FindBin::Bin);
my $webdir = $mydir->parent->parent->subdir('web');

print "Patching experimental Perl 6 support into ",$webdir->relative,"...\n";

my $wpfile = $webdir->file('webperl.js');
die "File structure not as I expected" unless -e $wpfile;

my $http = HTTP::Tiny->new();
my $jsfile = $webdir->file('perl6.js');
print "$p6url: ";
my $resp = $http->mirror($p6url, "$jsfile");
print "$resp->{status} $resp->{reason}\n";
die unless $resp->{success};
print "-> mirrored to ",$jsfile->relative,"\n";

my $wp = $wpfile->slurp(iomode=>'<:raw:encoding(UTF-8)');
$wp =~ s{
		^ \N* \bbegin_webperl6_patch\b \N* $
		.*
		^ \N* \bend_webperl6_patch\b \N* $
	}{}msxi;
die "I thought I clobbered the webperl6.js patch, why is there still a reference to Raku?"
	if $wp=~/\bRaku\./;
my $wp6file = $mydir->file('webperl6.js');
my $wp6 = $wp6file->slurp(iomode=>'<:raw:encoding(UTF-8)');
1 while chomp($wp6);
$wpfile->spew(iomode=>'>:raw:encoding(UTF-8)', $wp.$wp6);
print "Patched ",$wp6file->relative," into ",$wpfile->relative,"\n";

for my $f ($mydir->children) {
	next unless $f->basename=~/(?:html?|css)\z/i;
	link_or_copy($f, $webdir);
}


sub link_or_copy {
	my ($src,$dest) = @_;
	die "Not a dir: $dest" unless -d $dest;
	$dest = $dest->file( $src->basename );
	if ( eval { symlink("",""); 1 } ) { # we have symlink support
		if (!-l $dest) {
			$dest->remove or die "$dest: $!" if -e $dest;
			my $targ = $src->relative( $dest->dir );
			symlink($targ,$dest) or die "symlink: $!";
			print "Linked ",$dest->relative," to $targ\n";
		}
		else { print "Link ",$dest->relative," exists\n"; }
	}
	else {
		$dest->remove or die "$dest: $!" if -e $dest;
		copy($src,$dest) or die "copy: $!";
		print "Copied ",$src->relative," to ",$dest->relative,"\n";
	}
}
