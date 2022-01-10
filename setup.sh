#!/usr/bin/env bash

###
# Bash script to setup environment for deploying
# virtual TDP cluster using the TDP-getting-started repo
###

TDP_ROLES_PATH=ansible_roles/collections/ansible_collections/tosit/tdp

# Create directories
mkdir -p logs
mkdir -p files

# Clone ansible-tdp-roles repository (doesn't fail iof not known host)
[[ -d "$TDP_ROLES_PATH" ]] || git clone -o StrictHostKeyChecking=no git@github.com:TOSIT-FR/ansible-tdp-roles.git "$TDP_ROLES_PATH"

# Quick fix for file lookup related to the Hadoop role refactor (https://github.com/TOSIT-FR/ansible-tdp-roles/pull/57)
ln -s $PWD/files $TDP_ROLES_PATH/playbooks/files

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