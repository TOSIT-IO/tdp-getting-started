# Kerberos client install

**Ansible role to perform a minimal installation of an MIT kerberos client on the target, and to point it at an existing KDC using the following variable declarations:**

- realm_name
- kdc_server
- kadmind_server
- kdc_conf_path (defaults to `/etc/krb5.conf`)

