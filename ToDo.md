
WebPerl TODOs
=============

<http://webperl.zero-g.net>

1. Documentation (Website)
	
	- Using WebPerl
		- the user must explicitly "unregister" anonymous Perl subs (or show alternatives) to prevent %CodeTable from growing too large
		- the user shouldn't mess with the symbol table (delete subs, redefine them, etc.)
		- <http://kripken.github.io/emscripten-site/docs/compiling/Deploying-Pages.html>
	- Building WebPerl
		- test out perl -Mlazy to install all the deps (and if it works well, document)

2. Testing
	
	- Continue work on `WebPerl.t`
		- More tests for Unicode support (Perl/JS interface, Perl.eval(), plus Emscripten's virtual FS)
	- I should focus on getting the tests running in the browser instead of node.js
		- How to package tests? How does `make test` find&handle all the various modules' `t`s?
	- How to best disable individual tests that we know won't work? (qx etc.)
	- How to handle the many tests that call an external Perl?
		- patching t/test.pl's runperl() seems easiest at the moment, and we can use the iframe method from the IDE

3. Misc

	- Test if a CDN would work

See also: "TODO" tags in code (use `findtodo.sh`)

