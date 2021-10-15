#!/usr/bin/env bash

###
# Bash script to setup environment for deploying
# virtual TDP cluster using the TDP-getting-started repo
###

TDP_ROLES_PATH=ansible_roles/collections/ansible_collections/tosit/tdp

# Create directories
mkdir -p logs
mkdir -p files

# Clone ansible-tdp-roles repository (doesn't fail iof not known host)
[[ -d "$TDP_ROLES_PATH" ]] || git clone -o StrictHostKeyChecking=no git@github.com:TOSIT-FR/ansible-tdp-roles.git "$TDP_ROLES_PATH"
