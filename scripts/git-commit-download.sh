#!/usr/bin/env bash

###
# Bash script to download git archive
###

root_dir="$(dirname "$0")/.." # project root dir
target_dir="$root_dir/$1"
target_repository_url="$2"
target_commit="$3"
archive_filename="$target_commit.zip"
repository_name="$(basename $target_repository_url)"
archive_download_uri="$target_repository_url/archive/$archive_filename"

print_usage() {
  echo """
  Usage: git-commit-download.sh <target_directory> <github_repo_url> <target_commit>

  Note: This script downloads and extracts a github hosted project at a specific commit. Takes 3 mandatory args:

    - target_directory e.g. ansible_roles/collections/ansible_collections/tosit/tdp
    - github_repo_url e.g. https://github.com/TOSIT-IO/tdp-collection
    - target_commit e.g.abb3a24c43ba6ade109e93c187a77999ab919349
  """
}

get_git_repository_commit() {

  wget -O "/tmp/$archive_filename" "$archive_download_uri"
  unzip -o "/tmp/$archive_filename" -d /tmp
  mkdir -p "$target_dir"
  cp -r "/tmp/$repository_name-$target_commit/." "$target_dir"
}

while getopts 'h' flag; do
  print_usage && exit 1
done

get_git_repository_commit
