cluster={
  "worker-01.tdp"=>{:ip=>"192.168.32.10",:cpus=>4,:mem=>2048},
  "worker-02.tdp"=>{:ip=>"192.168.32.11",:cpus=>4,:mem=>2048},
  "worker-03.tdp"=>{:ip=>"192.168.32.12",:cpus=>4,:mem=>2048},
  "master-01.tdp"=>{:ip=>"192.168.32.13",:cpus=>4,:mem=>3072},
  "master-02.tdp"=>{:ip=>"192.168.32.14",:cpus=>8,:mem=>3072},
  "master-03.tdp"=>{:ip=>"192.168.32.15",:cpus=>4,:mem=>3072},
  "edge-01.tdp"=>{:ip=>"192.168.32.16",:cpus=>4,:mem=>2048},
}

Vagrant.configure("2") do |config|

  cluster.each_with_index do |(hostname, info), index|

    config.vm.define hostname, autostart: true do |cfg|
      cfg.vm.provider :virtualbox do |vb, override|
        config.vm.box = "centos/7"
        override.vm.network "private_network", ip: "#{info[:ip]}" # Directory sync fails without this
        vb.name = hostname # sets gui name for VM
        config.vm.hostname = hostname
        vb.customize ["modifyvm", :id, "--memory", info[:mem], "--cpus", info[:cpus], "--hwvirtex", "on"]
      end # end provider

      # Install core VM components
      config.vm.provision "normalize", type: "ansible_local" do |ansible|
        ansible.playbook = "provision/shared-provisioning-base.yml"
      end
    end # end config
  end # end cluster
end
