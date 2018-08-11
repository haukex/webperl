
🕸️🐪 Welcome to WebPerl!
======================

\[ [Using](using.html) -
[Building](building.html) -
[Notes](notes.html) -
[Legal](legal.html) -
[GitHub Wiki](https://github.com/haukex/webperl/wiki) \]


WebPerl uses the power of [WebAssembly](https://webassembly.org/) and
[emscripten](http://emscripten.org/) to let you run Perl 5 in the browser!

**Notice: WebPerl is in beta.**
Some things may not work yet, and parts of the API may still change.
Your feedback is always appreciated!

```html
<script src="webperl.js"></script>
<script type="text/perl">
use WebPerl qw/js/;

print "Hello, Perl World!\n";

js('document')->getElementById('my_button')
	->addEventListener("click", sub {
		print "You clicked 'Testing!'\n";
	} );
</script>
```

