
🕸️🐪 Misc. Notes on WebPerl
=========================

\[ [Using](using.html) -
[Building](building.html) -
Notes -
[Legal](legal.html) -
[GitHub Wiki](https://github.com/haukex/webperl/wiki) \]


TODOs
-----

- <https://github.com/haukex/webperl/blob/master/ToDo.md>
- <https://github.com/haukex/webperl/issues>
- <https://github.com/haukex/webperl/pulls>


Possible Improvements
---------------------

- More efficient JS/C/Perl glue
- Test/Support sockets/WebSockets
	- for example, can we compile a DBD:: module to connect to a DB on the server?
- A RPC module for communicating between client and server Perls
- Support some of the Emscripten API (like wget?)
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
  (see discussion in `webperl.js`, and `NO_EXIT_RUNTIME` in the Emscripten documentation - currently it
  seems to make the most sense to build with `NO_EXIT_RUNTIME=1`)
- Static linking, requires rebuild to add modules
  (Emscripten apparently only supports asm.js dynamic linking when dynamic memory growth is disabled, which is not very useful)


Prior Art
---------

Several people have built microperl with Emscripten:

- Harsha <https://github.com/moodyharsh/plu>
- Shlomi Fish <https://github.com/shlomif/perl5-for-JavaScript--take2>
- FUJI Goro <https://github.com/gfx/perl.js>

