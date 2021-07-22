# Getting Started with TDP

Launch various virtual TDP big data infrastructures in less than 10 commands.

## Available Deployments

- `zookeeper quorum`: deploys, configures and starts Apache ZooKeeper to 3 virtual machines

# Steps To Deployment
- Provision the virtual machines using vagrant and virtual box:
    `ansible-playbook -vvvv spawn-vms.yml`
- Deploy a three node Apache Zookeeper Quorum
    `ansible-playbook -vvvv deploy-zookeeper.yml -K`

##  Control-node environment [for reference - not necessaeily system requirements]

- Ubuntu 20.04.2 LTS 64-bit
- Vagrant 2.2.9
- ansible core version 2.11.2
- VirtualBox version 6.1
- Python 3.8.10

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
