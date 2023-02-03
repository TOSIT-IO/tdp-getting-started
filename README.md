# Getting Started with TDP

Use this repository to have a working directory where you run deploy commands with predefined virtual infrastructure with Vagrant or your own infrastructure.
You can customize the infrastructure and components of your cluster with 1 command per component.

- [Requirements](#requirements)
- [Quick Start](#quick-start)
  - [Prerequisites](#prerequisites)
  - [Deploy with TDP lib CLI](#deploy-with-tdp-lib-cli)
  - [Deploy with Ansible playbook](#deploy-with-ansible-playbook)
- [Web UIs Links](#web-uis-links)
- [Customised Deployment](#customised-deployment)
  - [Environment Setup](#environment-setup)
  - [Configure infrastructure](#configure-infrastructure)
  - [Configure prerequisites](#configure-prerequisites)
  - [Core Services Deployment](#core-services-deployment)
  - [Extras Services Deployment](#extras-services-deployment)
  - [Utils](#utils)

## Requirements

- Python >= 3.6 with virtual env package (i.e. `python3-venv`)
- Unzip (to execute the setup scripts)
- `jq` required to execute helper script

If you use TDP Vagrant to deploy VMs see requirements in https://github.com/TOSIT-IO/tdp-vagrant.

Python requirements like Ansible and Mitogen are listed in the file `requirements.txt`. The virtual environment is populated with these requirements. Therefore, you should not install them by yourself outside of the virtual environment. Only versions described in `requirements.txt` are supported.

## Quick Start

The below steps will deploy a TDP cluster with Vagrant using the parameters in the `inventory` directory.
The Ansible `host.ini` file will be generated using the `hosts` variable in `tdp-vagrant/vagrant.yml`.

### Prerequisites

```bash
# Clone project from version control
git clone https://github.com/TOSIT-IO/tdp-getting-started.git
# Move into project dir
cd tdp-getting-started
# Setup local env with stable tdp-collection (mandatory), tdp-lib (mandatory), tdp-server, tdp-collection-extras, tdp-collection-prerequisites, and vagrant
./scripts/setup.sh -e server -e extras -e observability -e prerequisites -e vagrant
# Activate Python virtual env
source ./venv/bin/activate
# To enable mitogen
export ANSIBLE_STRATEGY_PLUGINS="$(python -c 'import os,ansible_mitogen; print(os.path.dirname(ansible_mitogen.__file__))')/plugins/strategy"
export ANSIBLE_STRATEGY="mitogen_linear"
# Launch VMs
vagrant up
# Configure TDP prerequisites
ansible-playbook ansible_collections/tosit/tdp_prerequisites/playbooks/all.yml
```

You have tree ways to deploy a TDP cluster, using TDP server API, using TDP lib CLI or using Ansible playbook.

### Deploy with TDP server API

```bash
# Open a new terminal and activate python virtual env
source ./venv/bin/activate
# Start tdp-server
uvicorn tdp_server.main:app --reload
```

```bash
# Deploy TDP cluster core and extras services
curl -X POST http://localhost:8000/api/v1/deploy/dag
# You can see the log in the tdp-server output (the terminal where uvicorn is running)
# Wait deployment
while ! curl -s http://localhost:8000/api/v1/deploy/status | grep -q "no deployment on-going"; do sleep 10; done
# Configure HDFS user home directories
ansible-playbook ansible_collections/tosit/tdp/playbooks/utils/hdfs_user_homes.yml
# Configure Ranger policies
ansible-playbook ansible_collections/tosit/tdp/playbooks/utils/ranger_policies.yml
```

### Deploy with TDP lib CLI

```bash
# Deploy TDP cluster core and extras services
tdp deploy
# Configure HDFS user home directories
ansible-playbook ansible_collections/tosit/tdp/playbooks/utils/hdfs_user_homes.yml
# Configure Ranger policies
ansible-playbook ansible_collections/tosit/tdp/playbooks/utils/ranger_policies.yml
```

### Deploy with Ansible playbook

```bash
# Deploy TDP cluster core services
ansible-playbook ansible_collections/tosit/tdp/playbooks/meta/all.yml
# Deploy extras services
ansible-playbook ansible_collections/tosit/tdp_extra/playbooks/meta/livy.yml
ansible-playbook ansible_collections/tosit/tdp_extra/playbooks/meta/livy-spark3.yml
ansible-playbook ansible_collections/tosit/tdp_extra/playbooks/meta/zookeeper-kafka.yml
ansible-playbook ansible_collections/tosit/tdp_extra/playbooks/meta/kafka.yml
# Deploy observability services
ansible-playbook ansible_collections/tosit/tdp_observability/playbooks/meta/prometheus.yml
ansible-playbook ansible_collections/tosit/tdp_observability/playbooks/meta/grafana.yml
# Configure HDFS user home directories
ansible-playbook ansible_collections/tosit/tdp/playbooks/utils/hdfs_user_homes.yml
# Configure Ranger policies
ansible-playbook ansible_collections/tosit/tdp/playbooks/utils/ranger_policies.yml
```

## Web UIs Links

- [HDFS NN Master 01](https://master-01.tdp:9871/dfshealth.html)
- [HDFS NN Master 02](https://master-02.tdp:9871/dfshealth.html)
- [YARN RM Master 01](https://master-01.tdp:8090/cluster/apps)
- [YARN RM Master 02](https://master-02.tdp:8090/cluster/apps)
- [MapReduce Job History Server](https://master-03.tdp:19890/jobhistory)
- [HBase Master 01](https://master-01.tdp:16010/master-status)
- [HBase Master 02](https://master-02.tdp:16010/master-status)
- [Spark History Server](https://master-03.tdp:18081/)
- [Spark3 History Server](https://master-03.tdp:18083/)
- [Ranger Admin](https://master-03.tdp:6182/index.html)
- [JupyterHub](https://master-03.tdp:8000/)

**Note:** All the WebUIs are Kerberized, you need to have a working Kerberos client on your host, configure the KDC in your `/etc/krb5.conf` file and obtain a valid ticket. You can also access the WebUIs through [Knox](#knox).

## Customised Deployment

Each of the below sections includes a high-level explanation of each possible step of TDP deployment.

### Environment Setup

Execute the `setup.sh` script to create the project directories needed and clone stable or latest Ansible TDP collections. It also downloads the TDP binaries from their GitHub releases (e.g., [Hadoop](https://github.com/TOSIT-IO/hadoop/releases/tag/hadoop-project-dist-3.1.1-TDP-0.1.0-SNAPSHOT)).

**Note:** The list of TDP binaries needed for deployment is maintained in the `scripts/tdp-release-uris.txt` file.

```bash
# Get stable tdp-collection
./scripts/setup.sh
# Get latest tdp-collection, tdp-collection-extras, tdp-collection-prerequisites, and vagrant
./scripts/setup.sh -e extras -e observability -e prerequisites -e vagrant -r latest
```

### Configure infrastructure

#### Use TDP Vagrant

To use `tdp-vagrant` it is necessary to use the `-e vagrant` option when using `setup.sh`.

You can define `vagrant.yml` file to update the machine resources according to your machine's RAM and core count (3Gb of RAM and 4 cores is ideal for the master nodes). The file `tdp-vagrant/vagrant.yml` contains default values.

```bash
cp tdp-vagrant/vagrant.yml .
# Now you can edit ./vagrant.yml
```

**Important:** Do not modify `tdp-vagrant/vagrant.yml` to make it easier to update git submodule. The Vagrantfile will read `vagrant.yml` in the current directory and fallback to `tdp-vagrant/vagrant.yml`.

Start VMs with `vagrant` command.

```bash
vagrant up
```

For TDP Vagrant usage see https://github.com/TOSIT-IO/tdp-vagrant.

**Note:** The `helper.sh` script can generate the list of hosts in the cluster. Add the generated lines to your `/etc/hosts` file to resolve the local nodes from your shell or browser.

```bash
./scripts/helper.sh -h
```

### Configure prerequisites

To use `tdp-collection-prerequisites` it is necessary to use the `-e prerequisites` option when using `setup.sh`.

```bash
ansible-playbook ansible_collections/tosit/tdp_prerequisites/playbooks/all.yml
```

This playbook deploys the following services: Chrony, a CA, a LDAP, a KDC, a PostgreSQL.

For TDP prerequisites usage see https://github.com/TOSIT-IO/tdp-collection-prerequisites.

### Core Services Deployment

#### TDP lib command

```bash
tdp deploy
```

This command deploys all core and extra (if enable during setup) services.

For TDP lib usage see https://github.com/TOSIT-IO/tdp-lib.

#### Main playbook

```bash
ansible-playbook ansible_collections/tosit/tdp/playbooks/meta/all.yml
```

This playbook deploys the following services: Exporter, ZooKeeper, Hadoop core (HDFS, YARN, MapReduce), Ranger, Hive, Spark (2 and 3), HBase and Knox. **It does not deploy extras services (see [Extras Services Deployment](#extras-services-deployment) to deploy it).**

For TDP usage see https://github.com/TOSIT-IO/tdp-collection.

#### Exporter

```bash
ansible-playbook ansible_collections/tosit/tdp/playbooks/meta/exporter.yml
```

#### Zookeeper

Deploys Apache ZooKeeper to the `[zk]` Ansible group and starts a 3 node Zookeeper Quorum.

```bash
ansible-playbook ansible_collections/tosit/tdp/playbooks/meta/zookeeper.yml
```

_Run `echo stat | nc localhost 2181` from any node in the `[zk]` group to see its ZooKeeper status._

#### Ranger

Deploys Ranger to the `[ranger_admin]` Ansible group.

_Note that any changes to the `[ranger_admin]` hosts should also be reflected in the `[hadoop client group`]._

```
ansible-playbook ansible_collections/tosit/tdp/playbooks/meta/ranger.yml
```

The Ranger UI can be accessed at the address `https://<master-02.tdp ip>:6182/login.jsp` and the user `admin` and password `RangerAdmin123` (assuming default `ranger_admin_password` parameter). You may need to import the `root.pem` certificate authority into your browser or accept the SSL exception.

#### Launch HDFS, YARN & MapReduce

Launches HDFS, YARN, and deploys MapReduce clients.

```bash
ansible-playbook ansible_collections/tosit/tdp/playbooks/meta/hadoop.yml
ansible-playbook ansible_collections/tosit/tdp/playbooks/meta/hdfs.yml
ansible-playbook ansible_collections/tosit/tdp/playbooks/meta/yarn.yml
ansible-playbook ansible_collections/tosit/tdp/playbooks/utils/hdfs_user_homes.yml
```

`tdp_user` can access and write to its HDFS user directory:

```bash
# From edge-01.tdp
sudo su - tdp_user
kinit -ki
echo "This is the first line." | hdfs dfs -put - /user/tdp_user/test-file.txt
echo "This is the second (appended) line." | hdfs dfs -appendToFile - /user/tdp_user/test-file.txt
hdfs dfs -cat /user/tdp_user/test-file.txt
```

#### Hive

Deploys Hive to the `[hive_s2]` Ansible group. HDFS filesystem is created and the service is launched.

```
ansible-playbook ansible_collections/tosit/tdp/playbooks/meta/hive.yml
```

To interact with Hive, use the `beeline` CLI:

```bash
# From edge-01.tdp
sudo su - tdp_user
kinit -ki
export hive_truststore_password='Truststore123!'

# Connect to a random HiveServer2 using ZooKeeper
beeline -u "jdbc:hive2://master-01.tdp:2181,master-02.tdp:2181,master-03.tdp:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2;sslTrustStore=/etc/ssl/certs/truststore.jks;trustStorePassword=${hive_truststore_password}"

# Or directly to a HiveServer2
beeline -u "jdbc:hive2://master-03.tdp:10001/;principal=hive/_HOST@REALM.TDP;transportMode=http;httpPath=cliservice;ssl=true;sslTrustStore=/etc/ssl/certs/truststore.jks;trustStorePassword=${hive_truststore_password}"

# You can also use `beeline` alone which will default to the ZooKeeper mode
beeline
```

From the Beeline shell:

```hql
# Create the database
CREATE DATABASE IF NOT EXISTS tdp_user LOCATION '/user/tdp_user/warehouse/tdp_user.db';
USE tdp_user;

# Examine the database
SHOW DATABASES;
SHOW TABLES;

# Modify the database
CREATE TABLE IF NOT EXISTS table1 (
  col1 INT COMMENT 'Integer Column',
  col2 STRING COMMENT 'String Column'
);

# Examine the database
SHOW TABLES;

# Modify the database table
INSERT INTO TABLE table1 VALUES (1, 'one'), (2, 'two');

# Examine the database table
SELECT * FROM table1;
```

#### Spark

Deploys spark installations to the `[spark_hs]` and the `[spark_client]` Ansible group.

```
ansible-playbook ansible_collections/tosit/tdp/playbooks/meta/spark.yml
```

To submit a Spark application:

```bash
# From edge-01.tdp
sudo su - tdp_user
kinit -ki

# Run a spark application locally
spark-submit --class org.apache.spark.examples.SparkPi --master local[4]  /opt/tdp/spark/examples/jars/spark-examples_2.11-2.3.5-TDP-0.1.0-SNAPSHOT.jar 100

# Or spark-submit a spark application to yarn
spark-submit --class org.apache.spark.examples.SparkPi --master yarn  /opt/tdp/spark/examples/jars/spark-examples_2.11-2.3.5-TDP-0.1.0-SNAPSHOT.jar 100
```

**Note:** Other Spark CLIs are available: `pyspark`, `spark-shell`, `spark-sql`.

#### Spark 3

Deploys spark3 installations to the `[spark3_hs]` and the `[spark3_client]` Ansible group.

```
ansible-playbook ansible_collections/tosit/tdp/playbooks/meta/spark3.yml
```

Spark 3 is installed alongside Spark 2 and can be used exactly the same way. The Spark 3 CLIs are: `spark3-submit`, `spark3-shell`, `spark3-sql`, `pyspark3`.

#### HBase

Deploys HBase masters, regionservers, rest and clients to the `[hbase_master]`, `[hbase_rs]`, `[hbase_rest]` and `[hbase_client]` Ansible groups respectively.

```
ansible-playbook ansible_collections/tosit/tdp/playbooks/meta/hbase.yml
```

As `tdp_user` on `edge-01`, obtain a Kerberos TGT with the command `kinit -ki` and access the HBase shell with the command `hbase shell`.

Commands such as the below can be used to test your HBase deployment:

```
list
list_namespace
create 'tdp_user_table', 'cf'
put 'tdp_user_table', 'row1', 'cf:testColumn', 'testValue'
disable 'tdp_user_table'
drop 'tdp_user_table'
```

#### Knox

Deploys Knox Gateway on the `[knox]` Ansible group:

```
ansible-playbook ansible_collections/tosit/tdp/playbooks/meta/knox.yml
```

You can then access the WebUIs of the TDP services through Knox:

- [HDFS NN](https://edge-01.tdp:8443/gateway/tdpldap/hdfs)
- [YARN RM](https://edge-01.tdp:8443/gateway/tdpldap/yarn)
- [MapReduce Job History Server](https://edge-01.tdp:8443/gateway/tdpldap/jobhistory)
- [HBase Master](https://edge-01.tdp:8443/gateway/tdpldap/hbase/webui/master/master-status?host=master-01.tdp&port=16010)
- [Spark History Server](https://edge-01.tdp:8443/gateway/tdpldap/sparkhistory)
- [Spark3 History Server](https://edge-01.tdp:8443/gateway/tdpldap/spark3history)
- [Ranger Admin](https://edge-01.tdp:8443/gateway/tdpldap/ranger)

_Note: You can login to Knox using the `tdp_user` that is created in the next step._

### Extras Services Deployment

#### Livy

Deploys Livy Server on the `[livy_server]` group hosts:

```bash
ansible-playbook ansible_collections/tosit/tdp_extra/playbooks/meta/livy.yml
```

The Livy Server can be accessed at https://edge-01.tdp:8998 After deployment, one can create a Spark session and interact with it through cURL:

```bash
# From edge-01.tdp
sudo su - tdp_user
kinit -ki

# Create a session
curl -k -u : --negotiate -X POST https://edge-01.tdp:8998/sessions \
  -d '{"kind": "pyspark"}' -H 'Content-Type: application/json'
# Get the session status (wait until it is "idle")
curl -k -u : --negotiate -X GET https://edge-01.tdp:8998/sessions
# Submit a snippet of code to the session
curl -k -u : --negotiate -X POST https://edge-01.tdp:8998/sessions/0/statements \
  -d '{"code": "1 + 1"}' -H 'Content-Type: application/json'
# Get the statement result
curl -k -u : --negotiate -X GET https://edge-01.tdp:8998/sessions/0/statements/0
```

#### Livy for Spark 3

Another Livy server is deployed for Spark 3 on the `[livy-spark3_server]` group hosts:

```bash
ansible-playbook ansible_collections/tosit/tdp_extra/playbooks/meta/livy-spark3.yml
```

The default port is different than the regular Livy server: `8999` instead of `8998`.

#### Zookeeper Kafka

Deploys Apache ZooKeeper to the `[zk_kafka]` Ansible group and starts a 3 node Zookeeper Quorum dedicated to Kafka.

```bash
ansible-playbook ansible_collections/tosit/tdp_extra/playbooks/meta/zookeeper-kafka.yml
```

#### Kafka

Deploys a Kafka cluster on the `[kafka_broker]` group hosts:

```bash
ansible-playbook ansible_collections/tosit/tdp_extra/playbooks/meta/kafka.yml
```

The Kafka CLIs are available on the edge node for all users and client properties files are in `/etc/kafka/conf/*.properties`. After deployment, one can interact with Kafka from `edge-01.tdp`:

```sh
# From edge-01.tdp
sudo su - tdp_user
kinit -ki

# Create a topic
kafka-topics.sh --create --topic test-topic \
  --command-config /etc/kafka/conf/client.properties
# Write messages to the topic
kafka-console-producer.sh --topic test-topic \
  --producer.config /etc/kafka/conf/producer.properties
>Hello there
>I am writting messages to a Kafka topic
>How cool is that?
>^C # CTRL+C to leave the console producer
# Read all messages from the topic
kafka-console-consumer.sh --topic test-topic --from-beginning \
  --consumer.config /etc/kafka/conf/consumer.properties
```

### Utils

#### Configure HDFS user home directories

Create, update, remove HDFS user home directories.

```
ansible-playbook ansible_collections/tosit/tdp/playbooks/utils/hdfs_user_homes.yml
```

_Additional users can be added to the Ansible variable `hdfs_user_homes` if required._

When adding users following the Ranger Usersync deployment, you will need to add or update Ranger policies including these new users. You must wait for Ranger Usersync to poll users from LDAP or you can restart the Ranger Usersync using the following playbook:

```
ansible-playbook ansible_collections/tosit/tdp/playbooks/ranger_usersync_restart.yml
```

#### Configure Ranger policies

Create, update, remove Ranger policies.

```
ansible-playbook ansible_collections/tosit/tdp/playbooks/utils/ranger_policies.yml
```

_Additional policies can be added to the Ansible variable `ranger_policies` if required._
