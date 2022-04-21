#!/usr/bin/env bash

###
# Bash script to help users to configure their local environment
###

HOST_FLAG=''

root_dir="$(dirname "$0")/.."

print_usage() {
  echo """
  Usage: helper.sh [-h]
  Note: This script relies on jq

  Options:
    -h  Generate hosts list from Ansible inventory.
  """
}

print_hosts() {
  cd "$root_dir" || exit 1

  echo "# TDP Getting Started hosts"
  ansible-inventory -i inventory --list --export |
    jq -r '
      ._meta.hostvars | to_entries[] |
      (.value.ansible_host + " " + .key + "." + .value.domain)
    '
}

while getopts 'h' flag; do
  case "${flag}" in
  h) HOST_FLAG='true' ;;
  *) print_usage && exit 1 ;;
  esac
done

if [[ "$HOST_FLAG" ]]; then print_hosts; fi
