# Getting Started with TDP

Launch a fully featured virtual TDP Hadoop cluster with a single command *or* customise the infrastructure and components of your cluster with 1 command per component (e.g. `ansible-playbook deploy_<item>.yml`).

Each of the below section includes the command to exectue to deploy a component or dependency of the cluster, along with some high level code blocks for you to quickly verify that it is working as intended.

### TL;DR WIP to remove this command
```bash
ansible-playbook deploy-all.yml deploy-hive.yml deploy-ranger-user-policy.yml deploy-spark.yml -K
```

### Requirements
- ansible >= 2.9.6
- vagrant >= 2.29

# Environment Setup

Execute the `setup.sh` script to create the project directories needed, clone the latest tdp-ansible-roles and install any python dependencies. 

```bash
sh ./setup.sh
```

# TDP Deployment

## Single command deploy to deploy all

```
ansible-playbook deploy-all.yml -K
```

The first action in `deploy-all.yml` is to run the `launch-VMs.sh` scri which spawns and configures a set of 7 virtual machines at static IPs described in the `inventory/hosts` file.

**Important to note:**
- To change the static IPs you must update **both** the `Vagrantfile` and the `tdp-hosts` files
- To edit the resources assigned to the vms, update the `Vagrantfile`
- The `-K` parameter requests your superuser password. This is because one of the tdp-ansible-roles delegates privileged commands from your localhost to the VMs. No privileged commands modify anything outside of the VMs and only the `deploy-hdfs-yarn-mapreduce.yml` playbook requires these superuser privileges

*Check the status of the created VMs with the command `vagrant status`, and ssh to them with the cammand `vagrant ssh <target vm name>`*


# deploy-[service/feature].yml Descriptions

The following is a high level description of each of the deploy playbooks in the project root. Some include code snippets to test their functionality.

**SSH Key Generation and Deployment**

It is **optionally** possible to generate a new ssh key pair and deploy the public key to each host. This is optional as `vagrant ssh <ansible-host>` works just fine in the context of this getting-started cluster. To do it, use the following command:

```
ansible-playbook deploy-ssh-key.yml
```

**Certificate Authority and Certificates**

Creates a certificate authority at the `[ca]` ansible group and distributes signed certificates and keys to each VM.

```
ansible-playbook deploy-ca.yml
```

*The certificates will also be downloaded to the `files/certs` local project folder.*

***Kerberos***

Launches a KDC at the `[kdc]` ansible group and installs kerberos clients on each of the VMs.

```
ansible-playbook deploy-kerberos.yml
```

*After this, you can login as the kerberos admin from any VM with the command `kinit admin/admin` and the passwork `admin`.*

**Create Cluster Users**

The below command creates:
  - Unix users *tdp-user* and *tdp-admin* on each node of the cluster
  - A kerberos principal named `<user>/<fqdn>@<realm>` with keytabs at `/home/<user>/.ssh/<user>.kerberos.keytab`
  - All users are added to the users group
  - Users with 'admin' in the name will also be added to the group 'tdp-admin'

```
ansible-playbook deploy-users.yml
```

*Additional users can be added to the ansible-playbook parameter **users** in the `deploy-users.yml` if required*

**Zookeeper**

Deploys Apache ZooKeeper to the the `[zk]` ansible group and starts a 3 node Zookeeper quorum.
  
```
ansible-playbook deploy-zookeeper.yml
```

*Run `echo stat | nc localhost 2181` from any node in the `[zk]` group to see it's zookeeper status.*

**Launch HDFS, Yarn & MapReduce**

Launches a high availability hdfs distributed filesystem. 

```
ansible-playbook deploy-hdfs-yarn-mapreduce.yml -K
```

The following code snippets demonstrate that:
  - The namenode kerberos principal can create an appropriate hdfs user directory for tdp-user:
    
    - *From master-01.tdp:*

      ```bash
      kinit -kt /etc/security/keytabs/nn.service.keytab nn/master-01.tdp@REALM.TDP
      /opt/tdp/hadoop/bin/hdfs --config /etc/hadoop/conf.nn dfs -mkdir -p /user/tdp-user
      /opt/tdp/hadoop/bin/hdfs --config /etc/hadoop/conf.nn dfs -chown -R tdp-user:tdp-user /user/tdp-user
      ```

  - That tdp-user can access and write to their hdfs user directory:

    - *From edge-01.tdp:*

        ```bash
        su tdp-user
        kinit -kt /home/tdp-user/.ssh/tdp-user.principal.keytab tdp-user/edge-01.tdp@REALM.TDP
        echo "This is the first line." | /opt/tdp/hadoop/bin/hdfs --config /etc/hadoop/conf dfs -put - /user/tdp-user/testFile
        echo "This is the second (appended) line." | /opt/tdp/hadoop/bin/hdfs --config /etc/hadoop/conf dfs -appendToFile - /user/tdp-user/testFile
        /opt/tdp/hadoop/bin/hdfs --config /etc/hadoop/conf dfs -cat /user/tdp-user/testFile
        ```

  - That writes using the tdp-user from edge-01.tdp can be read from master-01.tdp:

    - *On master-01.tdp:*

      ```bash
      su tdp-user
      kinit -kt /home/tdp-user/.ssh/tdp-user.principal.keytab tdp-user/master-01.tdp@REALM.TDP
      /opt/tdp/hadoop/bin/hdfs --config /etc/hadoop/conf.nn dfs -cat /user/tdp-user/testFile
      ```

