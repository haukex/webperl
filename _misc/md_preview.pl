#!/usr/bin/env perl
use warnings;
use strict;
use open qw/:std :utf8/;
use FindBin ();

# Generate a preview of the site using `markdown`
# (I use this mostly just to check for any Markdown syntax mistakes)
#TODO Later: Use a markdown processor that handles GitHub's markdown enhancements?

my $dir = $FindBin::Bin.'/..';
opendir my $dh, $dir or die $!;
my @files = grep { ! -d } map { "$dir/$_" } sort grep {/\.md\z/i} readdir $dh;
close $dh;

print <<'ENDHTML';
<!doctype html>
<html lang="en-us">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>WebPerl Site Preview</title>
</head>
<body>
ENDHTML

print "<hr/>\n";
for my $f (@files) {
	system('markdown',$f)==0
		or die "markdown failed, \$?=$?";
	print "<hr/>\n";
}

print <<'ENDHTML';
</body>
</html>
ENDHTML
