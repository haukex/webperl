#!/usr/bin/env perl
use warnings;
use 5.026;
use FindBin ();
use Path::Class qw/dir file/;

# A quick and dirty script for importing stuff from webperl/master to gh-pages

sub edit (&$$) {
	my ($code,$source,$dest) = @_;
	state $basedir = dir($FindBin::Bin)->parent->parent;
	local $_ = file($source)->absolute($basedir)->slurp(iomode=>'<:raw:encoding(UTF-8)');
	$code->();
	file($dest)->absolute($basedir)->spew(iomode=>'>:raw:encoding(UTF-8)', $_);
}

edit {
	s{ iframe.perleditor\s*\{ [^\}]* border: \s* \K \N* (?=\n) }{1px dotted lightgrey;}xmsg==1 or die;
	s{ <!--(?<x>script\s+src="http.+?iframeResizer.min.js"[^>]+crossorigin[^>]+></script)--> }{<$+{x}>}xmsg==1 or die;
	s{ ^ \s* \K /[/*] (?= \s* iFrameResize ) }{}xmsg==2 or die;
} 'web/democode/demo.html', 'pages/democode/index.html';

edit {
	s{ <!-- [^>]* \K demo.html (?= [^>]* --> ) }{index.html}xmsg==1 or die;
	s{ <!--(?<x>script\s+src="http.+?iframeResizer.contentWindow.min.js"[^>]+crossorigin[^>]+></script)--> }{<$+{x}>}xmsg==1 or die;
} 'web/democode/perleditor.html', 'pages/democode/perleditor.html';

edit {
	s{ <!-- [^>]* \K demo.html (?= [^>]* --> ) }{index.html}xmsg==1 or die;
	s{ <(?<x>script\s+src="[^"]*webperl\.js"\s*></script)> }{<!--$+{x}-->}xmsg==1 or die;
	s{ <!--(?<x>script\s+src="http.+?webperl\.js"[^>]+crossorigin[^>]+></script)--> }{<$+{x}>}xmsg==1 or die;
} 'web/democode/perlrunner.html', 'pages/democode/perlrunner.html';

edit {
} 'web/democode/perleditor.css', 'pages/democode/perleditor.css';

edit {
	my $msg = <<'ENDMSG';
This is essentially a copy of
https://github.com/haukex/webperl/blob/master/web/regex_tester.html
with the following differences:
- webperl.js from CDN
- $RUN_CODE_IN_IFRAME enabled
- URL updated to https://github.com/haukex/webperl/blob/gh-pages/regex.html
(see import_regex_tester.pl)
ENDMSG
	s{ <(?<x>script\s+src="(?:webperl\.js|__WEBPERLURL__)"\s*></scr_*ipt)> }{<!--$+{x}-->}xmsg==2 or die;
	s{ <!--(?<x>script\s+src="http.+?webperl\.js"[^>]+crossorigin[^>]+></scr_*ipt)--> }{<$+{x}>}xmsg==2 or die;
	s{ ^ \s* our \s+ \$RUN_CODE_IN_IFRAME\s*=\s*\K[01](?=\s*;\s*) }{1}xmsg==1 or die;
	s{ https?://github.com/haukex/webperl/blob/\Kmaster/web/regex_tester.html }{gh-pages/regex.html}xmsg==1 or die;
	s{ \#\#\#\#\#\s*-->\n\K }{\n<!-- $msg-->\n}xmsg==1 or die;
} 'web/regex_tester.html', 'pages/regex.html';
