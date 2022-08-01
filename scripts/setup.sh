#!/usr/bin/env bash

set -euo pipefail

readonly AVAILABLE_FEATURES=(extras vagrant)
readonly PYTHON_BIN=${PYTHON_BIN:-python3}
readonly PYTHON_VENV=${PYTHON_VENV:-venv}
readonly TDP_COLLECTION_PATH="ansible_roles/collections/ansible_collections/tosit/tdp"
readonly TDP_COLLECTION_EXTRAS_PATH="ansible_roles/collections/ansible_collections/tosit/tdp_extra"

declare -a FEATURES
HELP="false"
RELEASE=stable

print_help() {
  cat <<EOF
SYNOPSIS
  TDP getting started environment setup script.

DESCRIPTION
  Ensures the existence of directories and dependencies required for TDP deployment.

USAGE
  setup.sh [-e feature1 -e ...] [-h] [-r latest|stable]

OPTIONS
  -e Enable feature, can be set multiple times (Available features: ${AVAILABLE_FEATURES[@]})
  -h Display help
  -r Specify the release for TDP deployment. Takes options latest and stable (the default).
EOF
}

parse_cmdline() {
  local OPTIND
  while getopts 'e:hr:' options; do
    case "$options" in
    e) FEATURES+=("$OPTARG") ;;
    h) HELP="true" && return 0 ;;
    r) RELEASE="$OPTARG" ;;
    *) return 1 ;;
    esac
  done
  shift $((OPTIND - 1))
  return 0
}

validate_features() {
  local validate="true"
  for feature in "${FEATURES[@]}"; do
    local is_available="false"
    for available_feature in "${AVAILABLE_FEATURES[@]}"; do
      [[ "$feature" == "$available_feature" ]] && is_available="true"
    done
    if [[ "$is_available" == "false" ]]; then
      echo "Feature ${feature} does not exist"
      validate="false"
    fi
  done
  if [[ "$validate" == "true" ]]; then
    return 0
  else
    echo "Available features: ${AVAILABLE_FEATURES[@]}"
    return 1
  fi
}

create_directories() {
  mkdir -p logs files
}

setup_python_venv() {
  [[ -d "$PYTHON_VENV" ]] && return 0
  echo "Setup python venv with '${PYTHON_BIN}' to '${PYTHON_VENV}'"
  "$PYTHON_BIN" -m venv "$PYTHON_VENV"
  (
    source "${PYTHON_VENV}/bin/activate"
    pip install -U pip
    pip install -r requirements.txt
  )
  return 0
}

git_submodule_setup() {
  local path=$1
  git submodule update --init --recursive "$path"
  if [[ "$RELEASE" == "latest" ]]; then
    local commit="origin/master"
    (
      cd "$path"
      git fetch --prune
      git checkout "$commit"
      echo "Submodule '${path}' checkout to '${commit}'"
    )
  fi
  return 0
}

setup_submodule_tdp() {
  local submodule_path="$TDP_COLLECTION_PATH"
  git_submodule_setup "$submodule_path"

  # Quick fix for file lookup related to the Hadoop role refactor (https://github.com/TOSIT-IO/tdp-collection/pull/57)
  [[ -d "${submodule_path}/playbooks/files" ]] || ln -s "../../../../../../files" "${submodule_path}/playbooks"
}

setup_submodule_extras() {
  local submodule_path="$TDP_COLLECTION_EXTRAS_PATH"
  git_submodule_setup "$submodule_path"

  # Quick fix for file lookup related to the Hadoop role refactor (https://github.com/TOSIT-IO/tdp-collection/pull/57)
  [[ -d "${submodule_path}/playbooks/files" ]] || ln -s "../../../../../../files" "${submodule_path}/playbooks"
}

setup_submodule_vagrant() {
  git_submodule_setup "tdp-vagrant"
  [[ -f "Vagrantfile" ]] || ln -s tdp-vagrant/Vagrantfile Vagrantfile
  [[ -f "inventory/hosts.ini" ]] || ln -s ../.vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory inventory/hosts.ini
}

setup_tdp_vars() {
  local tdp_vars="inventory/tdp_vars"
  rm -rf "$tdp_vars"
  mkdir "$tdp_vars"
  local tdp_vars_defaults_to_copy=(
    "${TDP_COLLECTION_PATH}/tdp_vars_defaults"
    "${TDP_COLLECTION_EXTRAS_PATH}/tdp_vars_defaults"
  )
  for tdp_vars_defaults in "${tdp_vars_defaults_to_copy[@]}"; do
    [[ -d "$tdp_vars_defaults" ]] && cp -rf "${tdp_vars_defaults}/"* "$tdp_vars"
  done
  echo "tdp_vars_defaults copied to '${tdp_vars}'"
  return 0
}

download_tdp_binaries() {
  wget --no-clobber --input-file="scripts/tdp-release-uris.txt" --directory-prefix="files"
}

main() {
  parse_cmdline "$@" || { print_help; exit 1; }
  [[ "$HELP" == "true" ]] && { print_help; exit 0; }
  validate_features
  create_directories
  setup_python_venv

  setup_submodule_tdp

  for feature in "${FEATURES[@]}"; do
    case "$feature" in
    extras)  setup_submodule_extras ;;
    vagrant) setup_submodule_vagrant ;;
    esac
  done

  setup_tdp_vars
  download_tdp_binaries
}

main "$@"
