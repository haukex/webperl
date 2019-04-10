
WebPerl Advanced GUI Example
============================

Similar to the "WebPerl Basic GUI Example", this is a demo of a GUI
using WebPerl, but using [Bootstrap](https://getbootstrap.com/)
and [jQuery](https://jquery.com/) instead of plain JavaScript,
and [Mojolicious](https://mojolicious.org/) instead of plain Plack.

To get this to work, you will need to copy the `webperl.js` and the
three `emperl.*` files from the main `web` directory to the `public`
subdirectory in this project.

Also, a limitation is that the server does not know when the browser
window is closed, so it must be stopped manually.

You can pack this application into a single executable using `do_pp.pl`.
Note: I'm not yet sure why, but sometimes this fails with errors such
as *"error extracting info from -c/-x file"*, in that case just try
the command again.


Author, Copyright, and License
==============================

**WebPerl - <http://webperl.zero-g.net>**

Copyright (c) 2019 Hauke Daempfling (haukex@zero-g.net)
at the Leibniz Institute of Freshwater Ecology and Inland Fisheries (IGB),
Berlin, Germany, <http://www.igb-berlin.de>

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself: either the GNU General Public
License as published by the Free Software Foundation (either version 1,
or, at your option, any later version), or the "Artistic License" which
comes with Perl 5.

This program is distributed in the hope that it will be useful, but
**WITHOUT ANY WARRANTY**; without even the implied warranty of
**MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE**.
See the licenses for details.

You should have received a copy of the licenses along with this program.
If not, see <http://perldoc.perl.org/index-licence.html>.
