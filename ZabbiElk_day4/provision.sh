#!/bin/bash
ipSrv='192.168.56.21'
ipAg='192.168.56.22'
##
#               --------Function install server
##
function install_srv(){
#REPO Elastic
#sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
#sudo echo '
#[elasticsearch-7.x]
#name=Elasticsearch repository for 7.x packages
#baseurl=https://artifacts.elastic.co/packages/7.x/yum
#gpgcheck=1
#gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
#enabled=1
#autorefresh=1
#type=rpm-md
# '>/etc/yum.repos.d/elasticsearch.repo

#sudo yum -y install elasticsearch 
  
sudo yum -y install mc
  
if [ -f /vagrant/elasticsearch-7.4.0-x86_64.rpm  ]
 then 
  rpm -Uhvi /vagrant/elasticsearch-7.4.0-x86_64.rpm
 else 
  wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.4.0-x86_64.rpm
#  wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.4.0-x86_64.rpm.sha512
#  shasum -a 512 -c elasticsearch-7.4.0-x86_64.rpm.sha512 
  sudo rpm --install elasticsearch-7.4.0-x86_64.rpm
fi
  
#sudo -E sed -i.bak 's/\#elasticsearch.hosts: ["http://localhost:9200"]/elasticsearch.hosts: ["http://localhost:9200"]/' /etc/kibana/kibana.yml

#######################################
#
#elasticsearch conf 
#
######################################
sudo -E sed -i.bak2 "s/\#network.host:.*/network.host: $ipSrv/"  /etc/elasticsearch/elasticsearch.yml
sudo -E sed -i.bak3 "s/\#http.port: 9200/network.port: 9200/"  /etc/elasticsearch/elasticsearch.yml
if grep transport.host /etc/elasticsearch/elasticsearch.yml
then
  echo "transport.host: localhost" >> /etc/elasticsearch/elasticsearch.yml
fi

 
sudo systemctl restart elasticsearch.service
if [ -f /vagrant/kibana-7.2.1-x86_64.rpm  ]
 then 
    rpm -Uhvi /vagrant/kibana-7.2.1-x86_64.rpm
 else 
   wget https://artifacts.elastic.co/downloads/kibana/kibana-7.2.1-x86_64.rpm
   sudo rpm --install kibana-7.2.1-x86_64.rpm
fi  #sudo yum -y install kibana
########################################
#
#kibana conf 
#
########################################
ipSrv=`hostname -I |awk '{print $2}'`
#if ! grep ^server.host  /etc/kibana/kibana.yml
sudo -E sed -i.bak "/\#server.host/a \
server.host:  $ipSrv" /etc/kibana/kibana.yml

sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable elasticsearch.service
sudo systemctl enable kibana
sudo systemctl start kibana
}
##
#               --------Function install agent
##
function install_ag(){
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
echo '
[logstash-7.x]
name=Elastic repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
'>/etc/yum.repos.d/logstash.repo

sudo yum -y install logstash

echo "
input {
  file {
    path => '/usr/share/tomcat/conf'
    start_position => "beginning"
  }
}

output {
  elasticsearch {
    hosts => [$ipSrv:9200]
  }
  stdout { codec => rubydebug }
}">/etc/logstash/conf.d/logstash-tomcat.conf

echo '
input {
  file {
    path => [ "/var/log/maillog" ]
    type => "syslog"
    start_position => "beginning"
  }
}

filter {
    if [type] == "syslog" {
        grok {
            match => [ "message", "%{HOSTNAME}" ]
        }
    }
}

output {
    elasticsearch { host => localhost }
}
'>/etc/logstash/conf.d/rsyslog.conf

sudo yum -y install  tomcat mc tomcat-webapps wget

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
#sudo chmod -R 755 /var/log/tomcat
usermod -aG tomcat logstash
sudo systemctl enable logstash tomcat
sudo systemctl restart logstash tomcat
usermod -aG tomcat logstash
}
##############end agent function

IP=`hostname -I |awk '{print $2}'|awk -F "." '{print $4}'`

case $IP in
        21)      
          install_srv
          ;;
        22)      
          install_ag
          ;;
        *)
          echo "I don\`t understand"
          ;;
esac

