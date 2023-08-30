#!/usr/bin/env bash

set -euo pipefail

readonly AVAILABLE_FEATURES=(extras prerequisites vagrant server ui observability)
readonly PYTHON_BIN=${PYTHON_BIN:-python3}
readonly PYTHON_VENV=${PYTHON_VENV:-venv}
readonly NPM_BIN=${NPM_BIN:-npm}
readonly TDP_COLLECTION_PATH="ansible_collections/tosit/tdp"
readonly TDP_COLLECTION_EXTRAS_PATH="ansible_collections/tosit/tdp_extra"
readonly TDP_COLLECTION_OBSERVABILITY_PATH="ansible_collections/tosit/tdp_observability"
readonly SQLITE_DB_PATH=${SQLITE_DB_PATH:-sqlite.db}
readonly TDP_DATABASE_DSN=${TDP_DATABASE_DSN:-sqlite:///$SQLITE_DB_PATH}
readonly TDP_VARS_OVERRIDES=${TDP_VARS_OVERRIDES:-tdp_vars_overrides}

CLEAN="false"
declare -a FEATURES
HELP="false"
RELEASE=stable

print_help() {
  cat <<EOF
SYNOPSIS
  TDP getting started environment setup script.

DESCRIPTION
  Ensures the existence of directories and dependencies required for TDP deployment.
  If submodule are not present, they will be checkout. Use "-c" option to force submodule update.
  If needed symlink and "tdp_vars" are not present, they will be created. Use "-c" option to remove and re-create them.

USAGE
  setup.sh [-e feature1 -e ...] [-h] [-r latest|stable]

OPTIONS
  -c Run in clean mode (reset git submodule, symlink, tdp_vars, etc.)
  -e Enable feature, can be set multiple times (Available features: ${AVAILABLE_FEATURES[@]})
  -h Display help
  -r Specify the release for TDP deployment. Takes options latest and stable (the default).
EOF
}

parse_cmdline() {
  local OPTIND
  while getopts 'ce:hr:' options; do
    case "$options" in
    c) CLEAN="true" ;;
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

# From https://stackoverflow.com/a/53839433
join_arr() {
  local IFS="$1"
  shift
  echo "$*"
}

create_directories() {
  mkdir -p logs files inventory/topologies
}

git_submodule_setup() {
  local path=$1
  local status="$(git submodule status -- "$path")"
  if [[ "$status" != -* ]] && [[ "$CLEAN" == "false" ]]; then
    echo "Submodule '${path}' present, nothing to do"
    return 0
  fi
  git submodule update --init --recursive "$path"
  if [[ "$RELEASE" == "latest" ]]; then
    local commit="origin/$2"
    (
      cd "$path"
      git fetch --prune
      git checkout "$commit"
      echo "Submodule '${path}' checkout to '${commit}'"
    )
  fi
  return 0
}

create_symlink_if_needed() {
  local target=$1
  local link_name=$2
  if [[ "$CLEAN" == "true" ]]; then
    echo "Remove '${link_name}'"
    rm -rf "$link_name"
  fi
  if [[ -e "$link_name" ]] || [[ -L "$link_name" ]]; then
    echo "File '${link_name}' exists, nothing to do"
    return 0
  fi
  echo "Create symlink '${link_name}'"
  ln -s "$target" "$link_name"
}

setup_submodule_tdp() {
  local submodule_path="$TDP_COLLECTION_PATH"
  git_submodule_setup "$submodule_path" "master"

  # Quick fix for file lookup related to the Hadoop role refactor (https://github.com/TOSIT-IO/tdp-collection/pull/57)
  create_symlink_if_needed "../../../../files" "${submodule_path}/playbooks/files"
  create_symlink_if_needed "../../${submodule_path}/topology.ini" "inventory/topologies/01_tdp"
}

setup_submodule_extras() {
  local submodule_path="$TDP_COLLECTION_EXTRAS_PATH"
  git_submodule_setup "$submodule_path" "master"

  # Quick fix for file lookup related to the Hadoop role refactor (https://github.com/TOSIT-IO/tdp-collection/pull/57)
  create_symlink_if_needed "../../../../files" "${submodule_path}/playbooks/files"
  create_symlink_if_needed "../../${submodule_path}/topology.ini" "inventory/topologies/extras"
}

setup_submodule_prerequisites() {
  local submodule_path="ansible_collections/tosit/tdp_prerequisites"
  git_submodule_setup "$submodule_path" "master"
  create_symlink_if_needed "../../${submodule_path}/topology.ini" "inventory/topologies/prerequisites"
}

setup_submodule_vagrant() {
  git_submodule_setup "tdp-vagrant" "master"
  create_symlink_if_needed "tdp-vagrant/Vagrantfile" "Vagrantfile"
  create_symlink_if_needed "../.vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory" "inventory/hosts.ini"
}

setup_submodule_tdp_lib() {
  git_submodule_setup "tdp-lib" "master"
  local collection_path="$TDP_COLLECTION_PATH"
  local env_path=".env"

  for feature in "${FEATURES[@]}"; do
    case "$feature" in
    extras) collection_path="${collection_path}:${TDP_COLLECTION_EXTRAS_PATH}" ;;
    observability) collection_path="${collection_path}:${TDP_COLLECTION_OBSERVABILITY_PATH}" ;;
    esac
  done

  if [[ "$CLEAN" == "true" ]]; then
    echo "Remove ${env_path}"
    rm -rf "$env_path"
  fi
  if [[ -e "${env_path}" ]]; then
    echo "File ${env_path} exists, nothing to do"
    return 0
  fi
  cat <<EOF > "$env_path"
