
\[ Using -
[Building](building.html) -
[Notes](notes.html) -
[Legal](legal.html) -
[GitHub Wiki](https://github.com/haukex/webperl/wiki/Using-WebPerl) \]

🕸️🐪 Using WebPerl
================


**Notice: WebPerl is very much in beta.**
Some things may not work yet, and parts of the API may still change.
Your feedback is always appreciated!


Basic Usage
-----------

### Serving WebPerl

You should serve WebPerl via a webserver of your choice, or you can
use the included simple `webperl.psgi` for testing. You can run it using
[`plackup` from Plack](https://metacpan.org/pod/distribution/Plack/script/plackup)
by simply saying `plackup webperl.psgi`.

The following four files make up WebPerl:

- `webperl.js`  - Contains the WebPerl JavaScript API and supporting code.
- `emperl.js`   - Emscripten-generated supporting JavaScript.
- `emperl.wasm` - The `perl` binary and libraries compiled to WebAssembly.
- `emperl.data` - The Emscripten virtual file system data (`.pm` files etc.).

I strongly recommend you add a MIME type of `application/wasm` for `.wasm` files,
otherwise you may see warnings like
"wasm streaming compile failed: TypeError: Response has unsupported MIME type" and
"falling back to ArrayBuffer instantiation".
For example, in an Apache `.htaccess` file, you can say: `AddType application/wasm .wasm`

Note that opening the files locally (via `file://`) may not work
due to browsers' Same-Origin Policy. However, there are some workarounds:

* On Linux, the "wasm streaming compile failed: TypeError: Response has unsupported MIME type /
falling back to ArrayBuffer instantiation" warnings can be worked around by
adding the line `application/wasm	wasm` to `~/.mime.types` or `/etc/mime.types`
* In Firefox, if your files reside in different directories, the same-origin policy can be
made more lax for `file://` URIs by disabling the
[security.fileuri.strict_origin_policy](http://kb.mozillazine.org/Security.fileuri.strict_origin_policy)
option. **But be aware** of the security implications of disabling this option!

See also the Emscripten deployment notes at
<http://kripken.github.io/emscripten-site/docs/compiling/Deploying-Pages.html>,
in particular I'd recommended using gzip encoding to serve the WebPerl files.

### Including Perl code in your HTML

In your HTML file, add the following (usually inside the `<head>` tags):

    <script src="webperl.js"></script>

Then, you can add one or more `<script type="text/perl">` tags containing embedded Perl code,
or a single `<script type="text/perl" src="foo.pl"></script>` tag which loads a
Perl script from the server - but not both! The code from multiple
`<script type="text/perl">` tags will be concatenated and run as a single script.

If you use embedded `<script type="text/perl">` tags, then the function `js` from
`WebPerl.pm` will be imported automatically. If you want to customize the import
list, then add `use WebPerl ...;` as one of the first five lines of your Perl code
(to be exact, WebPerl will look for `/^\s*use\s+WebPerl(\s|;)/m`).

If you don't have any such script tags in the document, Perl won't be run
automatically, and you can control Perl in detail via the JavaScript `Perl`
object provided by [webperl.js](#webperl.js).

Note that unlike JavaScript, which is run immediately, WebPerl will always be loaded
and run asynchronously from the page load. If you use `<script type="text/perl">` tags,
these will always be run after the document is ready, and if you use the `Perl` object
as described below, you will have control over when Perl is initialized and run, but
it will still be asynchronous because files need to be fetched from the server.


The Perl Interpreter and its Environment
----------------------------------------

The `perl` compiled for WebPerl is mostly a standard build of Perl, except
for a few patches to make things compile properly, and the major differences
described here.

[Emscripten](http://emscripten.org/) provides emulation for a number of system
calls, most notably for WebPerl, it provides a virtual filesystem from which Perl can
load its modules, since of course JavaScript in the browser is a sandboxed
environment (no access to hardware, the local filesystem, etc.).
However, because Perl is the *only* Emscripten process running in the browser,
there are **several things that won't work** either because Emscripten doesn't
support them (yet) or because they are simply not possible in this
single-process environment:

- Running other programs via e.g. `system`, backticks (`qx`), piped `open`, etc.
- No `fork` or multithreading, no `kill`, `wait`, `waitpid`, etc.
	- There is experimental support for pthreads, but this is not tested with WebPerl yet.
	  See also <http://kripken.github.io/emscripten-site/docs/porting/pthreads.html>.
- No signals (except `SIGALRM`)

Like many UI frameworks, scripting in the browser is usually **asynchronous and event-driven**.
In addition, in Emscripten it is currently not easy to run a program multiple times.
In order to better support these circumstances, WebPerl's C `main()` function has been
patched to *not* end the runtime. This means that once the main Perl script is run,
the interpreter is *not* shut down, meaning `END` blocks and global destruction are not run,
and instead control is passed back to the browser.

This way, you can write Perl in an event-driven manner: in your main code, you can register
callbacks as event handlers for events such as button clicks, network communication, etc., and
then control is passed back to the browser. When the events occur, your Perl callbacks will be run.

In order to allow for this mode of execution, WebPerl is built with Emscripten's
`NO_EXIT_RUNTIME` option enabled. When this option is enabled, `atexit` handlers are
not supported, and calls to `exit` will result in a warning. For this reason, WebPerl
is patched to not call `exit` when the exit code is zero. As a result of all this,
in your scripts, I strongly recommend you **don't use Perl's `exit;`/`exit(0);`**,
as it will not likely do what you want.

Remember that in the browser, the user may leave a page at any time, and there is little
a script can do to prevent this. Although it's possible to ask Perl to end early as follows,
I would still recommend that you **don't rely on `END` blocks or global destruction**.
If your program is doing things like saving files (e.g. via an asynchronous network request),
then you should provide some kind of feedback to your user to know that a process is still
going on, and possibly install your own "beforeunload" handler.

WebPerl includes a C function `int emperl_end_perl()` which will perform the normal
Perl interpreter shutdown (but as mentioned above, not call `exit` if the exit code is zero).
This function is accessible in several ways:

- From JavaScript, set `Perl.endAfterMain` before calling `Perl.init()`
  (this enables a "hack" that calls `emperl_end_perl()` after `main()` returns)
- From JavaScript, call `Perl.end()`
- From Perl, call `WebPerl::end_perl()`

These options might be useful if you're porting an existing script to run in WebPerl.

(In addition, WebPerl currently registers an "beforeunload" handler that attempts to call
the "end" function, but since this will be happening as the page is being unloaded,
do *not* rely on this being able to do very much, or even being called at all!)

### Memory Management and Anonymous `sub`s

**Anonymous `sub`s passed from Perl to JavaScript must be explicitly freed**
**when you are done using them, or else this is a memory leak.**
Please read this section!

When JavaScript arrays, objects, and functions are passed to Perl, they are not
copied, instead they are given an ID and placed in a table so that when Perl
wants to access them, it only needs to remember the ID, and pass the ID and the
corresponding operation to JavaScript. In JavaScript, these objects are kept alive
because of the entry in the table. Once the object goes out of scope in Perl,
its `DESTROY` method lets JavaScript know that it can free that entry from the
table, so JavaScript is free to garbage collect it if there are no other references.

When Perl values are passed to JavaScript, they are generally copied, except
for anonymous `sub`s, where a mechanism similar to the above is used, and a reference
to the `sub`s is kept alive using a table in Perl. *However,* JavaScript has
no equivalent of the `DESTROY` method, which means that even if you are done
using a `sub` in JavaScript, Perl will not know when it can free the table
entry, unless you explicitly tell it to!

WebPerl provides two mechanisms for freeing `sub`s:

- `WebPerl::unregister()` (can be exported), which takes a single argument that is
  a reference to an anonymous sub previously passed to JavaScript. If you
  `use 5.028;` or `use feature 'current_sub';`, anonymous `sub`s can refer to
  themselves using the special `__SUB__` identifier, so for example, you can say:
  
      use 5.028;
      js( sub {
          print "I was called, now I am going away\n";
          WebPerl::unregister(__SUB__);
      } )->();
  
- `WebPerl::sub_once` aka `WebPerl::sub1` are wrappers for `sub`s that essentially
  call the `sub` once and then immediately `unregister` it. The above example can be
  written as:
  
      use WebPerl qw/js sub1/;
      js( sub1 { print "Single-use sub called\n"; } )->();
  
  `unregister` is still useful for anonymous `sub`s that need to be called multiple
  times before falling out of use.

Of course, it is often the case that anonymous `sub`s need to persist for the
entire run of a program (like for example click handlers for buttons), or that
you may only have a handful of anonymous `sub`s in your program overall.
In such cases, you probably don't need to `unregister` them. However, there are
cases where this is very important to keep in mind - for example anonymous
`sub`s generated via stringy `eval`s.

If you want to check how many anonymous `sub`s are registered, you can say
`print scalar(keys %WebPerl::CodeTable);` (*do not* modify this hash).

Note that the above only applies to *anonymous* `sub`s. `sub`s that exist
in Perl's symbol table will persist in Perl's memory anyway, and no table entry
is generated for them, because it is assumed you won't delete them from the
symbol table - so please don't do that. Also, don't rename or redefine `sub`s
after having passed them to JavaScript, as that will probably cause mysterious behvaior.

### Virtual File System

Emscripten provides a virtual file system that also provides a few "fake" files such
as `/home/web_user`, `/dev`, and others, so that it resembles a normal *NIX file system.
Perl's libraries (`*.pm`) are installed into this virtual file system at `/opt/perl`.
Note that because the `perl` binary is compiled to WebAssembly and XS libraries
statically linked into it, you won't find any `perl` binary or library files in the
virtual file system, or for that matter any other binaries, since this is a
single-process environment.

The virtual filesystem is reloaded every time WebPerl is reloaded, so any changes are lost!
The exception is the "`IDBFS`", which stores files in an `IndexedDB`, so they persist
in the browser's storage across sessions. WebPerl mounts an instance of this filesystem
at `/mnt/idb`, and if you want to store files there, you **must** also use Emscripten's
`FS.syncfs()` interface after writing files, for example:

    js(q/ FS.syncfs(false, function (err) {
    	if(err) alert("FS sync failed: "+err);
    	else console.log("FS sync ok"); }); /);

Remember that users may clear this storage at any time as well,
so it is not really a permanent storage either.

Additional information may be found at:

- <http://kripken.github.io/emscripten-site/docs/porting/files/file_systems_overview.html>
- <http://kripken.github.io/emscripten-site/docs/api_reference/Filesystem-API.html>
- <http://kripken.github.io/emscripten-site/docs/api_reference/advanced-apis.html#advanced-file-system-api>

The "mini IDE" included with WebPerl includes some code to show possibilities
of getting and sending files from/to the user through the browser. You also have
the possibility of implementing an RPC mechanism to access local files, if you need to.

Note that WebPerl's build process strips any POD from the Perl libraries, to reduce download size.


webperl.js
----------

`webperl.js` provides a JavaScript object `Perl` that can be used to control
the Perl interpreter. Many properties of this object are intended for internal
use by WebPerl only, so please **only use the interface documented here**.

### Controlling Perl

As documented above, if your HTML file contains `<script type="text/perl">`
tags, these will be run automatically, so you should *not* use `Perl.init()`
and `Perl.start()` in this case.

#### `Perl.init(function)`

Initializes the Perl interpreter (asynchronously fetches the `emperl.*` files).
You should pass this function a callback function, which is to be called when
Perl is ready to be run - normally you would call `Perl.start()` from this callback.

#### `Perl.start(argv)`

Runs Perl with the given `argv` array. If `argv` is not provided, uses Emscripten's
`Module.arguments`, which currently defaults to `['--version']`.

#### `Perl.eval(code)`

Evaluates the given Perl code. Currently always returns a string.

The functionality of this function *may* be expanded upon in the future
to return more than just a string. See the discussion in
[Mappings from Perl to JavaScript](#mappings-from-perl-to-javascript).

#### `Perl.end()`

Ends the Perl interpreter. See the discussion under
["The Perl Interpreter and its Environment"](#the-perl-interpreter-and-its-environment)
for details.

### Options

#### `Perl.output`

Set this to a `function (str,chan) {...}` to handle Perl writing to `STDOUT` or `STDERR`.
`str` is the string to be written, which may consist of a single character, a whole
line, or multiple lines. `chan` will be either 1 for `STDOUT` or 2 for `STDERR`.
If you want to merge the two streams, you can simply ignore the `chan` argument.
Defaults to an implementation that line-buffers and logs via `console.log()`,
prefixing either `STDOUT` or `STDERR` depending on the channel.
See also `Perl.makeOutputTextarea`, which installs a different output handler.

#### `Perl.endAfterMain`

If set to `true` before calling `Perl.init()`, then WebPerl will automatically
end the Perl interpreter after it finishes running the main script. See the
discussion under
["The Perl Interpreter and its Environment"](#the-perl-interpreter-and-its-environment).
Defaults to `false`.

#### `Perl.trace`

Enable this option at any time to get additional trace-level output
to `console.debug()`. Defaults to `false`.

#### `Perl.stateChanged`

Set this to a `function (from,to) {...}` to handle state changes of the Perl interpreter.
Defaults to a simple implementation that logs via `console.debug()`.

### Utility Functions

#### `Perl.makeOutputTextarea(id)`

This function will create a new DOM `<textarea>` element, set up a `Perl.output`
handler that redirects Perl's output into the `<textarea>`, and return the
DOM element. You may optionally pass this function a string argument giving
a DOM ID. You will need to add the `<textarea>` to your DOM yourself
(see `webperl_demo.html` for an example).


WebPerl.pm
----------

`WebPerl.pm` provides the Perl side of the WebPerl API.
Its central function is `js()`, documented below.
It also provides the functions `unregister`, `sub_once`, and `sub1`
(the latter two are aliases for each other), which are documented
in ["Memory Management and Anonymous `sub`s"](#memory-management-and-anonymous-subs).
For convenience, it can also re-export `encode_json`, so you can
request it directly from `WebPerl` instead of needing to `use` another module.
All functions are exported only on request.

Note that WebPerl will also enable autoflush for `STDOUT`.

### `js()`

This function takes a single string argument consisting of JavaScript code to
run, uses JavaScript's `eval` to run it, and returns the result, as follows.

You may also pass an arrayref, hashref, or coderef, and this data structure
will be passed to JavaScript, and a corresponding `WebPerl::JSObject` returned.
Other references, including objects, are currently not supported.

### Mappings from JavaScript to Perl

If the code given to `js()` throws a JavaScript error, `js()` will `die`.
Otherwise, the `js()` function will return:

- JS `undefined` becomes Perl `undef`
- JS booleans become Perl's "booleans" (`!0` and `!1`)
- JS numbers and strings become Perl numbers and strings (values are copied)
- JS "Symbol"s currently cause a warning and and `js()` returns `undef`
- JS functions, objects (hashes), and arrays are returned as
  Perl objects of the class `WebPerl::JSObject`.

### `WebPerl::JSObject`

A `WebPerl::JSObject` is a thin wrapper around a JavaScript object.
The contents of the JavaScript object are not copied to Perl, they are kept in
JavaScript and accessed only when requested from Perl.

`JSObject`s support overload array, hash, and code dereferencing, plus
autoloaded method calls. This means that if you have a `WebPerl::JSObject`
stored in a Perl scalar `$foo` pointing to a JavaScript object `foo`:

- Perl `$foo->{bar}` is the equivalent of JavaScript `foo["bar"]`
- Perl `$foo->[42]` is the equivalent of JavaScript `foo[42]`
- Perl `$foo->("arg")` is the equivalent of JavaScript `foo("arg")`
- Perl `$foo->bar("arg")` is the equivalent of JavaScript `foo.bar("arg")`

`JSObject`s provide the following methods:

- `hashref` is the method behind hashref overloading. It returns a reference
  to a tied hash which accesses the underlying JavaScript object. The tied
  hash should behave like a normal Perl hash, except that all operations
  on it are passed to JavaScript.
- `arrayref` is the method behind arrayref overloading. It returns a reference
  to a tied array which accesses the underlying JavaScript array. The tied
  array should behave like a normal Perl array, except that all operations
  on it are passed to JavaScript.
- `coderef` is the method behind coderef overloading. It returns a reference
  to a `sub` that, when called, calls the underlying JavaScript function.
- `methodcall` is the method behind method autoloading. Its first argument is
  the name of the method, and the further arguments are arguments to the method.
- `toperl` is a method that translates the object from a `JSObject` into a
  regular Perl data structure (deep copy). Note that JavaScript functions are
  kept wrapped inside anonymous Perl `sub`s.

Method autoloading will of course not work for JavaScript methods that have
the same name as existing Perl methods - these are the above methods,
plus methods named `AUTOLOAD`, `DESTROY`, plus any methods inherited from Perl's
[`UNIVERSAL`](http://perldoc.perl.org/UNIVERSAL.html) class, such as `can` or `isa`.
If you need to call JavaScript methods with any of these names,
use `methodcall`. For example, `$jsobject->methodcall("can", "arg1")` will call
the JavaScript method `can` instead of the Perl method `can`.

Arguments from Perl to JavaScript function or method calls are mapped as follows.

### Mappings from Perl to JavaScript

Unlike the JavaScript to Perl mappings, values are (currently¹) generally *copied* from
Perl to JavaScript, instead of being *referenced*.
The exceptions are Perl `sub`s and `WebPerl::JSObject`s.

- Perl arrayrefs become JavaScript arrays
- Perl hashrefs become JavaScript objects
- Perl coderefs become JavaScript functions - 
  **Warning:** please see the discussion in
  ["Memory Management and Anonymous `sub`s"](#memory-Management-and-anonymous-subs)!
- Perl `WebPerl::JSObject`s become references to the wrapped JavaScript objects
- Perl numbers/strings are copied to JavaScript via `Cpanel::JSON::XS::encode_json`
  (with its `allow_nonref` option enabled). This means that the choice
  for whether to encode a Perl scalar as a JavaScript number or string is
  left up to the module, and is subject to the usual ambiguities when
  serializing Perl scalars. See
  [the `Cpanel::JSON::XS` documentation](https://metacpan.org/pod/Cpanel::JSON::XS).
- Other references, including objects, are currently not supported.

¹ So far, the focus of WebPerl has been to replace JavaScript with Perl, and
therefore on accessing JavaScript from Perl, and not as much the other
way around, that is, doing complex things with Perl from JavaScript code.
For example, currently, `Perl.eval()` always returns a string, but could in the
future be extended to return more than that, similar to `WebPerl::js()`,
and then the passing of Perl values to JavaScript could be accomplished
differently as well.


***

Additional notes on using WebPerl may be found in the
[GitHub Wiki](https://github.com/haukex/webperl/wiki/Using-WebPerl).

***

Copyright (c) 2018 Hauke Daempfling (haukex@zero-g.net)
at the Leibniz Institute of Freshwater Ecology and Inland Fisheries (IGB),
Berlin, Germany, <http://www.igb-berlin.de>

Please see the ["Legal" page](legal.html) for details.

***

You can find the source for this page at
<https://github.com/haukex/webperl/blob/gh-pages/using.md>

