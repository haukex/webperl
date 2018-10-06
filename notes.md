
\[ [Using](using.html) -
[Building](building.html) -
Notes -
[Legal](legal.html) -
[GitHub Wiki](https://github.com/haukex/webperl/wiki) \]

🕸️🐪 Misc. Notes on WebPerl
=========================


TODOs
-----

1. Testing
	
	- Continue work on `WebPerl.t`
		- More tests for Unicode support (Perl/JS interface, Perl.eval(), plus Emscripten's virtual FS)
	- Focus on getting the tests running in the browser instead of node.js
	- How to best package tests?
		- If possible, a separate bundle, so that it can be loaded optionally and we don't need to rebuild
		- How does `make test` find and handle all the various modules' `t`s?
	- How to best disable individual tests that we know won't work? (qx etc.)
	- How to handle the many tests that call an external Perl?
		- patching t/test.pl's runperl() seems easiest at the moment, and we can use the iframe method from the IDE

2. Misc
	
	- Write up a full RPC example
	- Investigate Emscripten's main loop concept for handling nonblocking sockets?
	- Turn some patches from emperl5 into patches for P5P
	- Submit some patches to Emscripten
		- <https://github.com/kripken/emscripten/pull/7005>
		- <https://github.com/kripken/emscripten/issues/7029>
		- Would we need to patch Perl's signal functions if Emscripten's stubs weren't noisy?
	- Add Perl.Util functions for making file uploads and downloads easier
		- Plus an example showing how to use it to run a "legacy" Perl script with inputs and output
	- Perhaps create a CPAN Bundle:: module or similar for `build.pl` deps?
	- There is some potential for restructuring:
		- `Perl.glue()` and `Perl.dispatch()` could go into `WebPerl.xs` (?)
		- Parts of `webperl.js` could go into `common_preamble.js` or `WebPerl.xs`,
		  so that `emperl.js` is runnable on its own in a Web Worker (?)
		  (see notes in `perlrunner.html` / `e12f1aa25a000`)
		- `nodeperl_dev_prerun.js` could probably be merged into that as well

3. See Also
	
	- <https://github.com/haukex/webperl/issues>
	- <https://github.com/haukex/webperl/pulls>
	- See also `TODO`s in the source tree by grepping for `TODO`
	  or using the included `findtodo.sh`.


Possible Improvements
---------------------

- More efficient JS/C/Perl glue
- Test/Support sockets/WebSockets
	- for example, can we compile a DBD:: module to connect to a DB on the server?
- A RPC module for communicating between client and server Perls
	- I think it's probably best to not have WebPerl prescribe a specific RPC mechanism,
	  since there's a big variety and many are pretty simple to implement using e.g. jQuery
- Support some of the Emscripten C API (like wget?)
- Try to shrink the download size more (exclude more modules, ...?)


Limitations
-----------

- Only works in browsers with WebAssembly support
  (asm.js requires aligned memory access, and Perl apparently has quite a few places with unaligned access)
- 32-bit ints
- No `system`, `qx`, `fork`, `kill`, `wait`, `waitpid`, threads, etc.
	- Theoretically, we could link in BusyBox to get a shell and utilities (??)
	- (`system` and `qx` support could theoretically be added by patching `pp_system`/`pp_backtick` in `pp_sys.c`)
- No signals (except `SIGALRM`)
- In the current configuration, `exit` is not supported, and therefore `atexit` handlers aren't supported
  (see discussion in [Using WebPerl](using.html), and `NO_EXIT_RUNTIME` in the Emscripten documentation -
  currently it seems to make the most sense to build with `NO_EXIT_RUNTIME=1`)
- Static linking, requires rebuild to add modules
  (Emscripten apparently only supports asm.js dynamic linking when dynamic memory growth is disabled, which is not very useful)


Release Checklist
-----------------

- Update `Changes.md` with all changes since last release
  
  As an example, to list changes since a specific version, excluding the regex tester:
  
      $ git log --stat v0.05-beta.. -- . ':!web/regex_tester.html' ':!.gitignore'
  
	- Also make sure that the documentation in `using.md` etc. mentions when features were added/deprecated

- Update version numbers everywhere; use `grep` to find them, for example:
  
      $ grep -Er --exclude-dir=work --exclude-dir=.git --exclude-dir=emperl5 --exclude=emperl.* '0\.0[0-9]' .
      $ ( cd emperl5; grep -Er '0\.0[0-9]' `git diff --numstat --diff-filter=A v5.28.0 HEAD | cut -f3` )
  
  At a minimum there is:
	- `web/webperl.js` - `Perl.WebPerlVersion`
	- `emperl5/ext/WebPerl/WebPerl.pm` - `$VERSION`
	- `pages/index.md` - download links

- Update [Subresource Integrity](https://developer.mozilla.org/en-US/docs/Web/Security/Subresource_Integrity) values as needed, e.g.:
  
      $ perl -wMstrict -MDigest -le 'open my $fh, "<:raw", "web/webperl.js" or die $!;
        print Digest->new("SHA-256")->addfile($fh)->b64digest'

- Build and create dist, e.g. `build/build.pl --reconfig --dist=webperl_prebuilt_v0.07-beta`

- Test all build results, both from `file://...` and `http://localhost`

- Add tags, the `webperl` repo gets an annotated tag such as `v0.07-beta`,
  and the `emperl5` repo gets an unannotated tag such as `webperl_v0.07-beta`,
  then `git push --tags`

- Create a release on GitHub and upload the `webperl_prebuilt_*.zip` as an asset

- Uploading to AWS S3:
	1. Run `gzip -9` on `emperl.*` and `webperl.js`
	2. Rename them to remove the `.gz` ending
	3. Upload them with the appropriate `Content-Type` (see e.g. `web/webperl.psgi`) and a `Content-Encoding` of `gzip`

- If there was a `pages_for_vX.XX` branch of `gh-pages`, don't forget to merge that


Prior Art
---------

Several people have built microperl with Emscripten:

- Harsha <https://github.com/moodyharsh/plu>
- Shlomi Fish <https://github.com/shlomif/perl5-for-JavaScript--take2>
- FUJI Goro <https://github.com/gfx/perl.js>


***

Copyright (c) 2018 Hauke Daempfling (haukex@zero-g.net)
at the Leibniz Institute of Freshwater Ecology and Inland Fisheries (IGB),
Berlin, Germany, <http://www.igb-berlin.de>

Please see the ["Legal" page](legal.html) for details.

***

You can find the source for this page at
<https://github.com/haukex/webperl/blob/gh-pages/notes.md>

