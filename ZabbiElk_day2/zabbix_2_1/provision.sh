#!/bin/bash
DBpass='zabbix'
IP_srv="192.168.56.21"
IP_ag="192.168.56.22"
HOSTNAME_ag="zabbix-ag21"

function install_srv(){
DBpass='zabbix'
#if ! yum list installed zabbix-server-pgsql
#then
sudo rpm -Uvh https://repo.zabbix.com/zabbix/4.4/rhel/7/x86_64/zabbix-release-4.4-1.el7.noarch.rpm
sudo  yum clean all 
sudo yum -y install zabbix-server-pgsql zabbix-web-pgsql zabbix-apache-conf zabbix-agent zabbix-get zabbix-java-gateway

sudo yum -y install postgresql-server postgresql-contrib
sudo yum -y install mc
#fi
sudo postgresql-setup initdb
sudo systemctl start postgresql
sudo systemctl enable postgresql
# read -p "posgress started. press x" x
sudo -u postgres createuser zabbix
#sudo -i -p -u postgres psql -c "CREATE USER zabbix WITH PASSWORD $DBpass";
sudo -E -p -u postgres psql -c "ALTER USER zabbix WITH PASSWORD $DBpass";
#sudo -u postgres psql -c "ALTER USER zabbix WITH PASSWORD 'zabbix'";
sudo -u postgres createdb -O zabbix zabbix
echo '
# TYPE DATABASE USER ADDRESS METHOD
host zabbix zabbix 127.0.0.1/32 password
host zabbix zabbix ::1/128 password
  
   # "local" is for Unix domain socket connections only
local all all ident
    # IPv4 local connections:
host all all 127.0.0.1/32 ident
     # IPv6 local connections:
host all all ::1/128 ident
'>/var/lib/pgsql/data/pg_hba.conf
sudo systemctl restart postgresql
# read -p "createuser, createDB .    press x" x
zcat /usr/share/doc/zabbix-server-pgsql*/create.sql.gz | sudo -u zabbix psql zabbix 
#echo '
#DBPassword=$DBpass
#> 

sudo -E sed -i.bak "s/# DBPassword=.*/DBPassword=$DBpass/" /etc/zabbix/zabbix_server.conf
#sed -i.bak 's/# php_value date.timezone Europe/Riga/php_value date.timezone Europe\/Minsk/' /etc/httpd/conf.d/zabbix.conf
sudo sed -i.bak 's/# php_value date.timezone.*/php_value date.timezone Europe\/Minsk/' /etc/httpd/conf.d/zabbix.conf
sudo sed -i.bak '/DocumentRoot/a RedirectMatch ^/$ /zabbix/' /etc/httpd/conf/httpd.conf

sudo -E sed -i.bak "s/# JavaGateway=.*/JavaGateway=$IP_srv/" /etc/zabbix/zabbix_server.conf
sudo -E sed -i.bak "s/# JavaGatewayPort=.*/JavaGatewayPort=10052/" /etc/zabbix/zabbix_server.conf
sudo -E sed -i.bak "s/# StartJavaPollers=.*/StartJavaPollers=5/" /etc/zabbix/zabbix_server.conf


sudo systemctl restart zabbix-server zabbix-agent httpd zabbix-java-gateway
sudo systemctl enable zabbix-server zabbix-agent httpd zabbix-java-gateway

}


function install_ag(){
sudo rpm -Uvh https://repo.zabbix.com/zabbix/4.4/rhel/7/x86_64/zabbix-release-4.4-1.el7.noarch.rpm
sudo yum -y install zabbix-agent zabbix-sender tomcat mc tomcat-webapps wget
echo "#Server=[zabbix server ip]
#Hostname=[ Hostname of client system ]
Server=$IP_srv
Hostname=$HOSTNAME_ag
ListenPort=10050
ListenIP=0.0.0.0
StartAgents=3
LogFile=/var/log/zabbix/zabbix_agentd.log
PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFileSize=0
DebugLevel=3
"> /etc/zabbix/zabbix_agentd.conf
sudo systemctl restart zabbix-agent tomcat
sudo systemctl enable zabbix-agent tomcat

if ! grep "^JAVA_OPTS" /etc/tomcat/tomcat.conf
then
sudo -E echo "
JAVA_OPTS=-Dcom.sun.management.jmxremote=true \
-Dcom.sun.management.jmxremote.port=12345 \
-Dcom.sun.management.jmxremote.rmi.port=12346 \
-Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false \
-Djava.rmi.server.hostname=$IP_ag ">>/etc/tomcat/tomcat.conf
fi



#sudo -u tomcat cd /usr/share/tomcat/lib
sudo -u tomcat wget -p /usr/share/tomcat/lib  http://repo2.maven.org/maven2/org/apache/tomcat/tomcat-catalina-jmx-remote/7.0.76/tomcat-catalina-jmx-remote-7.0.76.jar
#sudo cp /tmp/tomcat-catalina-jmx-remote-7.0.96.jar /usr/share/java/tomcat/

#sudo -u tomcat cd  /usr/share/tomcat/webapps
sudo -u tomcat wget -p /usr/share/tomcat/webapps https://tomcat.apache.org/tomcat-7.0-doc/appdev/sample/sample.war
#sudo cp /tmp/sample.war /usr/share/tomcat/webapps


if ! grep "rmiRegistryPortPlatform" /etc/tomcat/tomcat.conf
then
sudo -E sed -i.bak '/seThreadLocalLeakPreventionListener/a \
 <Listener className="org.apache.catalina.mbeans.JmxRemoteLifecycleListener"
 rmiRegistryPortPlatform="8097"
 rmiServerPortPlatform="8098"
 />
'

fi
}

IP=`hostname -I |awk '{print $2}'|awk -F "." '{print $4}'`

case $IP in
        21)      
          install_srv
          ;;
        22)      
          install_ag
          ;;
        *)
          echo "I don\`t inderstand"
          ;;
esac

