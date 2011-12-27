#!/bin/sh -e
#
# http://www.bugzilla.org/docs/4.0/en/html/installing-bugzilla.html

# See http://ftp.mozilla.org/pub/mozilla.org/webtools/ for available versions
VERSION=4.0.2

DB_NAME="bugs_$(echo $VERSION| sed -e 's/\./_/g')"

echo "Installing required packages"
# (might not be complete list)
zypper in \
    perl-CGI \
    perl-Email-Send \
    perl-Email-MIME \
    perl-DBD-mysql \
    perl-Template-GD \
    perl-URI \
    perl-DBI \
    perl-DateTime \
    perl-SOAP-Lite \
    perl-Test-Taint \
    perl-JSON-RPC


echo
echo "Fetching and extracting Bugzilla tarball"
cd /srv/www
wget http://ftp.mozilla.org/pub/mozilla.org/webtools/bugzilla-$VERSION.tar.gz -O- | \
    tar -xzv


echo
echo "Creating Apache vhost config"
cat > /etc/apache2/vhosts.d/bz.conf << EOF
Listen 85
<VirtualHost *:85>
  DocumentRoot  "/srv/www/bugzilla-$VERSION"
  <Directory /srv/www/bugzilla-$VERSION>
    AddHandler cgi-script .cgi
    Options +Indexes +ExecCGI
    DirectoryIndex index.cgi
    AllowOverride Limit FileInfo Indexes
    Order allow,deny
    Allow from all
  </Directory>
</VirtualHost>

#Listen 445
#<VirtualHost *:445>
#  DocumentRoot  "/srv/www/bugzilla-$VERSION"
#  <Directory /srv/www/bugzilla-$VERSION>
#    AddHandler cgi-script .cgi
#    Options +Indexes +ExecCGI
#    DirectoryIndex index.cgi
#    AllowOverride Limit FileInfo Indexes
#    Order allow,deny
#    Allow from all
#  </Directory>
#  SSLEngine on
#  SSLProtocol all -SSLv2 -SSLv3
#  SSLCipherSuite ALL:!aNULL:!eNULL:!SSLv2:!LOW:!EXP:!MD5:@STRENGTH
#  SSLCertificateFile /srv/obs/certs/server.crt
#  SSLCertificateKeyFile /srv/obs/certs/server.key
#</VirtualHost>
EOF


echo
echo "Setting up DB, enter mysql root user pw"
mysql -u root -p'opensuse' << EOF
GRANT SELECT, INSERT, UPDATE,
      DELETE, INDEX, ALTER, CREATE, LOCK TABLES,
      CREATE TEMPORARY TABLES, DROP, REFERENCES ON $DB_NAME.*
      TO bugs@localhost IDENTIFIED BY 'bugzill4';
FLUSH PRIVILEGES;
EOF


cd bugzilla-$VERSION
echo
echo "Running './checksetup.pl --check-modules'"
./checksetup.pl --check-modules

echo
echo "Running './checksetup.pl'"
./checksetup.pl

echo
echo "Updating localconfig"
sed -e "s/^\$db_pass.*/\$db_pass = 'bugzill4';/" \
    -e "s/^\$db_name.*/\$db_name = '$DB_NAME';/" \
    -e "s/^\$webservergroup.*/\$webservergroup = 'www';/" \
    -i'.bak' localconfig

echo
echo "Running './checksetup.pl' again to finalize setup"
./checksetup.pl

echo
echo "Restarting apache"
rcapache2 restart

echo
echo "Bugzilla should be now available at http://localhost:85/"
