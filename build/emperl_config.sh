#!/bin/bash

# This is the configuration file for building WebPerl.
# You should edit it according to the comments below.
# Remember to reload this file after making changes! (". emperl_config.sh")

# You must edit this to point to your Emscripten SDK's emsdk_env.sh.
. $HOME/emsdk/emsdk_env.sh

# A whitespace-separated list of modules to download and add to the build.
# Note: Cpanel::JSON::XS is required for WebPerl!
export EMPERL_EXTENSIONS="Cpanel::JSON::XS Devel::StackTrace Future"

# Modules from the above list that have XS code need to be linked statically.
# Add them here, separated by whitespace (see also the "static_ext" variable
# in https://perl5.git.perl.org/perl.git/blob/HEAD:/Porting/Glossary ).
export EMPERL_STATIC_EXT="Cpanel/JSON/XS"

# Do not edit (this gets this script's parent directory)
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. >/dev/null && pwd )"

# Various working directories, you normally don't need to edit these
export EMPERL_PERLSRCDIR="$BASEDIR/emperl5"
export EMPERL_HOSTPERLDIR="$BASEDIR/work/hostperl"
export EMPERL_DOWNLOADDIR="$BASEDIR/work/download"
export EMPERL_OUTPUTDIR="$BASEDIR/work/outputperl"

# Don't edit the following options unless you know what you're doing!
# Note to self: In build.pl, we take advantage of the fact that on Perls >=v5.10.0, "$^V" is the same as the tag name.
export EMPERL_PERLVER="v5.30.0"
export EMPERL_PREFIX="/opt/perl"
# Note: strace shows this is how file_packager.py is called: ["/usr/bin/python", "/home/haukex/emsdk/emscripten/1.38.28/tools/file_packager.py", "emperl.data", "--from-emcc", "--export-name=Module", "--preload", "/home/haukex/code/webperl/work/outputperl/opt/perl@/opt/perl", "--no-heap-copy"]
export EMPERL_PRELOAD_FILE="$EMPERL_OUTPUTDIR$EMPERL_PREFIX@$EMPERL_PREFIX"
export EMPERL_OPTIMIZ="-O2"
# Note: We explicitly disable ERROR_ON_UNDEFINED_SYMBOLS because it was enabled by default in Emscripten 1.38.13.
#TODO Later: Why does --no-heap-copy not get rid of the "in memory growth we are forced to copy it again" assertion warning? (https://github.com/emscripten-core/emscripten/commit/ec764ace634f13bab5ae932912da53fe93ee1b69)
export EMPERL_LINK_FLAGS="--pre-js common_preamble.js --no-heap-copy -s ERROR_ON_UNDEFINED_SYMBOLS=0 -s EXPORTED_FUNCTIONS=['_main','_emperl_end_perl','_Perl_call_sv','_Perl_call_pv','_Perl_call_method','_Perl_call_argv','_Perl_eval_pv','_Perl_eval_sv','_webperl_eval_perl'] -s EXTRA_EXPORTED_RUNTIME_METHODS=['ccall','cwrap']"

export EMPERL_DEBUG_FLAGS=""
#export EMPERL_DEBUG_FLAGS="-s ASSERTIONS=2 -s STACK_OVERFLOW_CHECK=2"
# Note: not including "-s SAFE_HEAP=1" in the debug flags because we're building to WebAssembly, which doesn't require alignment
#TODO Later: Can some of the SAFE_HEAP functionality (null pointer access I think?) be replaced by the WASM error traps?
# http://kripken.github.io/emscripten-site/docs/compiling/WebAssembly.html#binaryen-codegen-options

# Location and branch of the perl git repository that contains the emperl branch
export EMPERL_PERL_REPO="https://github.com/haukex/emperl5.git"
export EMPERL_PERL_BRANCH="emperl_$EMPERL_PERLVER"
# Enabling this setting causes the local emperl branch to be deleted and re-fetched from the origin.
# This is useful during development, when rewrites of the (unpublished!) git history of the branch might happen.
export EMPERL_CLOBBER_BRANCH=0

