#!/bin/sh -e
BZ_VERSION=4.0.2
BZ_ROOT=/srv/www/bugzilla-$BZ_VERSION

echo "Installing required packages"
zypper in \
    apache2-mod_fcgid \
    perl-Array-Diff \
    perl-File-Slurp \
    perl-XML-Writer \
    perl-Text-CSV_XS \
    perl-DateTime-Format-ISO8601 \
    perl-FCGI \
    perl-Catalyst-Action-RenderView \
    perl-Catalyst-Action-REST \
    perl-Catalyst-Plugin-Static-Simple \
    perl-Catalyst-Plugin-ConfigLoader \
    mercurial

echo
echo "Installing extra perl modules"
cpan BZ::Client Catalyst::Plugin::Log::Handler Slurp Data::Walk


cd /srv/www
echo
echo "Fetching BZ REST API"
hg clone http://hg.mozilla.org/webtools/bzapi bzapi

echo
echo "Installing the BZ extension"
cp -r bzapi/extension/BzAPI $BZ_ROOT/extensions/

echo
echo "Configuring REST API"
cat > bzapi/bugzilla_api.conf << EOF
bugzilla_url http://localhost:85/
bugzilla_version 4.0
bugzilla_timezone Europe/London
<Log::Handler>
  filename /srv/www/bzapi/log/bzapi.log
  fileopen 1
  mode     append
  newline  1
</Log::Handler>
log_xmlrpc 0
log_bzclient 0
name Bugzilla::API
EOF

mkdir /srv/www/bzapi/log
chown wwwrun /srv/www/bzapi/log

cat > /etc/apache2/vhosts.d/bz_rest.conf << EOF
Listen 86
<VirtualHost *:86>
  <IfModule mod_fcgid.c>
    Alias /rest_api/ /srv/www/bzapi/script/bugzilla_api_fastcgi.pl/
    <Location /rest_api/>
      Options ExecCGI
      Order allow,deny
      Allow from all
      AddHandler fcgid-script .pl
    </Location>
  </IfModule>
</VirtualHost>
EOF


echo
echo "Modifying /etc/sysconfig/apache2"
sed -e "/^APACHE_MODULES.*/ s/\"$/ fcgid\"/" -i'.bz_old' /etc/sysconfig/apache2
diff /etc/sysconfig/apache2 /etc/sysconfig/apache2.bz_old
if [ $? -eq 0 ]; then
    rm /etc/sysconfig/apache2.bz_old
else
    echo "Backup in /etc/sysconfig/apache2.bz_old"
fi


echo
echo "Restarting Apache"
rcapache2 restart

echo
echo "Testing"
EXPECT='{"error":1,"code":100,"message":"Invalid Bug Alias"}'
RESULT=$(curl -s http://localhost:86/rest_api/bug/-1)
if [ "$RESULT" = "$EXPECT" ]; then
    echo "Success!"
else
    echo "Failed"
    echo "Expected: $EXPECT"
    echo "Received: $RESULT"
fi
