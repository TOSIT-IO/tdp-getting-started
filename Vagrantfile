cluster={
  "worker-01.tdp"=>{:ip=>"192.168.32.10",:cpus=>2,:mem=>2048},
  "worker-02.tdp"=>{:ip=>"192.168.32.11",:cpus=>2,:mem=>2048},
  "worker-03.tdp"=>{:ip=>"192.168.32.12",:cpus=>2,:mem=>2048},
  "master-01.tdp"=>{:ip=>"192.168.32.13",:cpus=>2,:mem=>2048},
  "master-02.tdp"=>{:ip=>"192.168.32.14",:cpus=>2,:mem=>2048},
  "master-03.tdp"=>{:ip=>"192.168.32.15",:cpus=>2,:mem=>2048},
  "edge-01.tdp"=>{:ip=>"192.168.32.16",:cpus=>2,:mem=>2048},
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
        config.vm.synced_folder "./", "/vagrant", type: "rsync", rsync__auto: true, rsync__exclude: ['files/*.tar.gz', 'files/*.tgz', 'collections/', 'group_vars/', 'logs/', 'roles/']
      end # end provider
    end # end config
  end # end cluster
end
