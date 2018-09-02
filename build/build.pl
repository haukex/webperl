#!/usr/bin/env perl
use warnings;
use 5.026;

=head1 SYNOPSIS

Build script for WebPerl; see L<http://webperl.zero-g.net>.

 build.pl [OPTIONS]
 OPTIONS:
   --showconf     - Show configuration
   --reconfig     - Force regeneration config.sh
   --forceext     - Force fetching of extensions
   --applyconfig  - Apply any changes to config.sh (sh Configure -S)
   --remakeout    - Force rebuild of the output directory
   --forceemperl  - Force rebuild of emperl.js
   --dist=FN      - Create a distro file "FN.zip"
   --verbose      - Be more verbose

=head1 Author, Copyright, and License

B<< WebPerl - L<http://webperl.zero-g.net> >>

Copyright (c) 2018 Hauke Daempfling (haukex@zero-g.net)
at the Leibniz Institute of Freshwater Ecology and Inland Fisheries (IGB),
Berlin, Germany, L<http://www.igb-berlin.de>

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself: either the GNU General Public
License as published by the Free Software Foundation (either version 1,
or, at your option, any later version), or the "Artistic License" which
comes with Perl 5.

This program is distributed in the hope that it will be useful, but
B<WITHOUT ANY WARRANTY>; without even the implied warranty of
B<MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE>.
See the licenses for details.

You should have received a copy of the licenses along with this program.
If not, see L<http://perldoc.perl.org/index-licence.html>.

=cut

use Getopt::Long qw/ HelpMessage :config posix_default gnu_compat bundling auto_version auto_help /;
use Hash::Util qw/lock_hash/;
use Data::Dump;
use Path::Class qw/file dir/;
use IPC::Run3::Shell {show_cmd=>1}, qw/ :FATAL :run git make emmake /;
use ExtUtils::MakeMaker qw/prompt/;
use FindBin ();
use Carp;
use Cwd qw/getcwd abs_path/;
use URI ();
use IO::Socket::SSL 1.56 (); # for HTTP::Tiny
use Net::SSLeay 1.49 ();     # for HTTP::Tiny
use HTTP::Tiny ();
use Cpanel::JSON::XS qw/decode_json/;
use File::Temp qw/tempdir/;
use Archive::Tar ();
use File::Copy::Recursive qw/dirmove/;
use File::Replace qw/replace3/;
use Pod::Strip ();
use Archive::Zip qw/AZ_OK/;

GetOptions(\my %opts,'showconf','reconfig','forceext','applyconfig',
	'forceemperl','remakeout','dist=s','verbose')
	or HelpMessage(-exitval=>255);

# check that emperl_config.sh has been run
die "Please run '. emperl_config.sh' to set up the environment variables.\n"
	unless $ENV{EMPERL_PERLVER};
die "Please edit 'emperl_config.sh' to point it to the correct location of 'emsdk_env.sh'\n"
	unless $ENV{EMSCRIPTEN} && -d $ENV{EMSCRIPTEN} && $ENV{EMSDK} && -d $ENV{EMSDK};

# copy over config variables from environment
my %C = map {$_=>$ENV{'EMPERL_'.$_}} qw/ EXTENSIONS
	HOSTPERLDIR OUTPUTDIR DOWNLOADDIR PERLSRCDIR
	PREFIX PERLVER
	PERL_REPO PERL_BRANCH CLOBBER_BRANCH /;
$C{$_} = dir($C{$_}) for qw/ HOSTPERLDIR OUTPUTDIR DOWNLOADDIR PERLSRCDIR /;
$C{EXTENSIONS} = [ split ' ', $C{EXTENSIONS} ];
lock_hash %C;  # typo prevention
dd \%C if $opts{showconf};

my $VERBOSE = $opts{verbose}?1:0;
my $needs_reconfig = !!$opts{reconfig};

# ##### ##### ##### Step: Patch Emscripten ##### ##### #####

