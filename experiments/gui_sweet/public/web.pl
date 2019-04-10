#!perl
use warnings;
use 5.028;
use WebPerl qw/js sub1 encode_json/;

# This is the code that WebPerl runs in the browser. It is loaded by index.html.

my $window = js('window');
my $document = js('document');
my $jq = js('jQuery');

sub do_ajax {
	my %args = @_;
	die "must specify a url" unless $args{url};
	$args{fail} ||= sub { $window->alert(shift) };
	$jq->ajax( $args{url}, {
		$args{data} # when given data, default to POST (JSON), otherwise GET
			? ( method=>$args{method}||'POST',
				data=>encode_json($args{data}) )
			: ( method=>$args{method}||'GET' ),
	} )->done( sub1 {
		$args{done}->(shift) if $args{done};
	} )->fail( sub1 {
		my ($jqXHR, $textStatus, $errorThrown) = @_;
		$args{fail}->("AJAX Failed! ($errorThrown)");
	} )->always( sub1 {
		$args{always}->() if $args{always};
	} );
	return;
}

# slightly hacky way to get the access token, but it works fine
my ($token) = $window->{location}{search}=~/\btoken=([a-fA-F0-9]+)\b/;

my $btn = $jq->('<button>', { text=>"Click me!" } );
$btn->click(sub {
	$btn->prop('disabled',1);
	do_ajax( url=>"/example?token=$token",
		data => { string=>"rekcaH lreP rehtonA tsuJ" },
		done => sub { $window->alert("The server says: ".shift->{string}) },
		always => sub { $btn->prop('disabled',0); } );
} );
$btn->appendTo( $jq->('#buttons') );

