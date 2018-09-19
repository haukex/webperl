#!/usr/bin/env perl
use warnings;
use strict;
use feature 'state';
use FindBin;
use File::Find qw/find/;
use File::Path qw/make_path/;
use File::Spec::Functions qw/catdir catfile abs2rel rel2abs splitdir/;
use File::Basename qw/fileparse/;
use ExtUtils::MakeMaker qw/prompt/;
require File::Spec::Unix;

# A quick and dirty script for caching external resources locally

my $USE_WGET; BEGIN { $USE_WGET=0 }
use if !$USE_WGET, 'HTTP::Tiny';

my $DEBUG; BEGIN { $DEBUG=0 }
use if $DEBUG, 'Data::Dump';

my $CACHEDIR = catdir($FindBin::Bin,'web','cache');
make_path $CACHEDIR;

my @findin = @ARGV ? map {rel2abs($_)} @ARGV : catdir($FindBin::Bin,'web');

my @htmlfiles;
find({ follow=>1,
	wanted=>sub {
		-f && /\.html?\z/i && push @htmlfiles, $File::Find::name;
	} },
	@findin );

# yes, I know, parsing HTML with regexes, boo, hiss ;-)
# http://www.perlmonks.org/?node_id=1201438
my $regex = qr{
		< (?:script|link) [^>]+ (?:src|href) \s* = \s*
			(?<q> ["'] )
			(?= https?:// (?! localhost\b | 127\.0\.0\.1\b ) )
			\K
			(?: (?! \k{q} | > ) . )*
			(?= \k{q} )
	}msx;

for my $fn (@htmlfiles) {
	my $html = do { open my $fh, '<:encoding(UTF-8)', $fn or die "$fn: $!"; local $/; <$fh> };
	my $count = $html =~ s/$regex/fetch_resource($fn,$&)/eg;
	warn+($count||0)." replacements in $fn\n";
	next unless $count;
	next unless prompt("Overwrite $fn? [Yn]","y")=~/^\s*y/i;
	open my $ofh, '>:encoding(UTF-8)', $fn or die "$fn: $!";
	print $ofh $html;
	close $ofh;
}

sub fetch_resource {
	my ($file,$url) = @_;
	state $http = $USE_WGET ? undef : HTTP::Tiny->new;
	state %cached;
	my ($cachefn) = $url =~ m{/([^/]+)\z} or die $url;
	$cachefn = catfile($CACHEDIR, $cachefn);
	print STDERR "$url: ";
	if (not $cached{$url}) {
		if ($USE_WGET) {
			# Note: wget's timestamping (-N) doesn't work with -O
			system('wget','-nv','-O'.$cachefn,$url)==0 or die "wget failed\n";
		}
		else {
			my $resp = $http->mirror($url, $cachefn);
			die "$resp->{status} $resp->{reason}\n" unless $resp->{success};
			warn "$resp->{status} $resp->{reason}\n";
		}
		$cached{$url} = $cachefn;
	}
	else { print STDERR "already fetched\n"; }
	my (undef,$path) = fileparse($file);
	my $newurl = File::Spec::Unix->catdir(splitdir( abs2rel($cachefn,$path) ));
	$DEBUG and dd($file, $url, $cachefn, $newurl);
	return $newurl;
}

