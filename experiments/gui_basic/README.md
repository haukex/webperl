
WebPerl Basic GUI Example
=========================

This is a demo of a very basic GUI using WebPerl. It consists of a
local web server, which includes code to access an SQLite database,
and this web server also serves up WebPerl code to a browser, where
the GUI is implemented as HTML with Perl.

To get this to work, you will need to copy the `webperl.js` and three
`emperl.*` files from the main `web` directory to the `web`
subdirectory in this project.

Note that this should not be considered production-ready, as there
are several key features missing, such as HTTPS or access control.

Also, a limitation is that the server does not know when the browser
window is closed, so it must be stopped manually.

You can pack this application into a single executable using:

	DOING_PAR_PACKER=1 pp -o gui_basic -z 9 -x -a gui_basic_app.psgi -a web gui_basic.pl

Note: I'm not yet sure why, but sometimes this fails with errors such
as *"error extracting info from -c/-x file"*, in that case just try
the above command again.


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