# common
export TDP_COLLECTION_PATH=${collection_path}
export TDP_RUN_DIRECTORY=.
export TDP_VARS=./tdp_vars

# tdp-lib
export TDP_DATABASE_DSN=${TDP_DATABASE_DSN}
EOF

  local backend_cors_origins
  declare -a backend_cors_origins

  for feature in "${FEATURES[@]}"; do
    case "$feature" in
    server) backend_cors_origins+=("\\\"http://localhost:8000\\\"") ;;
    ui)     backend_cors_origins+=("\\\"http://localhost:3000\\\"") ;;
    esac
  done

  # Generate a comma separated string
  backend_cors_origins_comma=$(join_arr , "${backend_cors_origins[@]}")

  for feature in "${FEATURES[@]}"; do
    case "$feature" in
    server) cat <<EOF >> "$env_path"

# tdp-server
export PROJECT_NAME=tdp-server
export BACKEND_CORS_ORIGINS="[${backend_cors_origins_comma}]"
export SERVER_NAME=localhost
export SERVER_HOST=http://localhost:8000
export OPENID_CONNECT_DISCOVERY_URL=http://localhost:8080/auth/realms/tdp_server/.well-known/openid-configuration
export OPENID_CLIENT_ID=tdp_server
export DATABASE_DSN=${TDP_DATABASE_DSN}
export DO_NOT_USE_IN_PRODUCTION_DISABLE_TOKEN_CHECK=True
EOF
    ;;
    esac
  done
  return 0
}

setup_submodule_tdp_server() {
  git_submodule_setup "tdp-server" "master"
}

setup_submodule_tdp_ui() {
  git_submodule_setup "tdp-ui" "master"

  local config_path="./tdp-ui/config.json"
  if [[ "$CLEAN" == "true" ]]; then
    echo "Remove ${config_path}"
    rm -rf "$config_path"
  fi
  if [[ -e "${config_path}" ]]; then
    echo "File ${config_path} exists, nothing to do"
    return 0
  fi
  cat <<EOF > "$config_path"
{
  "apiBasePath": "http://localhost:8000",
  "skipAuth": true
}
EOF
}

