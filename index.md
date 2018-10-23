
\[ [Using](using.html) -
[Building](building.html) -
[Notes](notes.html) -
[Legal](legal.html) -
[GitHub Wiki](https://github.com/haukex/webperl/wiki) \]

Welcome to WebPerl!
===================


WebPerl uses the power of [WebAssembly](https://webassembly.org/) and
[Emscripten](http://emscripten.org/) to let you run Perl 5 in the browser!

WebPerl does not translate your Perl code to JavaScript, instead, it is
a port of the `perl` binary to WebAssembly, so that you have the full
power of Perl at your disposal!

**Notice: WebPerl is very much in beta.**
Some things may not work yet, and parts of the API may still change.
Your feedback is always appreciated!

```html
<script src="webperl.js"></script>
<script type="text/perl">

print "Hello, Perl World!\n";  # goes to JavaScript console by default

js('document')->getElementById('my_button')
	->addEventListener('click', sub {
		js('window')->alert("You clicked the button!");
	} );
</script>
```

- [**Download `webperl_prebuilt_v0.07-beta.zip`**](https://github.com/haukex/webperl/releases/download/v0.07-beta/webperl_prebuilt_v0.07-beta.zip)
- [**Get the sources on GitHub**](https://github.com/haukex/webperl)

For web applications written with WebPerl, see:

- [**WebPerl Code Demo Editor** (beta)](democode/index.html)
- [**WebPerl Regex Tester** (beta)](regex.html)


Quick Start
-----------

- Prerequisites: `perl` (a recent version is recommended, e.g. v5.26 and up),
  [`plackup` from Plack](https://metacpan.org/pod/distribution/Plack/script/plackup),
  and [Cpanel::JSON::XS](https://metacpan.org/pod/Cpanel::JSON::XS).

- In a shell:
  
      $ wget https://github.com/haukex/webperl/releases/download/v0.07-beta/webperl_prebuilt_v0.07-beta.zip
      $ unzip webperl_prebuilt_v0.07-beta.zip
      $ cd webperl_prebuilt_v0.07-beta
      $ plackup webperl.psgi
      HTTP::Server::PSGI: Accepting connections at http://0:5000/

- Then point your browser at <http://localhost:5000/webperl_demo.html>
  and have a look at its source. The ZIP archive also contains several
  other examples, which you can access at <http://localhost:5000/>.

You may also host the contents of the above ZIP archive on a webserver of your
choice, or some browsers will support opening the files locally; both are
described in [Serving WebPerl](using.html#serving-webperl).
(Note: In `webperl_demo.html`, you'll likely see "AJAX Failed!", which is to be
expected since your webserver won't know how to handle the example AJAX request.)

Have fun!


***

Copyright (c) 2018 Hauke Daempfling (haukex@zero-g.net)
at the Leibniz Institute of Freshwater Ecology and Inland Fisheries (IGB),
Berlin, Germany, <http://www.igb-berlin.de>

Please see the ["Legal" page](legal.html) for details.

***

You can find the source for this page at
<https://github.com/haukex/webperl/blob/gh-pages/index.md>

