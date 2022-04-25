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
TDP_ROLES_EXTRA_PATH=ansible_roles/collections/ansible_collections/tosit/tdp_extra
TDP_COLLECTION_EXTRAS_COMMIT=1035ca7f3f67275140cd15478d043b543679ec30

root_dir="$(dirname "$0")/.." # project root dir
EXPANDED_TDP_ROLES_PATH="$(realpath "$root_dir")/$TDP_ROLES_PATH"
EXPANDED_TDP_ROLES_EXTRA_PATH="$(realpath "$root_dir")/$TDP_ROLES_EXTRA_PATH"

# Create directories
mkdir -p logs
mkdir -p files

# Clone ansible-tdp-roles repository (doesn't fail iof not known host)
[[ -d "$EXPANDED_TDP_ROLES_PATH" ]] || "$(realpath "$root_dir")/scripts/git-commit-download.sh" $EXPANDED_TDP_ROLES_PATH $TDP_COLLECTION_URL $TDP_COLLECTION_COMMIT

[[ -d "$TDP_ROLES_EXTRA_PATH" ]] || "$(realpath "$root_dir")/scripts/git-commit-download.sh" $EXPANDED_TDP_ROLES_EXTRA_PATH $TDP_COLLECTION_EXTRAS_URL $TDP_COLLECTION_EXTRAS_COMMIT

# Quick fix for file lookup related to the Hadoop role refactor (https://github.com/TOSIT-FR/ansible-tdp-roles/pull/57)

[[ -d $EXPANDED_TDP_ROLES_PATH/playbooks/files ]] || ln -s "$(realpath "$root_dir")/files" $EXPANDED_TDP_ROLES_PATH/playbooks

# Copy the default tdp_vars
[[ -d "$(realpath "$root_dir")/inventory/tdp_vars" ]] || cp -r $EXPANDED_TDP_ROLES_PATH/tdp_vars_defaults "$(realpath "$root_dir")/inventory/tdp_vars"

# Read the TDP releases from file
tdp_release_uris=$(sed -E '/^[[:blank:]]*(#|$)/d; s/#.*//' "$(realpath "$root_dir")/scripts/tdp-release-uris.txt")

# Fetch the TDP .tar.gz releases
for tdp_release_uri in $tdp_release_uris; do
    release_name=$(basename $tdp_release_uri)
    # Fetch the TDP .tar.gz releases
    [[ -f "$(realpath "$root_dir")/files/$release_name" ]] || wget $tdp_release_uri -nc -nd -O "$(realpath "$root_dir")/files/$release_name"
done
