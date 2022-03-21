#!/usr/bin/env bash

###
# Bash script to setup environment for deploying
# virtual TDP cluster using the TDP-getting-started repo
###

TDP_ROLES_PATH=ansible_roles/collections/ansible_collections/tosit/tdp
TDP_ROLES_EXTRA_PATH=ansible_roles/collections/ansible_collections/tosit/tdp-extra

# Create directories
mkdir -p logs
mkdir -p files

# Clone ansible-tdp-roles repository (doesn't fail iof not known host)
[[ -d "$TDP_ROLES_PATH" ]] || git clone --branch hue-ansible-tdp-role -o StrictHostKeyChecking=no git@github.com:TOSIT-IO/ansible-tdp-roles.git "$TDP_ROLES_PATH"
[[ -d "$TDP_ROLES_EXTRA_PATH" ]] || git clone --branch hue -o StrictHostKeyChecking=no git@github.com:TOSIT-IO/tdp-collection-extras.git "$TDP_ROLES_EXTRA_PATH"

# Quick fix for file lookup related to the Hadoop role refactor (https://github.com/TOSIT-FR/ansible-tdp-roles/pull/57)
ln -s $PWD/files $TDP_ROLES_PATH/playbooks/files
ln -s $PWD/files $TDP_ROLES_EXTRA_PATH/playbooks/files

# Copy the default tdp_vars
[[ -d inventory/tdp_vars ]] || cp -r ansible_roles/collections/ansible_collections/tosit/tdp/tdp_vars_defaults inventory/tdp_vars
[[ -d inventory/tdp_extra_vars ]] || cp -r ansible_roles/collections/ansible_collections/tosit/tdp-extra/tdp_extra_vars_defaults inventory/tdp_extra_vars


# Link to local TDP binary directory (until  we go open source)
ln -s /home/daniel/Desktop/temp/tdp-getting-started/tdp-binaries/* $PWD/files


# Fetch the TDP .tar.gz releases (once we go open source)
# https://github.com/TOSIT-FR/hadoop/releases/download/hadoop-project-dist-3.1.1-TDP-0.1.0-SNAPSHOT/hadoop-3.1.1-TDP-0.1.0-SNAPSHOT.tar.gz
# https://github.com/TOSIT-FR/hive/releases/download/apache-hive-metastore-3.1.3-TDP-0.1.0-SNAPSHOT/apache-hive-3.1.3-TDP-0.1.0-SNAPSHOT-bin.tar.gz
# https://github.com/TOSIT-FR/tez/releases/download/tez-0.9.1-TDP-0.1.0-SNAPSHOT/tez-0.9.1-TDP-0.1.0-SNAPSHOT.tar.gz
# https://github.com/TOSIT-FR/spark/releases/download/spark-2.3.5-TDP-0.1.0-SNAPSHOT/spark-2.3.5-TDP-0.1.0-SNAPSHOT-bin-tdp.tgz
# https://github.com/TOSIT-FR/ranger/releases/download/ranger-2.0.1-TDP-0.1.0-SNAPSHOT/ranger-2.0.1-TDP-0.1.0-SNAPSHOT-admin.tar.gz
# https://github.com/TOSIT-FR/ranger/releases/download/ranger-2.0.1-TDP-0.1.0-SNAPSHOT/ranger-2.0.1-TDP-0.1.0-SNAPSHOT-hdfs-plugin.tar.gz
# https://github.com/TOSIT-FR/ranger/releases/download/ranger-2.0.1-TDP-0.1.0-SNAPSHOT/ranger-2.0.1-TDP-0.1.0-SNAPSHOT-hive-plugin.tar.gz
# https://github.com/TOSIT-FR/ranger/releases/download/ranger-2.0.1-TDP-0.1.0-SNAPSHOT/ranger-2.0.1-TDP-0.1.0-SNAPSHOT-yarn-plugin.tar.gz
# https://github.com/TOSIT-FR/ranger/releases/download/ranger-2.0.1-TDP-0.1.0-SNAPSHOT/ranger-2.0.1-TDP-0.1.0-SNAPSHOT-hbase-plugin.tar.gz