{
	my $d = pushd( dir($ENV{EMSCRIPTEN}, 'src') );
	# Emscripten's fork() (and system()) stubs return EAGAIN, meaning "Resource temporarily unavailable".
	# So perl will wait 5 seconds and try again, which is not helpful to us, since Emscripten doesn't support those functions at all.
	# This patch fixes that on the Emscripten side, so the stubs return ENOTSUP.
	#TODO Later: we should probably verify the Emscripten version too, and in the future we may need different patches for different versions
	if ( try_patch_file( file($FindBin::Bin,'emscripten_1.38.10_eagain.patch') ) ) {
		say STDERR "# Emscripten was newly patched, forcing a rebuild";
		# not sure if the following is needed, but playing it safe:
		run 'emcc', '--clear-cache';  # force Emscripten to rebuild libs (takes a bit of time)
		$needs_reconfig=1;
	}
}

# ##### ##### ##### Step: Check out Perl sources ##### ##### #####

if (!-e $C{PERLSRCDIR}) {
	say STDERR "# $C{PERLSRCDIR} doesn't exist, checking out";
	my $d = pushd($C{PERLSRCDIR}->parent);
	git 'clone', '--branch', $C{PERL_BRANCH}, $C{PERL_REPO}, $C{PERLSRCDIR}->basename;
	die "something went wrong with git clone" unless -d $C{PERLSRCDIR};
	$needs_reconfig=1;
}
GITSTUFF: {
	my $d = pushd($C{PERLSRCDIR});
	eval {
		git 'fetch';
	1 } or do {
		warn $@;
		# Maybe we don't have network connectivity
		if (prompt("Whoops, 'git fetch' failed. Continue anyway? [Yn]","y")=~/^\s*y/i)
			{ last GITSTUFF }
		else { die "git fetch failed, aborting" }
	};
	my $myhead = git 'log', '-1', '--format=%h', $C{PERL_BRANCH}, {chomp=>1,show_cmd=>$VERBOSE};
	my $remhead = git 'log', '-1', '--format=%h', 'origin/'.$C{PERL_BRANCH}, {chomp=>1,show_cmd=>$VERBOSE};
	say STDERR "# Local branch is at $myhead, remote is $remhead";
	if ($myhead ne $remhead) { #TODO Later: This should also check which git commit is newer!
		if (prompt("Would you like to update? WARNING: Unsaved local changes may be lost! [Yn]","y")=~/^\s*y/i) {
			eval {
				if ($C{CLOBBER_BRANCH}) {
					say "WARNING: I am about to clobber the branch $C{PERL_BRANCH} in $C{PERLSRCDIR}!";
					verify_perlsrc_modify(1);
					git 'checkout', '-q', $C{PERLVER};
					git 'branch', '-D', $C{PERL_BRANCH};
					git 'branch', $C{PERL_BRANCH}, 'origin/'.$C{PERL_BRANCH};
					git 'checkout', $C{PERL_BRANCH};
				}
				else {
					git 'checkout', $C{PERL_BRANCH};
					git 'pull';
				}
			1 } or die "$@\nA git step failed - perhaps you have uncommited changes in $C{PERLSRCDIR}?\n";
			$needs_reconfig=1;
		}
	}
	my $tags = git 'tag', '--list', {show_cmd=>$VERBOSE};
	die "could not find tag '$C{PERLVER}', is this the right repository?"
		unless $tags=~/^\Q$C{PERLVER}\E$/m;
	my $branches = git 'branch', '--list', {show_cmd=>$VERBOSE};
	die "could not find branch '$C{PERL_BRANCH}', is this the right repository?"
		unless $branches=~/^\*?\s*\b\Q$C{PERL_BRANCH}\E$/m;
	say STDERR "# Found tag '$C{PERLVER}' and branch '$C{PERL_BRANCH}' in $C{PERLSRCDIR}";
}
sub verify_perlsrc_modify {
	my $force = shift;
	state $already_prompted = 0;
	$already_prompted=0 if $force;
	return if $already_prompted;
	if (prompt("WARNING: You will lose any changes to the working copy and index in $C{PERLSRCDIR}!\n"
		."    Continue? [yN]","n")!~/^\s*y/i) {
		say STDERR "Aborting.";
		exit 1;
	} else { $already_prompted = 1 }
}

