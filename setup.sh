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

# Install pip requirements
pip install jmespath

# Process count for vagrant up command
vagrant_up_process_count=$1 # The higher the value, the faster but more prone to error the deployment

# Vagrant up (vagrant_up_process_count defines xargs process count)
vagrant status | awk 'BEGIN{ tog=0; } /^$/{ tog=!tog; } /./ { if(tog){print $1} }' | \
  xargs -P"${vagrant_up_process_count}" -I {} vagrant up {} 2>&1 | tee -a logs/vagrant.log
