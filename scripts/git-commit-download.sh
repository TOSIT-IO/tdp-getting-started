#!/usr/bin/env bash

###
# Bash script to download git archive
###

print_usage() {
  echo """
  Usage: git-commit-download.sh <target_directory> <github_repo_url> <target_commit>

  Note: This script downloads and extracts a github hosted project. Adding the commit sha parameter downloads the project at that specific commit. Takes 2 mandatory args:

    - target_directory e.g. ansible_roles/collections/ansible_collections/tosit/tdp
    - github_repo_url e.g. https://github.com/TOSIT-IO/tdp-collection

  A third optional arg to target a specific commit of the target project:

    - target_commit e.g.abb3a24c43ba6ade109e93c187a77999ab919349
  """
}

get_git_repository_commit() {

  target_dir=$1
  github_repository_url=$2
  repository_name="$(basename "$github_repository_url")"

  if [ $# -eq 2 ] # No commit sha
  then
    archive_filename="master.zip"
    archive_download_uri="$github_repository_url/archive/refs/heads/$archive_filename"
    unzipped_filename="$repository_name-master"
  elif [ $# -eq 3 ] # Commit sha
  then
    commit_sha=$3
    archive_filename="$3.zip"
    unzipped_filename="$repository_name-$commit_sha"
    archive_download_uri="$github_repository_url/archive/$archive_filename"
  else
    print_usage && exit 1
  fi

  # Download and place github project
  wget -O "/tmp/$archive_filename" "$archive_download_uri"
  unzip -q -o "/tmp/$archive_filename" -d /tmp
  mkdir -p "$target_dir"
  cp -r "/tmp/$unzipped_filename/." "$target_dir"
}

get_git_repository_commit "$@"
