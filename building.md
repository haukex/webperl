
\[ [Using](using.html) -
Building -
[Notes](notes.html) -
[Legal](legal.html) -
[GitHub Wiki](https://github.com/haukex/webperl/wiki/Building-WebPerl) \]

🕸️🐪 Building WebPerl
===================


Prerequisites
-------------

- Linux, a fairly modern release is strongly recommended, and `bash`
  (tested on a minimum of Ubuntu 16.04)
- `git` (e.g. Ubuntu/Debian: `sudo apt-get install git-core`)
- Build tools for `perl`; for example on Ubuntu:
  `sudo apt-get install build-essential` and `sudo apt-get build-dep perl`
- Perl, at least v5.26 (for example via [Perlbrew](http://perlbrew.pl/))
- [Emscripten](http://emscripten.org) SDK, 1.38.10 and up,
  please see the prerequisites and installation instructions at
  <http://kripken.github.io/emscripten-site/docs/getting_started/downloads.html#installation-instructions>
- The build script has several CPAN dependencies. One way to install them
  is using [lazy](https://metacpan.org/pod/lazy): first,
  install "lazy", then run e.g. `perl -Mlazy build.pl --help`.
  Otherwise, the modules used by `build.pl` can be seen in
  [its source](https://github.com/haukex/webperl/blob/master/build/build.pl)
  grouped near the top of the file.
- A working Internet connection is needed for installation and the first build.


Source Code
-----------

The source code is in two repositories:

- <https://github.com/haukex/webperl> - the main WebPerl repository

- <https://github.com/haukex/emperl5> - a fork of the Perl 5 source
  repository where the WebPerl-specific patches are applied

You only need to check out the first of the two, the `emperl5` repository
is checked out by the build script.


Running the Build
-----------------

1. Fetch the source code.
   
       $ git clone https://github.com/haukex/webperl.git
       $ cd webperl

2. Install the [prerequisites](#Prerequisites).

3. Edit the configuration file, `./build/emperl_config.sh`, to fit
   your system. For a first build, just make sure the path to
   `emsdk_env.sh` is correct.

4. Source the configuration file to set the environment variables.
   Remember to do this anytime you change variables. You may also
   add the sourcing of the configuration file to your `~/.bashrc`.

       $ . ./build/emperl_config.sh

5. Run the build script:

       $ build/build.pl

6. If the build succeeds, the output files `emperl.*` will be
   copied to the `web` directory of the repository. You can
   then use the files in the `web` directory as described in
   [Using WebPerl](using.html).


Build Process Overview
----------------------

The build script `build.pl` tries to take care of as much of the build process as
possible. Most of the work happens in a subdirectory `work` of the repository.
Similar to `make`, it tries to not run build steps that don't need to be rerun.

> A brief note on naming:
>
> - *`emperl`* is generally used for the build products of Emscripten
> - *`emperl5`* is the Perl 5 source tree modified for WebPerl
> - *WebPerl* is the finished product, including `emperl`
>   and the WebPerl APIs (`WebPerl.pm` and `webperl.js`)

The steps in the build process are roughly as follows.
Since WebPerl is still in beta, they are subject to change.
See
[the source of the `build.pl` script](https://github.com/haukex/webperl/blob/master/build/build.pl)
for the current details.

1. Patch Emscripten
   (currently just a minor patch, but important for Perl)

2. Fetch/update the `emperl5` Perl source tree

3. If necessary, build "host Perl" - in Perl's cross-compilation system,
   this is the Perl that is built for the host system architecture,
   i.e. in the case of Linux, a normal build of Perl for Linux. The
   `miniperl` from the host Perl will be used for some of the build
   steps for the target architecture.
   (Note: This step can take quite a while, but it usually only needs
   to be run once.)

4. Download and extract any CPAN modules, such as the required `Cpanel::JSON::XS`,
   into the Perl source tree so that they will be built as part of the normal
   build process and any XS extensions linked statically into the `perl` binary.
   (See ["Adding CPAN Modules"](#adding-cpan-modules))

5. Run Perl's `Configure` script using the custom "hints" file for the Emscripten
   architecture.

6. Run `make` to compile `perl`. This produces a file `perl.bc` with LLVM IR
   bitcode, which the Emscripten compiler will then compile to JavaScript/WebAssembly.
   Because some steps in the build process require a working `perl` binary,
   Emscripten's compiler is used together with a supporting JavaScript file to
   generate JavaScript/WebAssembly code that can be run with `node.js` (called `nodeperl_dev.js`).

8. Run the equivalent of `make install`, which copies all the Perl modules
   etc. into the target directory that will become part of the Emscripten
   virtual file system. Then, we clean this directory up by deleting anything
   that we don't need for WebPerl: additional binaries (it's a single-process
   environment), `*.pod` files, as well as stripping the POD out of `*.pm`
   files, etc. to reduce the download size.

9. The Emscripten compiler is used to take the previously compiled `perl.bc`
   and build the final output, `emperl.js` along with the corresponding
   `.wasm` and `.data` file. This step also includes the packaging of the
   virtual filesystem.

`build.pl` provides various command-line options that allow you to control
parts of the build process. See `build.pl --help` for details.


Adding CPAN Modules
-------------------

In the configuration file `emperl_config.sh`, the variable `EMPERL_EXTENSIONS`
is a whitespace-separated list of module names. `build.pl` will fetch these
from CPAN and extract them into the `ext` directory of the Perl source tree
so that they are compiled along with Perl. Any XS modules that need to be
linked into `perl` need to be added to the variable `EMPERL_STATIC_EXT` in
the format expected by Perl's `static_ext` configuration variable,
so for example `Cpanel/JSON/XS` instead of `Cpanel::JSON::XS`
(see <http://perl5.git.perl.org/perl.git/blob/HEAD:/Porting/Glossary>).

Note that the build script does **not** automatically fetch modules'
dependencies, for now you will need to resolve them and add them to
`EMPERL_EXTENSIONS` yourself. (This may be improved upon in the future.)


***

Additional notes on building WebPerl may be found in the
[GitHub Wiki](https://github.com/haukex/webperl/wiki/Building-WebPerl).

***

Copyright (c) 2018 Hauke Daempfling (haukex@zero-g.net)
at the Leibniz Institute of Freshwater Ecology and Inland Fisheries (IGB),
Berlin, Germany, <http://www.igb-berlin.de>

Please see the ["Legal" page](legal.html) for details.

