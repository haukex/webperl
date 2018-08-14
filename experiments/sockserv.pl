#!/usr/bin/env perl
use warnings;
use strict;
use Data::Dump;
use IO::Socket;

# $ git clone https://github.com/novnc/websockify
# $ cd websockify
# $ ./run 2345 localhost:2346

my $serv = IO::Socket::INET->new(
	LocalAddr => 'localhost',
	LocalPort => 2346,
	Proto     => 'tcp',
	Listen    => 5,
	Reuse     => 1 ) or die $@;

# really dumb server
print "Listening...\n";
while (my $client = $serv->accept()) {
	print "Got a client...\n";
	print $client "Hello, Perl!\n";
}

