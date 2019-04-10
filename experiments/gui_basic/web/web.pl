#!perl
use warnings;
use 5.028;
use WebPerl qw/js js_new sub1 encode_json/;

# This is the code that WebPerl runs in the browser. It is loaded by index.html.

sub do_xhr {
	my %args = @_;
	die "must specify a url" unless $args{url};
	$args{fail} ||= sub { js('window')->alert(shift) };
	my $xhr = js_new('XMLHttpRequest');
	$xhr->addEventListener("error", sub1 {
			$args{fail}->("XHR Error on $args{url}: ".(shift->{textContent}||"unknown"));
			return;
		});
	$xhr->addEventListener("load", sub1 {
			if ($xhr->{status}==200) {
				$args{done}->($xhr->{response}) if $args{done};
			}
			else {
				$args{fail}->("XHR Error on $args{url}: ".$xhr->{status}." ".$xhr->{statusText});
			}
			return;
		});
	$xhr->addEventListener("loadend", sub1 {
			$args{always}->() if $args{always};
			return;
		});
	# when given data, default to POST (JSON), otherwise GET
	if ($args{data}) {
		$xhr->open($args{method}||'POST', $args{url});
		$xhr->setRequestHeader('Content-Type', 'application/json');
		$xhr->send(encode_json($args{data}));
	}
	else {
		$xhr->open($args{method}||'GET', $args{url});
		$xhr->send();
	}
	return;
}

my $document = js('document');

my $btn_reload = $document->getElementById('reload_data');
sub do_reload {
	state $dtbl = $document->getElementById('datatable');
	$btn_reload->{disabled} = 1;
	do_xhr(url => 'select',
		done   => sub { $dtbl->{innerHTML} = shift; },
		always => sub { $btn_reload->{disabled} = 0; } );
	return;
}
$btn_reload->addEventListener("click", \&do_reload);

my $btn_insert = $document->getElementById('do_insert');
sub do_insert {
	state $txt_foo = $document->getElementById('input_foo');
	state $txt_bar = $document->getElementById('input_bar');
	$btn_insert->{disabled} = 1;
	do_xhr(url => 'insert',
		data => { foo=>$txt_foo->{value}, bar=>$txt_bar->{value} },
		always => sub { $btn_insert->{disabled} = 0; do_reload; } );
	return;
}
$btn_insert->addEventListener("click", \&do_insert);

do_reload; # initial load

