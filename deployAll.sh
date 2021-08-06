#!/bin/bash

# Clean up any previous execution
echo "" > ~/.ssh/known_hosts
vagrant destroy -f
rm -rf files/certs
rm -rf logs

# Launch the playbooks
ansible-playbook deploy_infrastructure.yml
ansible-playbook deploy-ca.yml
ansible-playbook deploy-kerberos.yml
ansible-playbook deploy-zookeeper.yml
ansible-playbook deploy-hdfs-yarn-mapreduce.yml -K

