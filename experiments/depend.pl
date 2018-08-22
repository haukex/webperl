#!/usr/bin/env perl
use warnings;
use 5.026;
use Getopt::Long qw/ HelpMessage :config posix_default gnu_compat
	bundling auto_version auto_help /;
use Graph ();
use Memoize 'memoize';
use Memoize::Storable ();

=head1 SYNOPSIS

 depend.pl MODULE(s)
 OPTIONS:
   -v | --verbose         - more output
   -t | --want-test       - include modules needed for test phase
   -p | --perl-ver VER    - Perl version for corelist (default: 5.026)
   -c | --cache-file FILE - cache file for MetaCPAN API requests
                            (default: /tmp/.metacpan_deps_cache)
   -C | --clear-cache     - clear cache before running

=head1 DESCRIPTION

A test of resolving module dependences, currently via the MetaCPAN API.
(The list of dependencies that MetaCPAN knows about may not always be complete.)

Outputs a possible install order that should satisfy dependencies.
Note this order can change across runs, but theoretically it should
always be a valid install order.

Notes for WebPerl:
Could be used in F<build.pl>.
I don't really need C<is_installed>.
Perhaps instead of C<is_core> I should check if the module exists
in the Perl source tree and is enabled in F<config.sh>...

=cut

our $VERSION = '0.01-beta';

GetOptions(
	'v|verbose'      => \(my $VERBOSE),
	't|want-test'    => \(my $WANT_TEST),
	'p|perl-ver=s'   => \(my $PERL_VER='5.026'),
	'c|cache-file=s' => \(my $CACHE_FILE='/tmp/.metacpan_deps_cache'),
	'C|clear-cache'  => \(my $NO_CACHE),
	) or HelpMessage(-exitval=>255);
HelpMessage(-msg=>'Not enough arguments',-exitval=>255) unless @ARGV;


if ($NO_CACHE && -e $CACHE_FILE)
	{ unlink($CACHE_FILE)==1 or die "Failed to unlink $CACHE_FILE: $!" }
tie my %get_deps_cache, 'Memoize::Storable', $CACHE_FILE;
memoize 'get_deps', SCALAR_CACHE=>[HASH=>\%get_deps_cache], LIST_CACHE=>'FAULT';
memoize 'is_core';
memoize 'is_installed';


my $dep_graph = Graph->new(directed => 1);
resolve_deps($_, $dep_graph) for @ARGV;
my @topo = $dep_graph->topological_sort;
say for reverse @topo;
warn "No (non-core) dependencies\n" unless @topo;


use MetaCPAN::Client ();
sub get_deps { # will be memoized (and persisted)
	my ($module) = @_;
	state $mcpan = MetaCPAN::Client->new();
	$VERBOSE and say STDERR "Fetching dependencies of $module from MetaCPAN API";
	return $mcpan->release($mcpan->module($module)->distribution)->dependency;
}

use Module::CoreList ();
sub is_core { # will be memoized
	my ($module,$version) = @_;
	return Module::CoreList::is_core($module,$version,$PERL_VER);
}

use Module::Load::Conditional ();
sub is_installed { # will be memoized
	my ($module,$version) = @_;
	return Module::Load::Conditional::check_install(module=>$module,version=>$version);
}

sub resolve_deps {
	my $module = shift;
	my $graph = @_ ? shift : Graph->new(directed => 1);
	for my $dep ( get_deps($module)->@* ) {
		next if is_core( $dep->{module}, $dep->{version} );  # ignore core modules
		next if $dep->{module} eq 'perl';                    # ignore perl dist itself
		next unless $dep->{relationship} eq 'requires';      # ignore 'recommends' and 'suggests'
		die "Unknown relationship '$dep->{relationship}'"
			unless $dep->{relationship}=~/\A(?:requires|recommends|suggests)\z/;
		next if $dep->{phase} eq 'develop';                  # ignore phase 'develop'
		next if !$WANT_TEST && $dep->{phase} eq 'test';      # ignore phase 'test' unless user wants it
		next if $dep->{phase}=~/\Ax_/;                       # ignore e.g. "x_Dist_Zilla"
		die "Unknown phase '$dep->{phase}'"
			unless $dep->{phase}=~/\A(?:configure|build|runtime|test)\z/;
		my $installed = is_installed( $dep->{module}, $dep->{version} );  # just for info
		$VERBOSE and say STDERR "$module requires $dep->{module}",
			$dep->{version} ? " (version $dep->{version})" : " (any version)",
			" for $dep->{phase}",
			$installed ? " (installed)" : " (not installed)";
		$graph->add_edge($module, $dep->{module});
		die "Fatal: Circular dependency detected (just added $module->$dep->{module})"
			if $graph->has_a_cycle;
		resolve_deps($dep->{module}, $graph)
	}
	return $graph;
}

