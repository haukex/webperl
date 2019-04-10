#!/usr/bin/env perl
use warnings;
use strict;
use File::Basename qw/fileparse/;
use File::Spec::Functions qw/catfile/;
use File::Temp qw/tempfile/;

# this attempts to locate Mojo's default server.crt/server.key files
chomp( my $dir = `perldoc -l Mojo::IOLoop::Server` );
die "perldoc -l failed, \$?=$?" if $? || !-e $dir;
(undef, $dir) = fileparse($dir);

# set up a file for pp's -A switch
my ($tfh, $tfn) = tempfile(UNLINK=>1);
print {$tfh} catfile($dir,'resources','server.crt'),";server.crt\n";
print {$tfh} catfile($dir,'resources','server.key'),";server.key\n";
close $tfh;

my @args = (qw/ -a public -a templates -A /, $tfn);

local $ENV{DOING_PAR_PACKER}=1;
system(qw/ pp -o gui_sweet -z 9 -x /,@args,'gui_sweet.pl')==0
	or die "pp failed, \$?=$?";
