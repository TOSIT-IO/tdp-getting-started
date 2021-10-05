#!bin/bash

###
# Bash script to setup environment for deploying
# virtual TDP cluster using the TDP-getting-started repo
###

# Create directories

for d in logs files ansible_roles; do
  mkdir -p ${d}
done

# Create files

for f in logs/vagrant.log logs/tdp.log; do
  touch ${f}
done
