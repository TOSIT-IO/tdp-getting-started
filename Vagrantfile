cluster={
"worker-01"=>{:ip=>"192.168.34.10",:cpus=>2,:mem=>2048},
"worker-02"=>{:ip=>"192.168.34.11",:cpus=>2,:mem=>2048},
"worker-03"=>{:ip=>"192.168.34.12",:cpus=>2,:mem=>2048},
"master-01"=>{:ip=>"192.168.34.13",:cpus=>2,:mem=>2048},
"master-02"=>{:ip=>"192.168.34.14",:cpus=>2,:mem=>2048},
"master-03"=>{:ip=>"192.168.34.15",:cpus=>2,:mem=>2048},
}

Vagrant.configure("2") do |config|

  cluster.each_with_index do |(hostname, info), index|

    config.vm.define hostname do |cfg|
      cfg.vm.provider :virtualbox do |vb, override|
        config.vm.box = "centos/7"
        override.vm.network "private_network", ip: "#{info[:ip]}" # Directory sync fails without this
        vb.name = hostname
        vb.customize ["modifyvm", :id, "--memory", info[:mem], "--cpus", info[:cpus], "--hwvirtex", "on"]
      end # end provider

      # Private key SSH auth config
      config.vm.provision "shell", inline: <<-SHELL
      cat /vagrant/files/tdp-getting-started-rsa.pub >> /home/vagrant/.ssh/authorized_keys
      SHELL
      
      config.vm.provision "shell", inline: <<-EOC
      sudo sed -i -e "\\#PasswordAuthentication yes# s#PasswordAuthentication yes#PasswordAuthentication no#g" /etc/ssh/sshd_config
      sudo systemctl restart sshd.service
      EOC

      # Install core VM components
      config.vm.provision "normalize", type: "ansible_local" do |ansible|
        ansible.playbook = "provision/shared-provisioning-base.yml"
      end
    end # end config
  end # end cluster
end
