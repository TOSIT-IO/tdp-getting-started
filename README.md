# Getting Started with TDP

Launch various virtual TDP big data infrastructures in less than 10 commands.

## Available Deployments

- `zookeeper quorum`: deploys, configures and starts Apache ZooKeeper to 3 virtual machines
## System Requirements (control node should also be created by vagrant to remove this)

Tested using Ubuntu 20.04.2 LTS 64-bit as the Ansible control node ansd the following:

- Vagrant 2.2.9
- ansible core version 2.11.2
- VirtualBox version 6.1
- Python 3.8.10

## Accessing launched VMs

```bash
# SSH to nodes using ssh
ssh -i 'files/tdp-getting-started-rsa' vagrant@<target-ip>
# Or alternatively using the vagrant CLI
vagrant ssh <tdp-hosts access_fqdn>
```

## Control node setup

```bash
# Clone TDP installation ansible roles
git clone http://gitlab.adaltas.com/tosit/tdp-getting-started.git 
cd tdp-getting-started

# Generate and prepare deployment ssh keys
mkdir files
ssh-keygen -t rsa  -b 2048 -f files/tdp-getting-started-rsa -P "" -C "tdp-getting-started"
chmod 600 files/tdp-getting-started-rsa
chmod 600 files/tdp-getting-started-rsa.pub

# Clone and position TDP ansible roles
mkdir -p collections/ansible_collections/tosit
git clone http://gitlab.adaltas.com/tosit/ansible-tdp-roles.git collections/ansible_collections/tosit/tdp

# Create log file
mkdir logs && touch logs/tdp-getting-started.log
```

# Deployments

## Launch a 3 node Zookeeper Quorum
```bash
# Download zookeeper binary
wget https://archive.apache.org/dist/zookeeper/zookeeper-3.4.6/zookeeper-3.4.6.tar.gz -P files
# Launch VMs and deploy Zookeeper
ansible-playbook deploy-zookeeper.yml -K
# Verify nodes are responsive
ansible -i tdp-hosts all -u vagrant -m ping
# Verify zookeeper running on each node
for i in {1..3}; do
vagrant ssh zk-server-0${i}.local -c "ps -aux | grep zookeeper"
done
```
