#!/usr/bin/env perl
use Mojolicious::Lite;
use Mojo::Util qw/md5_sum/;
use FindBin;
use File::Spec::Functions qw/catdir/;
use Browser::Open qw/open_browser/;

# This is the server-side code.

my $SERV_PORT = 3000;

my ($SSLCERTS,$HOMEDIR);
BEGIN {
	$HOMEDIR = $ENV{PAR_TEMP} ? catdir($ENV{PAR_TEMP},'inc') : $FindBin::Bin;
	chdir $HOMEDIR or die "chdir $HOMEDIR: $!";
	# do_pp.pl pulls the default Mojo SSL certs into the archive for us
	$SSLCERTS = $ENV{PAR_TEMP} ? '?cert=./server.crt&key=./server.key' : '';
}

app->static->paths([catdir($HOMEDIR,'public')]);
app->renderer->paths([catdir($HOMEDIR,'templates')]);
app->secrets(['Hello, Perl World!']);
app->types->type(js   => "application/javascript");
app->types->type(data => "application/octet-stream");
app->types->type(mem  => "application/octet-stream");
app->types->type(wasm => "application/wasm");

# Authentication and browser-launching stuff (optional)
my $TOKEN = md5_sum(rand(1e15).time);
hook before_server_start => sub {
	my ($server, $app) = @_;
	my @urls = map {Mojo::URL->new($_)->query(token=>$TOKEN)} @{$server->listen};
	my $url = shift @urls or die "No urls?";
	if ($ENV{DOING_PAR_PACKER}) {
		# arrange to have the server shut down in a few moments
		my $procpid = $$;
		my $pid = fork();
		if (!defined $pid) { die "fork failed" }
		elsif ($pid==0) { sleep 5; kill 'USR1', $procpid; exit; } # child
		print "====> Please wait a few seconds...\n";
		$SIG{USR1} = sub { $server->stop; exit };
	}
	else {
		print "Attempting to open in browser: $url\n";
		open_browser($url);
	}
};
under sub {
	my $c = shift;
	return 1 if ($c->param('token')//'') eq $TOKEN;
	$c->render(text => 'Bad token!', status => 403);
	return undef;
};

get '/' => sub { shift->render } => 'index';

post '/example' => sub {
	my $c = shift;
	my $data = $c->req->json;
	# can do anything here, this is just an example
	$data->{string} = reverse $data->{string};
	$c->render(json => $data);
};

app->start('daemon', '-l', "https://localhost:$SERV_PORT$SSLCERTS");

__DATA__

@@ index.html.ep
% layout 'main', title => 'WebPerl GUI Demo';
<main role="main" class="container">
	<div>
		<h1>WebPerl Advanced GUI Demo</h1>
		<p class="lead">Hello, Perl World!</p>
		<div id="buttons"></div>
	</div>
</main>
