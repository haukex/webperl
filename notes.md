
\[ [Using](using.html) -
[Building](building.html) -
Notes -
[Legal](legal.html) -
[GitHub Wiki](https://github.com/haukex/webperl/wiki) \]

🕸️🐪 Misc. Notes on WebPerl
=========================


To-Dos
------

- <https://github.com/haukex/webperl/blob/master/ToDo.md>
- <https://github.com/haukex/webperl/issues>
- <https://github.com/haukex/webperl/pulls>
- See also To-Dos in the source tree by grepping for `TODO`
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
  
  As an example, to list changes between `v0.03-beta` and `v0.05-beta`, excluding the regex tester:
  
      $ git log --stat v0.03-beta..v0.05-beta -- . ':!web/regex_demo.html' ':!web/regex_tester.html' ':!.gitignore'
  
	- Also make sure that the documentation in `using.md` etc. mentions when features were added/deprecated

- Update version numbers everywhere; use `grep` to find them, for example:
  
      $ grep -Er --exclude-dir=.git --exclude-dir=emperl5 --exclude=emperl.* '0\.0[0-9]' * emperl5/ext/WebPerl
  
  At a minimum there is:
	- `web/webperl.js` - `Perl.WebPerlVersion`
	- `emperl5/ext/WebPerl/WebPerl.pm` - `$VERSION`
	- `pages/index.md` - download links

- Update [Subresource Integrity](https://developer.mozilla.org/en-US/docs/Web/Security/Subresource_Integrity) values as needed, e.g.:
  
      $ perl -wMstrict -MDigest -le 'open my $fh, "<:raw", "web/webperl.js" or die $!;
        print Digest->new("SHA-256")->addfile($fh)->b64digest'

- Build and create dist, e.g. `build/build.pl --reconfig --dist=webperl_prebuilt_v0.05-beta`

- Test all build results, both from file:// and http://localhost

- Add tags, the `webperl` repo gets an annotated tag such as `v0.05-beta`,
  and the `emperl5` repo gets an unannotated tag such as `webperl_v0.05-beta`,
  then `git push --tags`

- Create a release on GitHub and upload the `webperl_prebuilt_*.zip` as an asset

- If there was a `pages_for_vX.XX` branch of `gh-pages`, don't forget to merge that

- Uploading to AWS S3:
	1. Run `gzip -9` on `emperl.*` and `webperl.js`
	2. Rename them to remove the `.gz` ending
	3. Upload them with the appropriate `Content-Type` (see e.g. `web/webperl.psgi`) and a `Content-Encoding` of `gzip`


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

