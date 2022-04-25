#!/usr/bin/env bash

###
# Bash script to setup environment for deploying
# virtual TDP cluster using the TDP-getting-started repo
###

# tdp-collection
TDP_COLLECTION_URL=https://github.com/TOSIT-IO/tdp-collection
TDP_ROLES_PATH=ansible_roles/collections/ansible_collections/tosit/tdp
TDP_COLLECTION_COMMIT=86f2d3f42df18a5ac07cc25e847ddaf3082be6d4

# tdp-collection-extras
TDP_COLLECTION_EXTRAS_URL=https://github.com/TOSIT-IO/tdp-collection-extras
TDP_ROLES_EXTRA_PATH=ansible_roles/collections/ansible_collections/tosit/tdp-extra
TDP_COLLECTION_EXTRAS_COMMIT=1035ca7f3f67275140cd15478d043b543679ec30

# Create directories
mkdir -p logs
mkdir -p files

# Clone ansible-tdp-roles repository (doesn't fail iof not known host)
[[ -d "$TDP_ROLES_PATH" ]] || scripts/git-commit-download.sh $TDP_ROLES_PATH $TDP_COLLECTION_URL $TDP_COLLECTION_COMMIT

[[ -d "$TDP_ROLES_EXTRA_PATH" ]] || scripts/git-commit-download.sh $TDP_ROLES_EXTRA_PATH $TDP_COLLECTION_EXTRAS_URL $TDP_COLLECTION_EXTRAS_COMMIT

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
