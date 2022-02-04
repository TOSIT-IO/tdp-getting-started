# Getting Started with TDP

Launch a fully featured virtual TDP Hadoop cluster with a single command _or_ customise the infrastructure and components of your cluster with 1 command per component.

## Requirements

- ansible >= 2.9.6 (to execute the playbooks)
- vagrant >= 2.29 (to launch and manage the VMs)
- The Python package `jmespath` (an Ansible dependency for json querying)

## Quick Start

The below steps will deploy a TDP cluster using the parameters in the `inventory` directory.
The Ansible `host` file and the `Vagrantfile` will both be generated using the `hosts` variable in `inventory/all.yml`.

```bash
git clone https://github.com/TOSIT-IO/tdp-getting-started.git
cd getting-started # Execute all commands from here
sh ./setup.sh # Setup local env and clone latest tdp-ansible-roles
# MANUAL STEP: Copy binaries to files directory in project root
ansible-playbook deploy-all.yml
```

## Web UIs

- [HDFS NN Master 01](https://master-01.tdp:9871/dfshealth.html)
- [HDFS NN Master 02](https://master-02.tdp:9871/dfshealth.html)
- [YARN RM Master 01](https://master-01.tdp:8090/cluster/apps)
- [YARN RM Master 02](https://master-02.tdp:8090/cluster/apps)
- [Ranger Admin](https://master-02.tdp:6182/index.html)

## Customised deployment

Each of the below sections includes a high level explanation of each possible step of a deployment using this repository.

### Environment Setup

Execute the `setup.sh` script to create the project directories needed and clone the latest tdp-ansible-roles.

```bash
sh ./setup.sh
```

### Single command to deploy all services

```
ansible-playbook deploy-all.yml
```

The first action in `deploy-all.yml` is to run the `launch-VMs.sh` script which spawns and configures a set of 7 virtual machines at static IPs described in the `inventory/hosts` file.

**Important:**

- To change the static IPs you must update **both** the `Vagrantfile` and the `inventory/hosts` files
- Update the machine resources assigned to the VMs in the `Vagrantfile` according to you machine's RAM and core count (3Gb of RAM and 4 cores is ideal for the master nodes).

_Check the status of the created VMs with the command `vagrant status`, and ssh to them with the command `vagrant ssh <target-ansible-host>`_

**SSH Key Generation and Deployment**

It is **optionally** possible to generate a new ssh key pair and deploy the public key to each host, though `vagrant ssh <ansible-host>` works just fine in the context of this getting-started cluster. Use the below command to generate SSH keys and deploy them throughout the cluster:

```
ansible-playbook deploy-ssh-key.yml
```

**Certificate Authority and Certificates**

Creates a certificate authority at the `[ca]` ansible group and distributes signed certificates and keys to each VM.

```
ansible-playbook deploy-ca.yml
```

_The certificates will also be downloaded to the `files/certs` local project folder._

**_Kerberos_**

Launches a KDC at the `[kdc]` ansible group and installs kerberos clients on each of the VMs.

```
ansible-playbook deploy-kerberos.yml
```

_After this, you can login as the kerberos admin from any VM with the command `kinit admin/admin` and the passwork `admin`._

**Zookeeper**

Deploys Apache ZooKeeper to the the `[zk]` ansible group and starts a 3 node Zookeeper quorum.

```
ansible-playbook deploy-zookeeper.yml
```

_Run `echo stat | nc localhost 2181` from any node in the `[zk]` group to see it's zookeeper status._

**Launch HDFS, YARN & MapReduce**

Launches HDFS, YARN and deploy MapReduce clients.

```
ansible-playbook deploy-hadoop.yml
```

The following code snippets demonstrate that:

- From master-01.tdp
```bash
kinit -kt /etc/security/keytabs/nn.service.keytab nn/master-01.tdp@REALM.TDP
hdfs dfs -mkdir -p /user/tdp_user
hdfs dfs -chown -R tdp_user:tdp_user /user/tdp_user
```

- That tdp_user can access and write to their hdfs user directory:
  - From edge-01.tdp

  ```bash
  su tdp_user
  kinit -kt ~/.keytabs/tdp_user.principal.keytab tdp_user@REALM.TDP
  echo "This is the first line." | hdfs dfs -put - /user/tdp_user/testFile
  echo "This is the second (appended) line." | hdfs dfs -appendToFile - /user/tdp_user/testFile
  hdfs dfs -cat /user/tdp_user/testFile
  ```

- That writes using the tdp_user from edge-01.tdp can be read from master-01.tdp:
  - From master-01.tdp

  ```bash
  su tdp_user
  kinit -kt ~/.keytabs/tdp_user.principal.keytab tdp_user@REALM.TDP
  hdfs dfs -cat /user/tdp_user/testFile
  ```

**Postgres**

Deploys postgres instance to `[postgres]` ansible group. Listens for request on from all IPs but but only trusts those specified in the /etc/hosts file.

The DBA user **postgres** is created with the password **postgres**.

```bash
ansible-playbook deploy-postgres.yml
```

**Ranger**

Creates a suitably configured postgres database to the `[postgresql]` ansible group, then deploys Ranger to the `[ranger_admin]` ansible group.

_Note that any changes to the `[ranger_admin]` hosts should be also be reflected in the `[hadoop client group`]_

```
ansible-playbook deploy-ranger.yml
```

The Ranger UI can be accessed at the address https://<master-02.tdp ip>:6182/login.jsp and the user `admin` and password `RangerAdmin123` (assuming default _ranger_admin_password_ parameter). You may need to import the `root.pem` certificate authority into your browser or accept the SSL exception.

**Hive**

Deploys hive to the `[hive_s2]` ansible group. HDFS filesystem is created and the service is launched.

```
ansible-playbook deploy-hive.yml
```

_Execute the following code blocks to execute some hive queries using beeline:_

The following code snippets:

- Create an hdfs user directory for tdp_user (this block is is the same as in the deploy hdfs example above):
  - _From master-01.tdp:_
  ```bash
  kinit -kt /etc/security/keytabs/nn.service.keytab nn/master-01.tdp@REALM.TDP
  hdfs dfs -mkdir -p /user/tdp_user
  hdfs dfs -chown -R tdp_user /user/tdp_user
  ```
- Authenticate as tdp_user from one of the hive_s2 nodes and enter the beeline client interface:
  - _From edge-01.tdp:_
  ```bash
  su tdp_user
  kinit -kt ~/.keytabs/tdp_user.principal.keytab tdp_user@REALM.TDP
  export hive_truststore_password=Truststore123!

  # Either via ZooKeeper
  /opt/tdp/hive/bin/hive --config /etc/hive/conf --service beeline -u "jdbc:hive2://master-01.tdp:2181,master-02.tdp:2181,master-03.tdp:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2;sslTrustStore=/etc/ssl/certs/truststore.jks;trustStorePassword=${hive_truststore_password}"

  # Or directly to a HiveServer2
  /opt/tdp/hive/bin/hive --config /etc/hive/conf --service beeline -u "jdbc:hive2://master-03.tdp:10001/;principal=hive/_HOST@REALM.TDP;transportMode=http;httpPath=cliservice;ssl=true;sslTrustStore=/etc/ssl/certs/truststore.jks;trustStorePassword=${hive_truststore_password}"

  # You can also use beeline_auto which is a preconfigured beeline command to connect via zookeeper
  beeline_auto
  ```

_Note that all necessary ranger policies have been deployed automatically as part of the `deploy-hive.yml` process_

From the beeline client, execute the following code blocks to interact with Hive:

```bash
# Create the database
CREATE DATABASE tdp_user_db;
USE tdp_user_db;

# Examine the database
SHOW DATABASES;
SHOW TABLES;

# Modify the database
CREATE TABLE IF NOT EXISTS table1
 (col1 int COMMENT 'Integer Column',
 col2 string COMMENT 'String Column'
 );

# Examine the database
SHOW TABLES;

# Modify the database table
INSERT INTO TABLE table1 VALUES (1, 'one'), (2, 'two');

# Examine the database table
SELECT * FROM table1;
```

**Spark**

Deploys spark installations to the `[spark_hs]` and the `[spark_client]` ansible group.

```
ansible-playbook deploy-spark.yml
```

_Execute the following command from any node in the `[spark_client]` ansible group to spark-submit an example jar from the spark installation:_

- _From edge-01.tdp:_
```bash
su tdp_user
kinit -kt ~/.keytabs/tdp_user.principal.keytab tdp_user@REALM.TDP
export SPARK_CONF_DIR=/etc/spark/conf

# Run a spark application locally
/opt/tdp/spark/bin/spark-submit --class org.apache.spark.examples.SparkPi --master local[4]  /opt/tdp/spark/examples/jars/spark-examples_2.11-2.3.5-TDP-0.1.0-SNAPSHOT.jar 100

# Or spark-submit a spark application to yarn
/opt/tdp/spark/bin/spark-submit --class org.apache.spark.examples.SparkPi --master yarn  /opt/tdp/spark/examples/jars/spark-examples_2.11-2.3.5-TDP-0.1.0-SNAPSHOT.jar 100
```

_Note: Other spark interfaces are also found in the `/opt/tdp/spark/bin` dir, such as pyspark, spark-shell, spark-sql, sparkR etc._

**HBase**

Deploys HBase masters, regionservers, rest and clients to the `[hbase_master]`, `[hbase_rs]`, `[hbase_rest]` and `[hbase_client]` ansible groups respectively.

```
ansible-playbook deploy-hbase.yml
```

As tdp_user on an `[hbase_client]` host, obtain a Kerberos TGT with the command `kinit -kt /home/tdp_user/.keytabs/tdp_user.principal.keytab tdp_user@REALM.TDP` and access the HBase shell with the command `/opt/tdp/hbase/bin/hbase --config /etc/hbase/conf shell`.

Commands such as the below can be used to test your HBase deployment:

```
list
list_namespace
create 'testTable' 'cf'
put 'testTable', 'row1', 'cf:testColumn', 'testValue'
disable 'testTable'
drop 'testTable'
```

**Create Cluster Users**

The below command creates:

- Unix users _tdp_user_ and _tdp-admin_ on each node of the cluster
- A kerberos principal named `<user>/<fqdn>@<realm>` with keytabs at `/home/<user>/.ssh/<user>.kerberos.keytab`
- All users are added to the users group
- Users with 'admin' in the name will also be added to the group 'tdp-admin'

```
ansible-playbook deploy-users.yml
```

_Additional users can be added to the ansible-playbook parameter **users** in the `deploy-users.yml` if required_

**Autostart Cluster Services**

As the getting started cluster is entirely virtual, when you switch off your computer the VMs will also turn off. To simplify getting your cluster up and running after booting up, the following command will launch a playbook which auto starts the necessary services to run the getting started cluster services:

```yaml
ansible-playbook deploy-service-start-on-boot-policies.yml
```
