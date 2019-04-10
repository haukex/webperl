#!/usr/bin/env perl
use warnings;
use 5.018;
use Plack::MIME;
use Plack::Builder qw/builder enable mount/;
use Plack::Request ();
use Plack::Response (); # declare compile-time dependency
use Cpanel::JSON::XS qw/decode_json encode_json/;
use DBI ();
use DBD::SQLite (); # declare compile-time dependency
use HTML::Tiny ();

# This is the server-side code.

# note we rely on gui_basic.pl to set the working directory correctly
my $SERV_ROOT = 'web';
my $DB_FILE = 'database.db';

my $dbh = DBI->connect("DBI:SQLite:dbname=$DB_FILE",
	undef, undef, { RaiseError=>1, AutoCommit=>1 });

$dbh->do(q{ CREATE TABLE IF NOT EXISTS FooBar (
	foo VARCHAR(255), bar VARCHAR(255) ) });

# This sends HTML to the browser, but we could also send JSON
# and build the HTML table dynamically in the browser.
my $app_select = sub {
	state $html = HTML::Tiny->new;
	state $sth_select = $dbh->prepare(q{ SELECT rowid,foo,bar FROM FooBar });
	$sth_select->execute;
	my $data = $sth_select->fetchall_arrayref;
	my $out = $html->table(
		[ \'tr',
			[ \'th', 'rowid', 'foo', 'bar' ],
			map { [ \'td', @$_ ] } @$data
		] );
	return [ 200, [ "Content-Type"=>"text/html" ], [ $out ] ];
};

# This is an example of one way to communicate with JSON.
my $app_insert = sub {
	my $req = Plack::Request->new(shift);
	state $sth_insert = $dbh->prepare(q{ INSERT INTO FooBar (foo,bar) VALUES (?,?) });
	my $rv = eval { # catch errors and return as 500 Server Error
		my $content = decode_json( $req->content );
		$sth_insert->execute($content->{foo}, $content->{bar});
		{ ok=>1 }; # return value from eval, sent to client as JSON
	}; my $e = $@||'unknown error';
	my $res = $req->new_response($rv ? 200 : 500);
	$res->content_type($rv ? 'application/json' : 'text/plain');
	$res->body($rv ? encode_json($rv) : 'Server Error: '.$e);
	return $res->finalize;
};

Plack::MIME->add_type(".js"   => "application/javascript");
Plack::MIME->add_type(".data" => "application/octet-stream");
Plack::MIME->add_type(".mem"  => "application/octet-stream");
Plack::MIME->add_type(".wasm" => "application/wasm");

builder {
	enable 'SimpleLogger';
	enable 'Static',
		path => sub { s#\A/\z#/index.html#; /\.(?:html?|js|css|data|mem|wasm|pl)\z/i },
		root => $SERV_ROOT;
	mount '/select' => $app_select;
	mount '/insert' => $app_insert;
}