setup_submodule_observability() {
  local submodule_path="$TDP_COLLECTION_OBSERVABILITY_PATH"
  git_submodule_setup "$submodule_path" "main"

  # Quick fix for file lookup related to the Hadoop role refactor (https://github.com/TOSIT-IO/tdp-collection/pull/57)
  create_symlink_if_needed "../../../../files" "${submodule_path}/playbooks/files"
  create_symlink_if_needed "../../${submodule_path}/topology.ini" "inventory/topologies/observability"

  # Galaxy observability roles
  ansible-galaxy role install -r "${submodule_path}/requirements.yml"
}

install_additional_ansible_collections() {
  echo "Install Ansible collections from requirements.yml"
  source "${PYTHON_VENV}/bin/activate"
  ansible-galaxy collection install -r requirements.yml
}

setup_python_venv() {
  if [[ ! -d "$PYTHON_VENV" ]]; then
    echo "Create python venv with '${PYTHON_BIN}' to '${PYTHON_VENV}' and update pip to latest version"
    "$PYTHON_BIN" -m venv "$PYTHON_VENV"
    (
      source "${PYTHON_VENV}/bin/activate"
      pip install -U pip
    )
  else
    echo "Python venv '${PYTHON_VENV}' already exists, nothing to do"
  fi
  echo "Install python dependencies"
  (
    source "${PYTHON_VENV}/bin/activate"
    pip install -r requirements.txt
    for feature in "${FEATURES[@]}"; do
      case "$feature" in
      # tdp-server must be installed before tdp-lib
      # with tdp-lib installed after, it will override the tdp-lib installed by tdp-server
      server) pip install --editable tdp-server uvicorn==0.16.0 ;;
      esac
    done
    pip install --editable tdp-lib[visualization]
  )
  return 0
}

init_tdp_lib() {
  local tdp_vars="./tdp_vars"
  local tdp_lib_cli_args=(init)
  if [[ "$CLEAN" == "true" ]]; then
    echo "Remove '${tdp_vars}' and '${SQLITE_DB_PATH}'"
    rm -rf "$tdp_vars" "$SQLITE_DB_PATH"
  fi
  if [[ -n "$TDP_VARS_OVERRIDES" ]]; then
    tdp_lib_cli_args+=(--overrides "$TDP_VARS_OVERRIDES")
  fi
  echo "tdp-lib init"
  (
    source "${PYTHON_VENV}/bin/activate"
    tdp "${tdp_lib_cli_args[@]}"
  )
  return 0
}

init_tdp_server() {
  echo "tdp-server init"
  (
    source "${PYTHON_VENV}/bin/activate"
    python tdp-server/tdp_server/initialize_database.py
    python tdp-server/tdp_server/initialize_tdp_vars.py
  )
  return 0
}

init_tdp_ui() {
  echo "tdp-ui init"
  "${NPM_BIN}" install ./tdp-ui
  echo "Generate the API client SDK"
  "${NPM_BIN}" --prefix ./tdp-ui run generate
  return 0
}

download_tdp_binaries() {
  while IFS=";" read -r uri_file_name file_name
  do
    if [[ -n "$file_name" ]]
    then
      wget --no-clobber --output-document=files/${file_name} ${uri_file_name}
    else
      wget --no-clobber --directory-prefix="files" ${uri_file_name}
    fi
  done < scripts/tdp-release-uris.txt
}

main() {
  parse_cmdline "$@" || { print_help; exit 1; }
  [[ "$HELP" == "true" ]] && { print_help; exit 0; }
  validate_features
  create_directories

  setup_submodule_tdp

  for feature in "${FEATURES[@]}"; do
    case "$feature" in
    extras)        setup_submodule_extras ;;
    prerequisites) setup_submodule_prerequisites ;;
    vagrant)       setup_submodule_vagrant ;;
    server)        setup_submodule_tdp_server ;;
    ui)            setup_submodule_tdp_ui ;;
    observability) setup_submodule_observability ;;
    esac
  done

  setup_submodule_tdp_lib
  setup_python_venv
  install_additional_ansible_collections
  init_tdp_lib

  for feature in "${FEATURES[@]}"; do
    case "$feature" in
    server) init_tdp_server ;;
    ui)     init_tdp_ui ;;
    esac
  done

  download_tdp_binaries
}

main "$@"