# ##### ##### ##### Step: Check/build hostperl ##### ##### #####

sub verify_hostperl {
	my $miniperl = $C{HOSTPERLDIR}->file('miniperl');
	return 0 unless -e $miniperl;
	my $miniperlver = run $miniperl, '-e', 'print $^V', {show_cmd=>$VERBOSE};
	say STDERR "# Detected hostperl / miniperl '$miniperlver' (need '$C{PERLVER}')";
	my $perl = $C{HOSTPERLDIR}->file('perl');
	if (-e $perl) { # currently just an optional check
		my $perlver = run $perl, '-e', 'print $^V', {show_cmd=>$VERBOSE};
		say STDERR "# Detected hostperl / perl '$perlver'";
		die "miniperl ('$miniperlver') / perl ('$perlver') version mismatch"
			unless $miniperlver eq $perlver;
	}
	return $miniperlver eq $C{PERLVER};
}
if (!verify_hostperl()) {
	say STDERR "# A rebuild of hostperl is required";
	$C{HOSTPERLDIR}->rmtree(1);
	$C{HOSTPERLDIR}->mkpath(1);
	verify_perlsrc_modify();
	{
		my $d = pushd($C{PERLSRCDIR});
		git 'checkout', '-qf', $C{PERLVER};
		git 'clean', '-dxf';
	}
	{
		my $d = pushd($C{HOSTPERLDIR});
		run {stdin=>\undef}, 'sh', file($C{PERLSRCDIR},'Configure'),
			'-des', '-Dusedevel', '-Dmksymlinks';
		make 'miniperl';
		make 'minitest';
		make 'generate_uudmap';
		#TODO Later: do we really need the following full perl build as well? (good for testing?)
		# if we do, make the test for "perl" in verify_hostperl required, not optional
		make 'perl';
		make 'test';
	}
	$needs_reconfig=1;
	die "something went wrong with hostperl" unless verify_hostperl();
}

# ##### ##### ##### Step: Prep "emperl" sources (for next steps) ##### ##### #####

my $config_sh = $C{PERLSRCDIR}->file('config.sh');
if (!-e $config_sh) {
	say STDERR "# config.sh NOT found, forcing a reconfig";
	$needs_reconfig=1 }
else { say STDERR "# config.sh found" }

if (-e $config_sh) {
	my $our_mtime = file($FindBin::Bin, 'emperl_config.sh')->stat->mtime;
	my $perl_mtime = $config_sh->stat->mtime;
	if ($perl_mtime>$our_mtime)
		{ say STDERR "# config.sh is newer than emperl_config.sh" }
	else {
		say STDERR "# config.sh is OLDER than emperl_config.sh, forcing a reconfig";
		$needs_reconfig=1 }
}

if ($needs_reconfig) {
	exit 1 if prompt("Looks like we need a full reconfig. Continue? [Yn]","y")!~/^\s*y/i;
	verify_perlsrc_modify();
	my $d = pushd($C{PERLSRCDIR});
	# Note: could get the current branch with: git 'rev-parse', '--abbrev-ref', 'HEAD', {chomp=>1};
	# but since we're clobbering anyway...
	git 'checkout', '-qf', $C{PERL_BRANCH};
	git 'clean', '-dxf';
}

# ##### ##### ##### Step: Add custom extensions ##### ##### #####

