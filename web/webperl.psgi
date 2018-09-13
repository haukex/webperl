#!/usr/bin/env perl
use warnings;
use strict;
use FindBin;
use Plack::MIME;
use Plack::Builder qw/builder enable mount/;
use Plack::App::Directory ();
use Cpanel::JSON::XS qw/decode_json encode_json/;
require Plack::Middleware::CrossOrigin;

# Demo Plack server for WebPerl
# run me with "plackup webperl.psgi"

# in an Apache .htaccess file, one could say:
#AddType application/javascript .js
#AddType application/octet-stream .data .mem
#AddType application/wasm .wasm

Plack::MIME->add_type(".js"   => "application/javascript");
Plack::MIME->add_type(".data" => "application/octet-stream");
Plack::MIME->add_type(".mem"  => "application/octet-stream");
Plack::MIME->add_type(".wasm" => "application/wasm");

my $SERV_ROOT = $FindBin::Bin;

my $app_ajaxtest = sub {
	my $req = Plack::Request->new(shift);
	my $rv = eval {
		my $content = decode_json( $req->content );
		
		# We can do anything we like here, like e.g. call Perl subs,
		# read/write files on the server, etc. - for this demo we're
		# just going to munge some data from the request.
		$content->{hello} .= "The server says hello!\n";
		
		$content; # return value from eval (must be a true value)
	}; my $e = $@||'unknown error';
	my $res = $req->new_response($rv ? 200 : 500);
	$res->content_type($rv ? 'application/json' : 'text/plain');
	$res->body($rv ? encode_json($rv) : 'Server Error: '.$e);
	return $res->finalize;
};

builder {
	enable 'SimpleLogger';
	enable 'CrossOrigin', origins => '*';
	enable 'Static',
		path => qr/\.(?:html?|js|css|data|mem|wasm|pl)\z/i,
		root => $SERV_ROOT;
	mount '/' => Plack::App::Directory->new({root=>$SERV_ROOT})->to_app;
	mount '/ajaxtest' => $app_ajaxtest;
}

