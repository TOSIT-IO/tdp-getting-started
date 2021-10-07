#!bin/bash

###
# Bash script to setup environment for deploying
# virtual TDP cluster using the TDP-getting-started repo
###

# Create directories
mkdir -p ./logs 
mkdir -p ./files
mkdir -p ./ansible_roles

# Create log files
touch ./logs/vagrant.log 
touch ./logs/tdp.log

# Clone ansible-tdp-roles repository (doesn't fail iof not known host)
git clone -o StrictHostKeyChecking=no git@github.com:TOSIT-FR/ansible-tdp-roles.git ansible_roles/collections/ansible_collections/tosit/tdp/
