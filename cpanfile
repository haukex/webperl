
# Install the dependencies for "web" via:
# $ cpanm --installdeps .

requires 'Cpanel::JSON::XS';
requires 'Plack';
requires 'Plack::Middleware::CrossOrigin';
requires 'Plack::Middleware::Auth::Digest';
