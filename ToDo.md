
WebPerl TODOs
=============

<http://webperl.zero-g.net>

1. Documentation (Website)
	
	- Check if intra-page links work

2. Testing
	
	- Continue work on `WebPerl.t`
		- More tests for Unicode support (Perl/JS interface, Perl.eval(), plus Emscripten's virtual FS)
	- Focus on getting the tests running in the browser instead of node.js
	- How to best package tests?
		- If possible, a separate bundle, so that it can be loaded optionally and we don't need to rebuild
		- How does `make test` find and handle all the various modules' `t`s?
	- How to best disable individual tests that we know won't work? (qx etc.)
	- How to handle the many tests that call an external Perl?
		- patching t/test.pl's runperl() seems easiest at the moment, and we can use the iframe method from the IDE

3. Misc

	- Test if a CDN would work
	- Perhaps create a CPAN Bundle:: module or similar for `build.pl` deps?

See also: "TODO" tags in code (use `findtodo.sh`)

