#!/usr/bin/env perl
use warnings;
use 5.0.26;
use FindBin;
use Plack::MIME;
use Plack::Builder qw/builder enable mount/;
use Plack::App::Directory ();

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

builder {
	enable 'SimpleLogger';
	enable 'Static',
		path => qr/\.(?:html?|js|css|data|mem|wasm|pl)\z/i,
		root => $SERV_ROOT;
	Plack::App::Directory->new({root=>$SERV_ROOT})->to_app;
}