if ($needs_reconfig || $opts{forceext}) {
	my $http = HTTP::Tiny->new;
	$C{DOWNLOADDIR}->mkpath(1);
	for my $modname ($C{EXTENSIONS}->@*) {
		my $apiuri = URI->new('https://fastapi.metacpan.org/v1/download_url');
		$apiuri->path_segments( $apiuri->path_segments, $modname );
		say STDERR "# Fetching $apiuri...";
		my $resp1 = $http->get($apiuri);
		die "$apiuri: $resp1->{status} $resp1->{reason}\n" unless $resp1->{success};
		my $apiresp = decode_json($resp1->{content});
		my $version = $apiresp->{version};
		my $dluri = URI->new($apiresp->{download_url});
		
		my $file = $C{DOWNLOADDIR}->file( ($dluri->path_segments)[-1] );
		die "I don't know what to do with this file type (yet): $file"
			unless $file->basename=~/(?:\.tar\.gz|\.tgz)$/i;
		
		say STDERR "# Fetching $dluri into $file...";
		my $resp2 = $http->mirror($dluri, $file);
		die "$dluri: $resp2->{status} $resp2->{reason}\n" unless $resp2->{success};
		say STDERR "# $dluri: $resp2->{status} $resp2->{reason}";
		
		my $tempd = dir( tempdir(DIR=>$C{DOWNLOADDIR}, CLEANUP => 1) );
		{
			my $d = pushd($tempd);
			my @files = Archive::Tar->new->extract_archive($file, Archive::Tar::COMPRESS_GZIP);
			say STDERR "# Extracted ",0+@files," files into $tempd";
		}
		
		my @dirs = $tempd->children;
		die "Can't handle the directory structure of this file (yet): $file"
			unless @dirs==1 && $dirs[0]->is_dir;
		my ($dirname) = $dirs[0]->basename =~ /^(.+)-\Q$version\E$/g
			or die "Failed to parse ".$dirs[0]->basename;
		my $targdir = $C{PERLSRCDIR}->subdir( 'ext', $dirname );
		my $domove = 1;
		if (-e $targdir) {
			if ( prompt("WARNING: $targdir exists, Keep or Delete? [Kd]","k")=~/^\s*d/i )
				{ $targdir->rmtree(1) }
			else { $domove=0 }
		}
		if ($domove) {
			say STDERR "# Moving $dirs[0] to $targdir";
			dirmove($dirs[0], $targdir)
				or die "move failed: $!";
		}
	}
	say STDERR "# Done setting up modules";
}
else { say STDERR "# Since we don't need a reconfig, not looking at extensions" }

# ##### ##### ##### Step: Run configure ##### ##### #####

if ($needs_reconfig) { # this means that we cleaned the source tree above
	say STDERR "# Running Configure...";
	my $d = pushd($C{PERLSRCDIR});
	# note that we don't use -Dmksymlinks here because something in the
	# Emscripten build process seems to have issues with the symlinks (?)
	run {stdin=>\undef}, 'emconfigure', 'sh', 'Configure', '-des',
		'-Dhintfile=emscripten';
}
elsif ($opts{applyconfig}) {
	say STDERR "# Running Configure -S...";
	my $d = pushd($C{PERLSRCDIR});
	run {stdin=>\undef}, 'emconfigure', 'sh', 'Configure', '-S';
}

# ##### ##### ##### Step: Build perl into outputdir ##### ##### #####

