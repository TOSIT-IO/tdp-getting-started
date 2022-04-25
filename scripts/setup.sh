#!/usr/bin/env bash

###
# Bash script to setup environment for deploying
# virtual TDP cluster using the TDP-getting-started repo
###

# Get tdp-getting-started root dir
root_dir="$(dirname "$0")/.."

TDP_ROLES_PATH="$root_dir/ansible_roles/collections/ansible_collections/tosit/tdp"
TDP_ROLES_EXTRA_PATH="$root_dir/ansible_roles/collections/ansible_collections/tosit/tdp_extra"

# Create directories
mkdir -p logs
mkdir -p files

# Clone ansible-tdp-roles repository (doesn't fail if not known host)
[[ -d "$TDP_ROLES_PATH" ]] || git clone https://github.com/TOSIT-IO/tdp-collection.git "$TDP_ROLES_PATH"
[[ -d "$TDP_ROLES_EXTRA_PATH" ]] || git clone https://github.com/TOSIT-IO/tdp-collection-extras.git "$TDP_ROLES_EXTRA_PATH"

# Quick fix for file lookup related to the Hadoop role refactor (https://github.com/TOSIT-FR/ansible-tdp-roles/pull/57)
[[ -d "$TDP_ROLES_PATH/playbooks/files" ]] || ln -s "$(realpath "$root_dir")/files" "$TDP_ROLES_PATH/playbooks"
[[ -d "$TDP_ROLES_EXTRA_PATH/playbooks/files" ]] || ln -s "$(realpath "$root_dir")/files" "$TDP_ROLES_EXTRA_PATH/playbooks"

# Copy the default tdp_vars
[[ -d inventory/tdp_vars ]] || cp -r ansible_roles/collections/ansible_collections/tosit/tdp/tdp_vars_defaults inventory/tdp_vars

# Read the TDP releases from file
tdp_release_uris=$(grep -P '^[^#]' <"$root_dir/scripts/tdp-release-uris.txt")

# Fetch the TDP .tar.gz releases
for tdp_release_uri in $tdp_release_uris; do
    release_name=$(basename "$tdp_release_uri" | grep -oP '^([^?]+)')
    # Fetch the TDP .tar.gz releases
    [[ -f "$root_dir/files/$release_name" ]] || wget "$tdp_release_uri" -nc -nd -O "$root_dir/files/$release_name"
done
