#!/bin/bash

if ! yum list installed jq
then
    sudo yum -y install epel-release
    sudo yum -y install jq
fi
if ! command -v jo
then
    sudo yum install git -y
    cd /tmp
    git clone git://github.com/jpmens/jo.git
    cd jo
    autoreconf -i
    ./configure
    make check
    sudo make install clean
fi



HOSTNAME_ag="zabbix-ag"
#HOSTNAME_ag=`hostname`
ZbUser="Admin"
ZbPass="zabbix"
ZbServerIp='192.168.56.141'
ZBAgentIp='192.168.56.142'
ZbApi="http://$ZbServerIp/api_jsonrpc.php"
ZbGroup='CloudHosts'
ZbPort=10050

authenticate() {
    JsData=`jo jsonrpc=2.0 method=user.login params=$(jo user=$ZbUser password=$ZbPass) auth= null id=0`
    echo `curl -s -H  'Content-Type: application/json-rpc' -d "$JsData" $ZbApi`
}

AUTH_TOKEN=`echo $(authenticate)|jq -r .result`

echo "auth: $AUTH_TOKEN"

echo 11111111111


getgroupid() {
    JsData=`jo jsonrpc=2.0 method=hostgroup.get params=$(jo output=extend filter=$(name=$ZbGroup)) auth=$AUTH_TOKEN id=0`
    echo `curl -s -H 'Content-Type: application/json-rpc' -d "$JsData" $ZbApi`
}
GROUP_ID=`echo $(getgroupid)|jq -r .result[0].grupid`

echo 2222222222222222
echo "group id 1 step :$GROUP_ID"

if test -n "$GROUP_ID"
  then 
  echo 333333333
    echo "start create group id"
    creategroupid() {
    JsData=`jo jsonrpc=2.0 method=hostgroup.create params=$(jo name=$ZbGroup) auth=$AUTH_TOKEN id=0`
    echo `curl -s -H 'Content-Type: application/json-rpc' -d "$JsData" $ZbApi`
    
    
    echo 4444444444
    
    echo "jsData create group: $JsData"
    echo "pered jsdata jq"
    echo "jsdata jq `$JsData|jq`"
    
    }
  else echo "not null"
fi
GROUP_ID=`echo $(getgroupid)|jq -r .result[0].grupid`

echo 5555555
echo "group id 2 step :$GROUP_ID"


createtemplate() {
    JsData=`jo jsonrpc=2.0 method=template.create params=$(jo host="Custom Template" description="Custom Template from Task" groups=$(jo groupid=$ZbGroup)) auth=$AUTH_TOKEN id=0`
    
    echo " createtemp Jsdata: $JsData"
    
    echo `curl -s -H 'Content-Type: application/json-rpc' -d "$JsData" $ZbApi`
}
TEMPL_ID=`echo $(createtemplate)|jq -r result[0].templateids`

createhost() {
    JsData=`jo jsonrpc=2.0 method=host.create params=$(jo host=$HOSTNAME_ag interfaces=$(jo type=1 main=1 useip=1 ip=$ZbAgentIp dns="" port=$ZbPort) groups=$(jo groupid=$GROUP_ID)) templates=$(jo templateid=1001 templateid=$TEMPL_ID) auth=$AUTH_TOKEN id=0`
    
    echo `curl -s -H 'Content-Type: application/json-rpc' -d "$JsData" $ZbApi`
}

gethostid() {
    JsData=`jo jsonrpc=2.0 method=host.get params=$(jo filter=$(host=$HOSTNAME_ag))  auth=$AUTH_TOKEN id=0`
    echo `curl -s -H  'Content-Type: application/json-rpc' -d "$JsData" $ZbApi`
}


#echo $(gethostid)|jq
HOST_ID=`echo $(gethostid)|jq -r .result[0].hostid`

#RESPONSE=$(remove_host)
#echo ${RESPONSE}


echo "group id:$GROUP_ID"
echo "templ id:$TEMPL_ID"


