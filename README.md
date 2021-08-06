# Getting Started with TDP

Launch various virtual TDP big data infrastructures in less than 10 commands



## Deployments:


The below command will create the core infrastructure expected by all tdp deployments documented in the guide.

```bash
ansible-playbook deploy-infrastructure.yml
```
It spawns and lightly configures a set of 7 virtual machines at the following default static IPs:

* worker-01 192.168.32.10
* worker-02 192.168.32.11
* worker-03 192.168.32.12
* master-01 192.168.32.13
* master-02 192.168.32.14
* master-03 192.168.32.15
* edge-01 192.168.32.16
* edge-02 192.168.32.17

**Note that:**
- Any change to the IPs should be reflected in boith the `Vagrantfile` and the `tdp-hosts` files.
- Edit the resources assigned to the vms are required in the `Vagrantfile`.

### Kerberos

```
ansible-playbook deploy-kerberos.yml
```

Launches a KDC at `[kdc]` group and installs kerberos clients on each of the 7 nodes.

```
ansible-playbook deploy-ca.yml
```

Creates a certificate authority at `[ca]` and distributes signed certificates and keys to each node.

The certificates will be downloaded to the `files/certs` local project folder.

```
ansible-playbook deploy-zookeeper.yml
```

Deploys Apache ZooKeeper to the the `[zk]` group and starts a 3 node quorum.
  
Run `echo stat | nc localhost 2181` from any node in the `[zk]` group to see it's zookeeper status.

```
ansible-playbook deploy-hdfs-yarn-mapreduce.yml
```

Launches a high availability hdfs distributed filesystem. Verify that it's working with the following steps:
   
Execute this code block **as root from master-01** to create a principal for `edge-01` and set it up to use hdfs:

```bash
# Authenticate as priviledged user nn/master-01@TDP
kinit -kt /etc/security/keytabs/nn.service.keytab nn/master-01@TDP
# Create edge-01 principle and keytab
kadmin -r TDP -p admin/admin -w admin -q "addprinc -randkey edge-01/edge-01@TDP"
kadmin -r TDP -p admin/admin -w admin -q "xst -k edge-01.service.keytab edge-01/edge-01@TDP"
# Create an hdfs directory for edge-01
/opt/tdp/hadoop/bin/hdfs --config /etc/hadoop/conf.nn dfs -mkdir /edge-01
/opt/tdp/hadoop/bin/hdfs --config /etc/hadoop/conf.nn dfs -chown -R edge-01:hadoop /edge-01
```

Execute this code block **as root from edge-01** to create a interact with hdfs:

```bash
# Create a local keytab for edge-01 principal
kadmin -r TDP -p admin/admin -w admin -q "xst -k /etc/security/keytabs/edge-01.service.keytab edge-01/edge-01@TDP"
# Authenticate as edge-01 principal
kinit -kt /etc/security/keytabs/edge-01.service.keytab edge-01/edge-01@TDP
# Add some content to hdfs
echo "This is the first line." | /opt/tdp/hadoop/bin/hdfs --config /etc/hadoop/conf dfs -put - /edge-01/testFile
echo "This is the second (appended) line." | /opt/tdp/hadoop/bin/hdfs --config /etc/hadoop/conf dfs -appendToFile - /edge-01/testFile
# Retrive that content
/opt/tdp/hadoop/bin/hdfs --config /etc/hadoop/conf dfs -cat /edge-01/testFile
```

Execute this code block **as root from master-01** and see that the content added from edge-01 are present:
```bash
# Authenticate
kinit -kt /etc/security/keytabs/nn.service.keytab nn/master-01@TDP
# Check contents of new file
/opt/tdp/hadoop/bin/hdfs --config /etc/hadoop/conf.nn dfs -cat /edge-01/testFile
```
