#!/bin/bash
DBpass='zabbix'
IP_srv="192.168.56.141"
HOSTNAME_ag="zabbix-ag"

function install_srv(){
DBpass='zabbix'
sudo rpm -Uvh https://repo.zabbix.com/zabbix/4.4/rhel/7/x86_64/zabbix-release-4.4-1.el7.noarch.rpm
sudo  yum clean all 
sudo yum -y install zabbix-server-pgsql zabbix-web-pgsql zabbix-apache-conf zabbix-agent 
sudo yum -y install postgresql-server postgresql-contrib
sudo yum -y install ssmtp
sudo postgresql-setup initdb
sudo systemctl start postgresql
sudo systemctl enable postgresql
# read -p "posgress started. press x" x
#sudo -u postgres createuser --pwprompt zabbix
sudo -i -p -u postgres psql -c "CREATE USER zabbix WITH PASSWORD $DBpass";
#sudo -u postgres psql -c "CREATE USER zabbix WITH PASSWORD zabbix";
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
sed -i.bak 's/DBPassword=.*/DBPassword=$DBpass/' /etc/zabbix/zabbix_server.conf
#sed -i.bak 's/# php_value date.timezone Europe/Riga/php_value date.timezone Europe\/Minsk/' /etc/httpd/conf.d/zabbix.conf
sed -i.bak 's/# php_value date.timezone.*/php_value date.timezone Europe\/Minsk/' /etc/httpd/conf.d/zabbix.conf
sudo systemctl restart zabbix-server zabbix-agent httpd
sudo systemctl enable zabbix-server zabbix-agent httpd 
}


function install_ag(){
sudo rpm -Uvh https://repo.zabbix.com/zabbix/4.4/rhel/7/x86_64/zabbix-release-4.4-1.el7.noarch.rpm
sudo yum -y install zabbix-agent 
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
sudo systemctl restart zabbix-agent
sudo systemctl enable zabbix-agent
}

IP=`hostname -I |awk '{print $2}'|awk -F "." '{print $4}'`

case $IP in
        141)      
          install_srv
          ;;
        142)      
          install_ag
          ;;
        *)
          echo "I don\`t inderstand"
          ;;
esac

