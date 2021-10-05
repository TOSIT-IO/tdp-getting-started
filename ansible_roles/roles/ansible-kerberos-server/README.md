ansible-kerberos-server
=======================


**ansible-kerberos-server** is an Ansible role to easily install a Kerberos Server.

This role was a simplified fork of ["AlberTajuelo/ansible-kerberos-server
"](https://github.com/AlberTajuelo/ansible-kerberos-server) which turn was inspired by the work of ["bennojoy/kerberos_server"](https://github.com/bennojoy/kerberos_server).

Requirements
------------

In order to use this Ansible role, you will need:

* Ansible version >= 2.2 in your deployer machine.
* Check meta/main.yml if you need to check dependencies.


Main workflow
-------------

This role does:
* Download specific Kerberos packages (this packages are os-dependent).
* Configuring Kerberos Server files:
 * kdc.conf
 * kadm5.acl
 * krb5.conf
* Create an admin user

Default Role Variables
--------------


| Attribute 		| Default Value 	| Description  									|
|---        		|---				|---											|
| realm_name  		| REALM.NAME.COM	| Realm Name for Kerberos Server				|
| kdc_port  		| 88			  	| Kerberos Key Distribution Center (KDC) port 	| 
| master_db_pass  	| m4st3r_p4ssw0rd  	| Administrator password					  	|
| kadmin_user  		| defaultuser 	 	| Kadmin username							  	|
| kadmin_pass  		| d3f4ultp4ss  		| Kadmin password							  	|


Example Playbook
----------------
*Note all variables are set to defaults here but can be modified as required*
```
- hosts: kdc
  become: yes
  vars:
    realm_name: REALM.NAME.COM
    kdc_port: 88
    master_db_pass: m4st3r_p4ssw0rd
    kadmin_principal: admin/admin
    kadmin_user: defaultuser
    kadmin_pass: defaultpass
  tasks:
    - import_role:
        name: roles/ansible-kerberos-server
```
