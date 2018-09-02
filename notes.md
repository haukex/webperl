
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


Miscellaneous
-------------

- Generating a [Subresource Integrity](https://developer.mozilla.org/en-US/docs/Web/Security/Subresource_Integrity) value:
  
      $ perl -wMstrict -MDigest -le 'open my $fh, "<:raw", "web/webperl.js" or die $!;
        print Digest->new("SHA-256")->addfile($fh)->b64digest'


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