my $destdir = dir($C{OUTPUTDIR},$C{PREFIX});
if ($needs_reconfig || !-e $destdir || $opts{remakeout}) {
	say STDERR "# Rebuilding $destdir...";
	$destdir->rmtree(1);
	# make the target dir here so that nodeperl_dev_prerun.js can mount it during build
	$destdir->mkpath(1);
	
	my $d = pushd($C{PERLSRCDIR});
	
	emmake 'make', 'perl';
	
	# a really basic test to see if the build succeeded
	my $perltest = run file($C{PERLSRCDIR},'perl'), '-e', q{print "$^O $^V"},
		{chomp=>1,show_cmd=>$VERBOSE,fail_on_stderr=>1};
	die "something went wrong building perl (got: '$perltest')"
		unless $perltest eq 'emscripten '.$C{PERLVER};
	
	# note that installperl requires ./perl to be executable (our Makefile patch currently takes care of that)
	run $C{HOSTPERLDIR}.'/miniperl', 'installperl', '-p', '--destdir='.$C{OUTPUTDIR};
	
	# clean out the stuff we really don't need
	$destdir->subdir('bin')->rmtree(1);
	$destdir->recurse( callback => sub {
		my $f = shift;
		return if $f->is_dir;
		if ( ( $f->basename=~/\.(?:h|a|pod)$/i ) || ( $f->basename eq 'extralibs.ld' && (-s $f)==1 )
		  || ( $f->basename eq '.packlist' ) ) {
			print STDERR "removing $f\n";
			$f->remove or die "failed to remove $f";
		}
		elsif ( $f->basename=~/\.(?:pm|pl)$/i && $f->basename ne 'WebPerl.pm' ) {
			print STDERR "stripping POD from $f\n";
			my $strip = Pod::Strip->new;
			my ($infh,$outfh,$repl) = replace3($f);
			$strip->output_fh($outfh);
			$strip->parse_file($infh);
			$repl->finish;
		}
	});
	CLEAN_EMPTY: {
		my @todel;
		$destdir->recurse( callback => sub { push @todel, $_[0] if $_[0]->is_dir && !$_[0]->children } );
		for my $f (@todel) {
			print STDERR "removing $f\n";
			$f->remove or die "failed to remove $f";
		}
		redo CLEAN_EMPTY if @todel;
	}
	
	# Development aides:
	$destdir->subdir('dev')->mkpath(1);
	# we make them hard links so that edits to WebPerl.pm don't require a full
	# rebuild of the output directory (a rebuild of emperl.js is enough)
	safelink( $C{PERLSRCDIR}->file('ext','WebPerl','WebPerl.t'),
		$destdir->file('dev','WebPerl.t') );
	safelink( $C{PERLSRCDIR}->file('ext','WebPerl','WebPerl.pm'),
		$destdir->file('lib','5.28.0','wasm','WebPerl.pm') ); #TODO: should figure this directory out dynamically
	
	#TODO Later: Provide an easy way for users to add files to the virtual file system
	
	say STDERR "# Done rebuilding $destdir";
}

# ##### ##### ##### Step: Build emperl.js ##### ##### #####

{
	say STDERR "# Making emperl.js...";
	if ($opts{forceemperl} || $opts{remakeout})
		{ $C{PERLSRCDIR}->file('emperl.js')->remove
			or die "failed to delete emperl.js" }
	my $d = pushd($C{PERLSRCDIR});
	emmake 'make', 'emperl.js';
	say STDERR "# Done making emperl.js";
}
for my $f (qw/ emperl.js emperl.wasm emperl.data /) {
	$C{PERLSRCDIR}->file($f)
		->copy_to( dir($FindBin::Bin)->parent->subdir('web') )
			or die "failed to copy $f: $!";
}
say STDERR "# Copied emperl.* files to web dir";

# ##### ##### ##### Step: Build distro ##### ##### #####

if (my $dist = $opts{dist}) {
	my $basedir = dir($FindBin::Bin)->parent;
	my $zipfn = $basedir->file("$dist.zip");
	my $zip = Archive::Zip->new();
	$zip->addTree($basedir->subdir('web').'', dir($dist).'');
	$zip->addFile($basedir->file($_).'', dir($dist)->file($_).'') for
		qw/ README.md LICENSE_artistic.txt LICENSE_gpl.txt /;
	$zip->writeToFileNamed("$zipfn") == AZ_OK or die "$zipfn write error";
	say STDERR "# Wrote to $zipfn:";
	my $unzip = Archive::Zip->new("$zipfn");
	say "\t$_" for $unzip->memberNames;
}


# ##### ##### ##### subs ##### ##### #####

