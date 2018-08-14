use warnings;
use 5.028;
use Socket;
use Fcntl qw/F_GETFL F_SETFL O_NONBLOCK/;
use IO::Select;
use Data::Dumper;
$Data::Dumper::Useqq=1;

my $port    = 2345;
my $iaddr   = inet_aton("localhost") || die "host not found";
my $paddr   = sockaddr_in($port, $iaddr);

# Note: Emscripten apparently doesn't like NONBLOCK being passed to socket(),
# and I couldn't get setsockopt to work yet - but the following works.
# https://github.com/kripken/emscripten/blob/d08bf13/tests/sockets/test_sockets_echo_client.c#L166
# everything is async - need "our $sock" here so it doesn't go out of scope at end of file
socket(our $sock, PF_INET, SOCK_STREAM, getprotobyname("tcp")) or die "socket: $!";
my $flags = fcntl($sock, F_GETFL, 0) or die "get flags: $!";
fcntl($sock, F_SETFL, $flags | O_NONBLOCK) or die "set flags: $!";
connect $sock, $paddr or !$!{EINPROGRESS} && die "connect: $!";

# so far so good... but probably should just use something like IO::Async instead


