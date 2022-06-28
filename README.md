# Getting Started with TDP

Launch a fully-featured virtual TDP Hadoop cluster with a single command _or_ customize the infrastructure and components of your cluster with 1 command per component.

- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [Web UIs Links](#web-uis-links)
- [Customised Deployment](#customised-deployment)
  - [Environment Setup](#environment-setup)
  - [Configuration files generation](#configuration-files-generation)
  - [Services Deployment](#services-deployment)

## Requirements

- Ansible >= 2.9.6 (to execute the playbooks)
- Vagrant >= 2.2.19 (to launch and manage the VMs)
- VirtualBox >= 6.1.26
- The Python package `jmespath` (an Ansible dependency for JSON parsing/querying)
- Unzip (to execute the setup scripts)
- `jq` required to execute helper script

## Quick Start

The below steps will deploy a TDP cluster using the parameters in the `inventory` directory.
The Ansible `host` file and the `Vagrantfile` will both be generated using the `hosts` variable in `inventory/all.yml`.

```bash
# Clone project from version control
git clone https://github.com/TOSIT-IO/tdp-getting-started.git
# Move into project dir
cd tdp-getting-started
# Setup local env with stable tdp-collections
./scripts/setup.sh -r stable
# Generate Vagrantfile and ansible hosts file from inventory
ansible-playbook generate-node-deployment-config.yml
# Install centos/7 vagrant box
vagrant box add centos/7 --provider virtualbox
# Deploy TDP cluster
ansible-playbook deploy-all.yml
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

**Note:** All the WebUIs are Kerberized, you need to have a working Kerberos client on your host, configure the KDC in your `/etc/krb5.conf` file and obtain a valid ticket. You can also access the WebUIs through [Knox](#knox).

## Customised Deployment

Each of the below sections includes a high-level explanation of each possible step of TDP deployment.

### Environment Setup

Execute the `setup.sh` script to create the project directories needed and clone the latest ansible TDP roles. It also downloads the TDP binaries from their GitHub releases (e.g., [Hadoop](https://github.com/TOSIT-IO/hadoop/releases/tag/hadoop-project-dist-3.1.1-TDP-0.1.0-SNAPSHOT)).

**Note:** The list of TDP binaries needed for deployment is maintained in the `scripts/tdp-release-uris.txt` file.

```bash
./scripts/setup.sh
```

### Configuration files generation

```
ansible-playbook generate-node-deployment-config.yml
```

This playbook will generate the `Vagrantfile` and the `inventory/hosts` file.

**Important:**

- Update the machine resources assigned to the VMs in the `Vagrantfile` according to your machine's RAM and core count (3Gb of RAM and 4 cores is ideal for the master nodes).

**Note:** The `helper.sh` script can generate the list of hosts in the cluster. Add the generated lines to your `/etc/hosts` file to resolve the local nodes from your shell or browser.

```bash
./scripts/helper.sh -h
```

### Services Deployment

#### Main playbook

```
ansible-playbook deploy-all.yml
```

This playbook deploys the following services: a CA, an LDAP, a KDC, PostgreSQL, ZooKeeper, Hadoop core (HDFS, YARN, MapReduce), Ranger, Hive, Spark (2 and 3), HBase and Knox.

The first action in `deploy-all.yml` is to run the `vagrant-up-parallel.sh` script which spawns and configures a set of 7 virtual machines at static IPs described in the `inventory/hosts` file.

_Check the status of the created VMs with the command `vagrant status`, and ssh to them with the command `vagrant ssh <target-ansible-host>`._

#### SSH Key Generation and Deployment

It is **optionally** possible to generate a new ssh key pair and deploy the public key to each host, though `vagrant ssh <ansible-host>` works just fine in the context of this getting-started cluster. Use the below command to generate SSH keys and deploy them throughout the cluster:

```
ansible-playbook deploy-ssh-key.yml
```

#### Certificate Authority and Certificates

Creates a certificate authority at the `[ca]` Ansible group and distributes signed certificates and keys to each VM.

```
ansible-playbook deploy-ca.yml
```

_The certificates will also be downloaded to the `files/certs` local project folder._

#### Kerberos

Launches a KDC on the `[kdc]` group hosts, launches an LDAP on the `[ldap]` group hosts and installs Kerberos clients on each of the VMs.

```
ansible-playbook deploy-ldap-kerberos.yml
```

_After this, you can log in as the Kerberos admin from any VM with the command `kinit admin/admin` and the password `admin`._

#### Zookeeper

Deploys Apache ZooKeeper to the `[zk]` Ansible group and starts a 3 node Zookeeper Quorum. Also deploys a second ZooKeeper cluster dedicated to Kafka on the same nodes.

```
ansible-playbook deploy-zookeeper.yml
```

_Run `echo stat | nc localhost 2181` from any node in the `[zk]` group to see its ZooKeeper status._

#### Launch HDFS, YARN & MapReduce

Launches HDFS, YARN, and deploys MapReduce clients.

```
ansible-playbook deploy-hadoop.yml
```

The following code snippets demonstrate that:

- From `master-01.tdp`

```bash
kinit -kt /etc/security/keytabs/nn.service.keytab nn/master-01.tdp@REALM.TDP
hdfs dfs -mkdir -p /user/tdp_user
hdfs dfs -chown -R tdp_user:tdp_user /user/tdp_user
```

- That `tdp_user` can access and write to its HDFS user directory:

  - From `edge-01.tdp`

  ```bash
  sudo su tdp_user
  kinit -kt ~/tdp_user.keytab tdp_user@REALM.TDP
  echo "This is the first line." | hdfs dfs -put - /user/tdp_user/testFile
  echo "This is the second (appended) line." | hdfs dfs -appendToFile - /user/tdp_user/testFile
  hdfs dfs -cat /user/tdp_user/testFile
  ```

- That writes using the `tdp_user` from `edge-01.tdp` can be read from `master-01.tdp`:

  - From `master-01.tdp`

  ```bash
  sudo su tdp_user
  kinit -kt ~/tdp_user.keytab tdp_user@REALM.TDP
  hdfs dfs -cat /user/tdp_user/testFile
  ```

#### PostgreSQL

Deploys PostgreSQL instance to `[postgres]` Ansible group. Listens for requests from all IPs but only trusts those specified in the `/etc/hosts` file.

The DBA user `postgres` is created with the password `postgres`.

```bash
ansible-playbook deploy-postgres.yml
```

#### Ranger

Creates a suitably configured PostgreSQL database to the `[postgresql]` Ansible group, then deploys Ranger to the `[ranger_admin]` Ansible group.

_Note that any changes to the `[ranger_admin]` hosts should also be reflected in the `[hadoop client group`]._

```
ansible-playbook deploy-ranger.yml
```

The Ranger UI can be accessed at the address `https://<master-02.tdp ip>:6182/login.jsp` and the user `admin` and password `RangerAdmin123` (assuming default `ranger_admin_password` parameter). You may need to import the `root.pem` certificate authority into your browser or accept the SSL exception.

#### Hive

Deploys Hive to the `[hive_s2]` Ansible group. HDFS filesystem is created and the service is launched.

```
ansible-playbook deploy-hive.yml
```

_Execute the following code blocks to execute some hive queries using beeline:_

The following code snippets:

- Create an HDFS user directory for `tdp_user` (this block is is the same as in the deploy HDFS example above):
  - _From `master-01.tdp`:_
  ```bash
  sudo su
  kinit -kt /etc/security/keytabs/nn.service.keytab nn/master-01.tdp@REALM.TDP
  hdfs dfs -mkdir -p /user/tdp_user
  hdfs dfs -chown -R tdp_user /user/tdp_user
  ```
- Authenticate as `tdp_user` from one of the `hive_s2` nodes and enter the Beeline client interface:

  - _From `edge-01.tdp`:_

  ```bash
  sudo su tdp_user
  kinit -kt ~/tdp_user.keytab tdp_user@REALM.TDP
  export hive_truststore_password=Truststore123!

  # Either via ZooKeeper
  /opt/tdp/hive/bin/hive --config /etc/hive/conf --service beeline -u "jdbc:hive2://master-01.tdp:2181,master-02.tdp:2181,master-03.tdp:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2;sslTrustStore=/etc/ssl/certs/truststore.jks;trustStorePassword=${hive_truststore_password}"

  # Or directly to a HiveServer2
  /opt/tdp/hive/bin/hive --config /etc/hive/conf --service beeline -u "jdbc:hive2://master-03.tdp:10001/;principal=hive/_HOST@REALM.TDP;transportMode=http;httpPath=cliservice;ssl=true;sslTrustStore=/etc/ssl/certs/truststore.jks;trustStorePassword=${hive_truststore_password}"

  # You can also use `beeline_auto` which is a preconfigured Beeline command to connect via ZooKeeper
  beeline_auto
  ```

_Note that all necessary Ranger policies have been deployed automatically as part of the `deploy-hive.yml` process._

From the Beeline client, execute the following code blocks to interact with Hive:

```bash
# Create the database
CREATE DATABASE IF NOT EXISTS tdp_user_db;
USE tdp_user_db;

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
ansible-playbook deploy-spark.yml
```

_Execute the following command from any node in the `[spark_client]` Ansible group to `spark-submit` an example jar from the Spark installation:_

- _From `edge-01.tdp`:_

```bash
su tdp_user
kinit -kt ~/tdp_user.keytab tdp_user@REALM.TDP

# Run a spark application locally
spark-submit --class org.apache.spark.examples.SparkPi --master local[4]  /opt/tdp/spark/examples/jars/spark-examples_2.11-2.3.5-TDP-0.1.0-SNAPSHOT.jar 100

# Or spark-submit a spark application to yarn
spark-submit --class org.apache.spark.examples.SparkPi --master yarn  /opt/tdp/spark/examples/jars/spark-examples_2.11-2.3.5-TDP-0.1.0-SNAPSHOT.jar 100
```

_Note: Other spark interfaces are also found in the `/opt/tdp/spark/bin` directory, such as `pyspark`, `spark-shell`, `spark-sql`, `sparkR` etc._

#### Spark 3

Deploys spark3 installations to the `[spark3_hs]` and the `[spark3_client]` Ansible group.

```
ansible-playbook deploy-spark3.yml
```

Spark 3 is installed alongside Spark 2 and can be used exactly the same way. The Spark 3 CLIs are: `spark3-submit`, `spark3-shell`, `spark3-sql`, `pyspark3`.

#### HBase

Deploys HBase masters, regionservers, rest and clients to the `[hbase_master]`, `[hbase_rs]`, `[hbase_rest]` and `[hbase_client]` Ansible groups respectively.

```
ansible-playbook deploy-hbase.yml
```

As `tdp_user` on an `[hbase_client]` host, obtain a Kerberos TGT with the command `kinit -kt ~/tdp_user.keytab tdp_user@REALM.TDP` and access the HBase shell with the command `/opt/tdp/hbase/bin/hbase --config /etc/hbase/conf shell`.

Commands such as the below can be used to test your HBase deployment:

```
list
list_namespace
create 'testTable', 'cf'
put 'testTable', 'row1', 'cf:testColumn', 'testValue'
disable 'testTable'
drop 'testTable'
```

#### Knox

Deploys Knox Gateway on the `[knox]` Ansible group:

```
ansible-playbook deploy-knox.yml
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

#### Livy

Deploys Livy Server on the `[livy_server]` group hosts:

```bash
ansible-playbook deploy-livy.yml
```

The Livy Server can be accessed at https://edge-01.tdp:8998 After deployment, one can create a Spark session and interact with it through cURL:

```bash
# From edge-01.tdp
sudo su tdp_user
kinit -kt ~/tdp_user.keytab tdp_user@REALM.TDP

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
ansible-playbook deploy-livy-spark3.yml
```

The default port is different than the regular Livy server: `8999` instead of `8998`.

#### Kafka

Deploys a Kafka cluster on the `[kafka_broker]` group hosts:

```bash
ansible-playbook deploy-kafka.yml
```

The Kafka CLIs are available on the edge node for all users and client properties files are in `/etc/kafka/conf/*.properties`. After deployment, one can interact with Kafka from `edge-01.tdp`:

```sh
# From edge-01.tdp
sudo su tdp_user
kinit -kt ~/tdp_user.keytab tdp_user@REALM.TDP

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

#### Create Cluster Users

The below command creates:

- Unix users `tdp_user` and `tdp-admin` on each node of the cluster
- A Kerberos principal named `<user>/<fqdn>@<realm>` with keytabs at `/home/<user>/.ssh/<user>.kerberos.keytab`
- All users are added to the users' group
- Users with `admin` in the name will also be added to the group `tdp-admin`

```
ansible-playbook deploy-users.yml
```

_Additional users can be added to the Ansible playbook parameter `users` in the `deploy-users.yml` if required._

#### Autostart Cluster Services

As the getting started cluster is entirely virtual, when you switch off your computer the VMs will also turn off. To simplify getting your cluster up and running after booting up, the following command will launch a playbook that auto starts the necessary services to run the getting started cluster services:

```yaml
ansible-playbook deploy-service-start-on-boot-policies.yml
```
