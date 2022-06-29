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
TDP_COLLECTION_STABLE_COMMIT=fa68888b13f1aa68c8cc096049e0b333bd27d714

# tdp-collection-extras
TDP_COLLECTION_EXTRAS_URL=https://github.com/TOSIT-IO/tdp-collection-extras
TDP_ROLES_EXTRA_PATH="$abs_root_dir/ansible_roles/collections/ansible_collections/tosit/tdp_extra"
TDP_COLLECTION_EXTRAS_STABLE_COMMIT=b24cfc7e75f2d599716ea212b1e8f2cab55953af

# Create directories
mkdir -p logs
mkdir -p files

print_usage() {
  echo """
  Name:
    TDP getting started environment setup script
  Description:
    Ensures the existence of directories and dependencies required by the TDP getting started project.
  Usage:
    setup.sh.sh [-h] [-r latest|stable]
  Options:
    -h Display usage
    -r Specify the release of the downlaoded TDP collections. Takes options latest and stable (the default).
  """
}

# Parse args for for target release and help flags
while getopts 'r:h' options; do
  case "$options" in
  r) RELEASE="$OPTARG" ;;
  h) print_usage && exit 0 ;;
  *) print_usage && exit 1 ;;
  esac
done

if [ "$RELEASE" == "latest" ]; then
  echo "Cloning latest tdp-collections..."
  [[ -d "$TDP_ROLES_PATH" ]] || "$abs_root_dir/scripts/git-commit-download.sh" "$TDP_ROLES_PATH" "$TDP_COLLECTION_URL"
  [[ -d "$TDP_ROLES_EXTRA_PATH" ]] || "$abs_root_dir/scripts/git-commit-download.sh" "$TDP_ROLES_EXTRA_PATH" "$TDP_COLLECTION_EXTRAS_URL"

elif [ "$RELEASE" == "stable" ]; then
  echo "Cloning stable tdp-collections..."
  [[ -d "$TDP_ROLES_PATH" ]] || "$abs_root_dir/scripts/git-commit-download.sh" "$TDP_ROLES_PATH" "$TDP_COLLECTION_URL" "$TDP_COLLECTION_STABLE_COMMIT"
  [[ -d "$TDP_ROLES_EXTRA_PATH" ]] || "$abs_root_dir/scripts/git-commit-download.sh" "$TDP_ROLES_EXTRA_PATH" "$TDP_COLLECTION_EXTRAS_URL" "$TDP_COLLECTION_EXTRAS_STABLE_COMMIT"

fi

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