**Postgres**

Deploys postgres instance to `[postgres]` ansible group. Listens for request on from all IPs but but only trusts those specified in the /etc/hosts file.

The DBA user **postgres** is created with the password **postgres**.

```bash
ansible-playbook deploy-postgres.yml
```


**Ranger**

Creates a suitably configured postgres database to the `[postgresql]` ansible group, then deploys Ranger to the `[ranger_admin]` ansible group.

*Note that any changes to the `[ranger_admin]` hosts should be also be reflected in the `[hadoop client group`]*
  

```
ansible-playbook deploy-ranger.yml
```

The Ranger UI can be accessed at the address https://<master-02.tdp ip>:6182/login.jsp and the user `admin` and password `RangerAdmin123` (assuming default *ranger_admin_password* parameter). You may bneed to import the `root.pem` certificate authority into your browser to access.

**Hive**

Deploys hive to the `[hive_s2]` ansible group. HDFS filesystem is created and the service is launched.

```
ansible-playbook deploy-hive.yml
```

*Execute the following code blocks to execute some hive queries using beeline:*

The following code snippets:
  - Create an hdfs user directory for tdp-user (this block is is the same as in the deploy hdfs example above):

    - *From master-01.tdp:*

        ```bash
        kinit -kt /etc/security/keytabs/nn.service.keytab nn/master-01.tdp@REALM.TDP
        /opt/tdp/hadoop/bin/hdfs --config /etc/hadoop/conf.nn dfs -mkdir -p /user/tdp-user
        /opt/tdp/hadoop/bin/hdfs --config /etc/hadoop/conf.nn dfs -chown -R tdp-user /user/tdp-user
        ```

  - Authenticate as tdp-user from one of the hive_s2 nodes and enter the beeline client interface:
  
    - *From master-02.tdp:*

        ``bash
        su tdp-user
        export hive_truststore_password=Truststore123!
        # Either via zookeeper
        kinit -kt /home/tdp-user/.ssh/tdp-user.principal.keytab tdp-user/master-02.tdp@REALM.TDP
        /opt/tdp/hive/bin/hive --config /etc/hive/conf.s2 --service beeline -u "jdbc:hive2://master-01.tdp:2181,master-02.tdp:2181,master-03.tdp:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2;sslTrustStore=/etc/ssl/certs/truststore.jks;trustStorePassword=${hive_truststore_password}"
        # Or directly to a hiveserver
        /opt/tdp/hive/bin/hive --config /etc/hive/conf.s2 --service beeline -u "jdbc:hive2://master-02.tdp:10001/;principal=hive/_HOST@REALM.TDP;transportMode=http;httpPath=cliservice;ssl=true;sslTrustStore=/etc/ssl/certs/truststore.jks;trustStorePassword=${hive_truststore_password}"
        ```
  
  - As there is no ranger user sync configured in this cluster, add the tdp-user manually in the ranger UI at `https://master-02.tdp:6182/index.html` with `admin` and `RangerAdmin123` user and password (assuming default settings used). 
      - Go to *RangerUI > Settings > users/Groups/Roles > Add New User* and create tdp-user
      - Go to  *RangerUI > Service Manager > hive-tdp Policies* and create a policy to allow tdp-user full permissions to database tdp_user_db
      - Go to  *RangerUI > Service Manager > hdfs-tdp Policies* and create a policy to allow tdp-user full read, write and execute permissions in  `/user/tdp-user` hdfs dir
      - Go to  *RangerUI > Service Manager > hdfs-tdp Policies* and create a policy to hive user read, write and execute permissions in  `/user` hdfs dir

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
*Execute the following command from any node in the `[spark_client]` ansible group to spark-submit an example jar from the spark installation:*

```bash
su tdp-user
kinit -kt /home/tdp-user/.ssh/tdp-user.principal.keytab tdp-user/edge-01.tdp@REALM.TDP
export SPARK_CONF_DIR=/etc/spark/conf
/opt/tdp/spark/bin/spark-submit --class org.apache.spark.examples.SparkPi --master yarn --deploy-mode cluster /opt/tdp/spark/examples/jars/spark-examples_2.11-2.3.5-TDP-0.1.0-SNAPSHOT.jar 100
```
