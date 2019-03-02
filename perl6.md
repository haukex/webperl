
\[ [Using](using.html) -
[Building](building.html) -
🦋 -
[Notes](notes.html) -
[Legal](legal.html) -
[Wiki](https://github.com/haukex/webperl/wiki/Perl6) \]

WebPerl Experimental Perl 6 Support 🦋
=====================================


Thanks to [**Paweł Murias**](https://github.com/pmurias) and his
amazing work on **`Rakudo.js`** and
[**6Pad**](https://perl6.github.io/6pad/), I've been able to patch
support for Perl 6 into WebPerl!

Currently **requires Google Chrome** (due to BigInt support), see the
[Quick Start](#quick-start) below on how to get this up and running on
your local machine!

```html
<script src="webperl.js"></script>
<script type="text/perl6">

say "Hello, Perl 6 World!";   # goes to JavaScript console by default

my $document = EVAL(:lang<JavaScript>, 'return document');
my $window   = EVAL(:lang<JavaScript>, 'return window');
$document.getElementById('my_button')
	.addEventListener("click", -> $event {
		$window.alert("You clicked the button!");
	} );
</script>
```


Quick Start
-----------

- Prerequisites: `perl` (a recent version is recommended, e.g. v5.26 and up),
  and [`cpanm`](https://metacpan.org/pod/App::cpanminus) to easily install
  dependencies (otherwise, see the files `cpanfile` for the dependencies and
  use the module installer of your choce).

- In a shell (the following assumes Linux):
  
      $ git clone https://github.com/haukex/webperl.git
      $ cd webperl
      $ wget https://github.com/haukex/webperl/releases/download/v0.09-beta/webperl_prebuilt_v0.09-beta.zip
      $ unzip -j webperl_prebuilt_v0.09-beta.zip '*/emperl.*' -d web
      $ cpanm --installdeps .
      $ cd experiments ; cpanm --installdeps . ; cd ..
      $ experiments/p6/6init.pl   # this patches Perl 6 support in
      $ plackup web/webperl.psgi

- Then point your Chrome browser at <http://localhost:5000/6demo.html>,
  and have a look at its source.

Have fun!


Experimental Status and Notes
-----------------------------

- I don't have enough experience with `Rakudo.js`
	- <https://github.com/rakudo/rakudo/tree/master/src/vm/js>
	- <https://perl6.github.io/6pad/>
	- <http://blogs.perl.org/users/pawel_murias/>
	- <https://github.com/perl6/perl6-parcel-example>
	- <https://www.youtube.com/watch?v=LN0mKjmraVs>

- requires BigInt support, which is currently only available in Chrome
	- <https://developers.google.com/web/updates/2018/05/bigint>
	- <https://github.com/tc39/proposal-bigint>
	- <https://v8.dev/blog/bigint>

- Large download (10MB compressed, 74MB uncompressed) - can we
  repackage it to make it smaller, or is there a good way to
  distribute this?

- STDERR only goes to console, STDOUT gets output with HTML escapes


Documentation
-------------

My code steal^H^H^H^H^Hborrows the prepackaged `Rakudo.js` build from
[6Pad](https://perl6.github.io/6pad/) and caches it locally. The script
`experiments/p6/6init.pl` also patches the experimental P6 support into
`webperl.js` (see the [Quick Start](#quick-start) above).

Note that both Perl 5 and Perl 6 are only loaded on demand by
`webperl.js`, so if you only use one or the other, you won't have the
overhead of loading both.

For now, I've basically just patched `Rakudo.js`'s `evalP6()` into
`Raku.eval()`, and `NQP_STDOUT` into `Raku.output`, to make things more
like the Perl 5 WebPerl, and provided some of the same API for Perl 6
as I provide for Perl 5.

The JS API provided by WebPerl for Perl 6 currently closely mirrors
[the Perl 5 API](using.html#webperljs): There is a JS object `Raku`
which provides the following functions / properties that do mostly the
same as for Perl 5:

- `Raku.addStateChangeListener( function (from,to) {} )`
- `Raku.state`
- `Raku.output = function (str,chan) {}`
- `Raku.makeOutputTextarea()`
- `Raku.init( function () {} )`
- `Raku.eval( code )`

You can add Perl 6 code to your HTML pages with `<script>` tags
with `type="text/perl6"` or `type="text/raku"`.

For everything else, I defer to `Rakudo.js` for now! I will update this
documentation as things evolve.


***

Additional notes on WebPerl's experimental Perl 6 support may be found
in the [GitHub Wiki](https://github.com/haukex/webperl/wiki/Perl6).

***

Copyright (c) 2018 Hauke Daempfling (haukex@zero-g.net)
at the Leibniz Institute of Freshwater Ecology and Inland Fisheries (IGB),
Berlin, Germany, <http://www.igb-berlin.de>

Please see the ["Legal" page](legal.html) for details.

***

You can find the source for this page at
<https://github.com/haukex/webperl/blob/gh-pages/perl6.md>


