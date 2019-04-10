#!/usr/bin/env perl
use warnings;
use 5.018;
use FindBin;
use File::Spec::Functions qw/catdir/;
use Plack::Runner ();
use Starman ();
use Browser::Open qw/open_browser/;

# This just serves up gui_basic_app.psgi in the Starman web server.
# You can also say "plackup gui_basic_app.psgi" instead.

BEGIN {
	my $dir = $ENV{PAR_TEMP} ? catdir($ENV{PAR_TEMP},'inc') : $FindBin::Bin;
	chdir $dir or die "chdir $dir: $!";
}

my $SERV_PORT = 5000;
my $THE_APP = 'gui_basic_app.psgi';

# AFAICT, both Plack::Runner->new(@args) and ->parse_options(@argv) set
# options, and these options are shared between "Starman::Server"
# (documented in "starman") and "Plack::Runner" (documented in "plackup").
my @args = (
	server => 'Starman', loader => 'Delayed', env => 'development',
	version_cb => sub { print "Starman $Starman::VERSION\n" } );
my @argv = ( '--listen', "localhost:$SERV_PORT", $THE_APP );
my $runner = Plack::Runner->new(@args);
$runner->parse_options(@argv);
$runner->set_options(argv => \@argv);
die "loader shouldn't be Restarter" if $runner->{loader} eq 'Restarter';

if ($ENV{DOING_PAR_PACKER}) {
	require Plack::Util;
	Plack::Util::load_psgi($THE_APP); # for dependency resolution
	# arrange to have the server shut down in a few moments
	my $procpid = $$;
	my $pid = fork();
	if (!defined $pid) { die "fork failed" }
	elsif ($pid==0) { sleep 5; kill 'INT', $procpid; exit; } # child
	print "====> Please wait a few seconds...\n";
}
else {
	# There's a small chance here that the browser could open before the server
	# starts up. In that case, a reload of the browser window is needed.
	print "Attempting to open in browser: http://localhost:$SERV_PORT/\n";
	open_browser("http://localhost:$SERV_PORT/");
}

$runner->run;
