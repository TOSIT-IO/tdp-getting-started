# ansible-create-ca

Create a certification authority and create/distribute certificates

`certs_fqdns` variable is a list of domains for which certificates will be created and to which the certificates will be deployed (copied) to.
`inventory_hostname` variable is the host name in the ansible hosts file

## Example playbook

```yaml
---
- hosts: ca
  become: yes
  vars:
    - ca_name: tdp-getting-started
    - certs_fqdns:
        - edge-01
        - edge-02
        - master-01
        - master-02
        - master-03
        - worker-01
        - worker-02
        - worker-03
  tasks:
    - import_role:
        name: roles/ansible-ca
```
