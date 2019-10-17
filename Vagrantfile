# -*- mode: ruby -*
# vi: set ft=ruby :

#IP_srv = "192.168.56.141"
#IP_ag = "192.168.56.142"
#IP_ag2 = "192.168.56.144"


BOX_IMAGE = "sbeliakou/centos"

[["zabbix-srv100","192.168.56.151"], ["zabbix_ag101","192.168.56.152"]].each do |te|


 Vagrant.configure("2") do |config|

    config.vm.define te[0] do |subconfig|
      subconfig.vm.box = BOX_IMAGE
      subconfig.vm.hostname = te[0]
      subconfig.vm.network :private_network, ip: te[1]
      subconfig.vm.provider "virtualbox" do |vb|
        vb.name = te[0]
        vb.memory = "1024"
      end
      subconfig.vm.provision "shell", path: "provision.sh"
    end

 end

end