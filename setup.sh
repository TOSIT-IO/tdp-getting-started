#!/usr/bin/env bash

###
# Bash script to setup environment for deploying
# virtual TDP cluster using the TDP-getting-started repo
###

TDP_ROLES_PATH=ansible_roles/collections/ansible_collections/tosit/tdp
TDP_ROLES_EXTRA_PATH=ansible_roles/collections/ansible_collections/tosit/tdp-extra

# Create directories
mkdir -p logs
mkdir -p files

# Clone ansible-tdp-roles repository (doesn't fail iof not known host)
[[ -d "$TDP_ROLES_PATH" ]] || git clone -o StrictHostKeyChecking=no git@github.com:TOSIT-IO/tdp-collection.git "$TDP_ROLES_PATH"
[[ -d "$TDP_ROLES_EXTRA_PATH" ]] || git clone -o StrictHostKeyChecking=no git@github.com:TOSIT-IO/tdp-collection-extras.git "$TDP_ROLES_EXTRA_PATH"

# Quick fix for file lookup related to the Hadoop role refactor (https://github.com/TOSIT-FR/ansible-tdp-roles/pull/57)
[[ -d $TDP_ROLES_PATH/playbooks/files ]] || ln -s $PWD/files $TDP_ROLES_PATH/playbooks

# Copy the default tdp_vars
[[ -d inventory/tdp_vars ]] || cp -r ansible_roles/collections/ansible_collections/tosit/tdp/tdp_vars_defaults inventory/tdp_vars

# Read the TDP releases from file
tdp_release_uris=$(sed -E '/^[[:blank:]]*(#|$)/d; s/#.*//' $PWD/tdp-release-uris)

# Fetch the TDP .tar.gz releases
for tdp_release_uri in $tdp_release_uris; do
    release_name=$(basename $tdp_release_uri)
    # Fetch the TDP .tar.gz releases
    [[ -f "$PWD/files/$release_name" ]] || wget $tdp_release_uri -nc -nd -O $PWD/files/$release_name
done
