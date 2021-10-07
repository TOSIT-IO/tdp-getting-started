#!bin/bash

###
# Bash script to setup environment for deploying
# virtual TDP cluster using the TDP-getting-started repo
###

# Process count for vagrant up command
vagrant_up_process_count=$1 # The higher the value, the faster but more prone to error the deployment

# Vagrant up (vagrant_up_process_count defines xargs process count)
vagrant status | awk 'BEGIN{ tog=0; } /^$/{ tog=!tog; } /./ { if(tog){print $1} }' | \
  xargs -P"${vagrant_up_process_count}" -I {} vagrant up {} 2>&1 | tee -a logs/vagrant.log
