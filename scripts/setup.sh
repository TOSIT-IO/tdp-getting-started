#!/usr/bin/env bash

###
# Bash script to setup environment for deploying
# virtual TDP cluster using the TDP-getting-started repo
###

# tdp-getting-started root dir
rel_root_dir="$(dirname "$0")/.."
abs_root_dir="$(realpath "$rel_root_dir")"

# tdp-collection
TDP_COLLECTION_URL=https://github.com/TOSIT-IO/tdp-collection
TDP_ROLES_PATH="$abs_root_dir/ansible_roles/collections/ansible_collections/tosit/tdp"
TDP_COLLECTION_COMMIT=7076c9c95a14f701e510d02520c5c4901a7ac2bd

# tdp-collection-extras
TDP_COLLECTION_EXTRAS_URL=https://github.com/TOSIT-IO/tdp-collection-extras
TDP_ROLES_EXTRA_PATH="$abs_root_dir/ansible_roles/collections/ansible_collections/tosit/tdp_extra"
TDP_COLLECTION_EXTRAS_COMMIT=e407bb40958d77b87287fe42dc48a969ad179c4f

# Create directories
mkdir -p logs
mkdir -p files

# Clone ansible-tdp-roles repository (doesn't fail if not known host)
[[ -d "$TDP_ROLES_PATH" ]] || "$abs_root_dir/scripts/git-commit-download.sh" "$TDP_ROLES_PATH" "$TDP_COLLECTION_URL" "$TDP_COLLECTION_COMMIT"
[[ -d "$TDP_ROLES_EXTRA_PATH" ]] || "$abs_root_dir/scripts/git-commit-download.sh" "$TDP_ROLES_EXTRA_PATH" "$TDP_COLLECTION_EXTRAS_URL" "$TDP_COLLECTION_EXTRAS_COMMIT"

# Quick fix for file lookup related to the Hadoop role refactor (https://github.com/TOSIT-FR/ansible-tdp-roles/pull/57)
[[ -d "$TDP_ROLES_PATH/playbooks/files" ]] || ln -s "$abs_root_dir/files" "$TDP_ROLES_PATH/playbooks"
[[ -d "$TDP_ROLES_EXTRA_PATH/playbooks/files" ]] || ln -s "$abs_root_dir/files" "$TDP_ROLES_EXTRA_PATH/playbooks"

# Copy the default tdp_vars from tdp-collection and tdp-collection-extras
mkdir -p "$abs_root_dir/inventory/tdp_vars"
[[ -d "$TDP_ROLES_PATH/tdp_vars_defaults" ]] && cp -rf "$TDP_ROLES_PATH/tdp_vars_defaults/"* "$abs_root_dir/inventory/tdp_vars"
[[ -d "$TDP_ROLES_EXTRA_PATH/tdp_vars_defaults" ]] && cp -rf "$TDP_ROLES_EXTRA_PATH/tdp_vars_defaults/"* "$abs_root_dir/inventory/tdp_vars"

# Download tdp release binaries
tdp_releases="$abs_root_dir/scripts/tdp-release-uris.txt"
wget -nc -i "$tdp_releases" -P "$abs_root_dir/files"
