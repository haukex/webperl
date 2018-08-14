use warnings;
use 5.026;
use Time::HiRes qw/gettimeofday tv_interval/;

my $t0 = [gettimeofday];
my @primes = join ',', grep {prime($_)} 1..1000000;
my $elapsed = tv_interval($t0);
printf "%.3f\n", $elapsed;

# http://www.rosettacode.org/wiki/Primality_by_trial_division#Perl
sub prime {
	my $n = shift;
	$n % $_ or return for 2 .. sqrt $n;
	$n > 1
}

# A quick test: This program, when run
# from WebPerl (Firefox):  ~7.4s 
# natively (same machine): ~2.3s
# => roughly 3.2 times slower
