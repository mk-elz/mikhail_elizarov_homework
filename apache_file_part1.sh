#!/bin/bash

user="Mikhail Elizarov"

for pkg in httpd lynx
do 
 if ! yum list installed $pkg
  then
   yum -y install $pkg && echo "$pkg DONE"
  else echo "$pkg alredy installed"
 fi
done

firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --reload

touch /var/www/html/index.html
chown apache:apache /var/www/html/index.html

cat <<EOF > /var/www/html/index.html
<h2>Hello from httpd</h2>
<hr />
<p>Created by $user</p>
EOF


#3. Start httpd, check httpd syntax with “httpd -S”, open test page in browser, stop httpd service.
httpd -S
systemctl start httpd
systemctl status httpd
curl localhost
#lynx localhost
systemctl stop httpd
#4. Install apache2

if -d /usr/local/apache2
 then rm -rf /usr/local/apache2 &&  mkdir -p /usr/local/apache2
 else mkdir -p /usr/local/apache2
fi

chown -R apache:apache /usr/local/apache2

wget http://ftp.byfly.by/pub/apache.org/httpd/httpd-2.4.41.tar.gz -O /usr/local/apache2/httpd-2.4.41.tar.gz

yum groupinstall " Development Tools"  -y

wget http://ftp.byfly.by/pub/apache.org/httpd/httpd-2.4.41.tar.gz -O /usr/local/apache2/httpd-2.4.41.tar.gz
wget https://github.com/apache/apr/archive/1.6.2.tar.gz -O /usr/local/apache2/apr-1.6.2.tar.gz
wget https://github.com/apache/apr-util/archive/1.6.0.tar.gz -O /usr/local/apache2/apr-util-1.6.0.tar.gz

tar zxf /usr/local/apache2/httpd-2.4.41.tar.gz
tar zxf /usr/local/apache2/apr-1.6.2.tar.gz
tar zxf /usr/local/apache2/apr-util-1.6.0.tar.gz

cd /usr/local/apache2/

mv apr-1.6.2 httpd-2.4.41/srclib/apr
mv apr-util-1.6.0 httpd-2.4.41/srclib/apr-util


cd /usr/local/apache2/httpd-2.4.41

./buildconf 
./configure --prefix=/usr/local/apache2
make
make install

#5. Create test html page /usr/local/apache2/htdocs/index.html
mkdir -p /usr/local/apache2/htdocs
touch /usr/local/apache2/htdocs/index.html
chown -R apache:apache /usr/local/apache2
cat <<EOF > /usr/local/apache2/htdocs/index.html
<h2>Hello from Apache2</h2>
<hr />
<p>Created by $user</p>
EOF
#6. Start apache2, check apache2 syntax with “apachectl -S”, open test page in browser, stop apache2.
#Check
/usr/local/apache2/bin/apachectl -S
/usr/local/apache2/bin/apachectl start
#lynx localhost
/usr/local/apache2/bin/apachectl stop


ss -tulpan |grep ":80" && pkill httpd 2>/dev/null
systemctl start httpd


cat <<EOF > /var/www/html/index.html
<h2>Hello from httpd</h2>
<hr />
<p>Created by $user</p>
EOF


#1. Install cronolog
sudo yum -y install epel-release
sudo yum  -y install cronolog
