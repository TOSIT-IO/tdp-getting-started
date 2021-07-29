# Getting Started with TDP

Launch various virtual TDP big data infrastructures in less than 10 commands.

## Available Deployments

- `KDC`: deploys and configures a Kerberos KDC

- `zookeeper quorum`: deploys, configures and starts Apache ZooKeeper to 3 virtual machines

# Steps To Deployment

- Provision VMs and gerenate/clone necessary structure and dependencies:
    `ansible-playbook launch_infrastructure.yml`

- Deploy a KDC and install configured kerberous clients on the VMs

    `ansible-playbook kerborize-cluster.yml`

- Deploy a three node Apache Zookeeper Quorum

    `ansible-playbook deploy-zookeeper.yml`

- Create a certificate authority a download generated certs to files

    `ansible-playbook deploy-ca.yml`

##  Control-node environment [for reference - not necessaeily system requirements]

- Ubuntu 20.04.2 LTS 64-bit
- Vagrant 2.2.9
- ansible core version 2.11.2
- VirtualBox version 6.1
- Python 3.8.10
