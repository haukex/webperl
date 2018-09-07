#!/usr/bin/env perl
use warnings;
use strict;
use FindBin ();

# A quick and dirty script for importing regex_tester.html to pages

my $infn = "$FindBin::Bin/../../web/regex_tester.html";
my $outfn = "$FindBin::Bin/../regex.html";

my $html = do { open my $ifh, '<:encoding(UTF-8)', $infn or die "$infn: $!"; local $/; <$ifh> };

my $msg = <<'ENDMSG';
This is essentially a copy of
https://github.com/haukex/webperl/blob/master/web/regex_tester.html
with the following differences:
- webperl.js from CDN
- $RUN_CODE_IN_IFRAME enabled
- URL updated to https://github.com/haukex/webperl/blob/gh-pages/regex.html
(see import_regex_tester.pl)
ENDMSG

( $html =~ s{ <(?<x>script\s+src="webperl\.js"\s*></script)> }{<!--$+{x}-->}xms )==1 or die;
( $html =~ s{ <!--(?<x>script\s+src="http.+?webperl\.js"[^>]+crossorigin[^>]+></script)--> }{<$+{x}>}xms )==1 or die;
( $html =~ s{ ^ \s* our \s+ \$RUN_CODE_IN_IFRAME\s*=\s*\K0(?=\s*;\s*) }{1}xms )==1 or die;
( $html =~ s{ https?://github.com/haukex/webperl/blob/\Kmaster/web/regex_tester.html }{gh-pages/regex.html}xms )==1 or die;
( $html =~ s{ \#\#\#\#\#\s*-->\n\K }{\n<!-- $msg-->\n}xms )==1 or die;

open my $ofh, '>:encoding(UTF-8)', $outfn or die "$outfn: $!";
print $ofh $html;
close $ofh;
