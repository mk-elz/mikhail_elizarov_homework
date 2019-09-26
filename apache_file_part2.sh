#!/bin/bash

clear


grep mikhail /etc/hosts || sed 's/localhost /localhost www.mikhail.elizarov mikhail.elizarov /' /etc/hosts
user="Mikhail Elizarov"
dir_name="mikhail_elizarov"


systemctl restart httpd

firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --reload

sudo yum -y install epel-release
sudo yum  -y install cronolog



mkdir -p /var/www/$dir_name
chown apache:apache /var/www/$dir_name

mkdir -p /var/www/$dir_name/html
chown apache:apache /var/www/$dir_name/html

touch /etc/httpd/conf.d/httpd-vhost.conf
chown apache:apache /etc/httpd/conf.d/vhost.conf

touch /var/www/$dir_name/error.log
chown apache:apache /var/www/$dir_name/error.log

mkdir -p /var/www/$dir_name/logs
chown apache:apache /var/www/$dir_name/logs


cat <<EOF >/etc/httpd/conf.d/httpd-vhost.conf
<VirtualHost *:80>
    ServerName www.mikhail.elizarov
    ServerAlias mikhail.elizarov
    DocumentRoot /var/www/$dir_name/html
    LogFormat "%h %l %u %t \"%r\" %>s %b" extended_ncsa
    ErrorLog  "| /usr/bin/logger -thttpd -plocal6.err"
    CustomLog "| /usr/bin/logger -thttpd -plocal6.notice" extended_ncsa
#    ErrorLog "| /usr/sbin/cronolog /var/www/$dir_name/logs/error.log.%Y-%m-%d-%H-%m"
#    CustomLog "| /usr/sbin/cronolog  /var/www/$dir_name/logs/requests.log.%Y-%m-%d-%H-%m" combined
    RewriteEngine On
    RewriteRule "/$" "/index.html" [R,L,NC]
    RewriteRule "^/index\.html$" "/ping.html" [R,L,NC]
    RewriteRule ^/ping.html /ping.html [L]
    RewriteRule ^.* - [F]
</VirtualHost>
EOF


systemctl restart httpd