sub safelink {  # like link(OLDFILE,NEWFILE) but with extra checks
	my ($oldfile,$newfile) = @_;
	die "not a file: $oldfile" unless -f $oldfile;
	if (-e $newfile) {
		die "files don't match: $oldfile vs. $newfile"
			unless do { open my $fh, '<:raw', $oldfile or die "$oldfile: $!"; local $/; <$fh> }
			    eq do { open my $fh, '<:raw', $newfile or die "$newfile: $!"; local $/; <$fh> };
		file($newfile)->remove or die "failed to remove $newfile: $!";
	}
	link($oldfile,$newfile)
		or die "link('$oldfile','$newfile'): $!";
}

# First argument: the filename of the .patch file
# Any following arguments are additionally passed to "patch" (e.g. "-p1")
# Attempts to run "patch", will fail gracefully if the patch has already been applied.
# Dies if anything goes wrong (patch not applied cleanly, etc.).
# Returns false (0) if the patch was already applied previously, true (1) if the patch was newly applied.
sub try_patch_file {
	my ($patchf,@args) = @_;
	say STDERR "# Attempting to apply patch $patchf...";
	run 'patch', @args, '-r-', '-sNi', $patchf, {allow_exit=>[0,1],show_cmd=>$VERBOSE};
	if ($?==1<<8) {
		# Slightly hackish way to test if the patch did not apply cleanly, or it's just already been applied:
		# Apply the patch in reverse once, and then apply it again, if both go through without errors all is ok.
		# There is probably a better way to do this, I'm just feeling a little lazy at the moment.
		run 'patch', @args, '-sRi', $patchf, {show_cmd=>$VERBOSE};
		run 'patch', @args, '-si',  $patchf, {show_cmd=>$VERBOSE};
		say STDERR "# Verified that $patchf was previously applied";
		return 0;
	}
	elsif ($?) { die "patch $patchf \$?=$?" }
	else { say STDERR "# Successfully applied patch $patchf"; return 1 }
}

# A simplified version of File::pushd that outputs debug info. TODO Later: should probably propose a patch for a debug option.
sub pushd {
	if (not defined wantarray) { carp "pushd in void context"; return }
	croak "bad arguments to pushd" unless @_==1 && defined $_[0];
	my $targ = abs_path(shift);
	croak "not a directory: $targ" unless -d $targ;
	my $orig = getcwd;
	if ($targ ne $orig) {
		say STDERR "\$ cd $targ";
		chdir $targ or croak "chdir to $targ failed: $!";
	}
	return bless { orig=>$orig }, 'PushedDir';
}
sub PushedDir::DESTROY {
	my $self = shift;
	if (getcwd ne $self->{orig}) {
		say STDERR "\$ cd ".$self->{orig};
		chdir $self->{orig} or croak "chdir to ".$self->{orig}." failed: $!";
	}
}

__END__

#TODO Later: Fix the following (note setting d_getgrgid_r and d_getgrnam_r in the hints file didn't seem to help)
warning: unresolved symbol: getgrgid
warning: unresolved symbol: getgrnam
warning: unresolved symbol: llvm_fma_f64
warning: unresolved symbol: sigsuspend

#TODO Later: Fix the following "miniperl make_ext.pl" errors (warnings?)
./miniperl -Ilib make_ext.pl lib/auto/Encode/Byte/Byte.a  MAKE="make" LIBPERL_A=libperl.a LINKTYPE=static CCCDLFLAGS=
Can't find extension Encode/Byte in any of cpan dist ext at make_ext.pl line 251.
./miniperl -Ilib make_ext.pl lib/auto/Encode/Symbol/Symbol.a  MAKE="make" LIBPERL_A=libperl.a LINKTYPE=static CCCDLFLAGS=
Can't find extension Encode/Symbol in any of cpan dist ext at make_ext.pl line 251.
./miniperl -Ilib make_ext.pl lib/auto/Encode/Unicode/Unicode.a  MAKE="make" LIBPERL_A=libperl.a LINKTYPE=static CCCDLFLAGS=
Can't find extension Encode/Unicode in any of cpan dist ext at make_ext.pl line 251.

