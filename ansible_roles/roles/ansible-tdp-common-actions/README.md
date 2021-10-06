# ansible-tdp-common-actions

This role comproses a set of tasks commonly applied accross a TDP-getting-started cluster.

# Example playbook example

```yaml
- hosts: all
  tasks:
    - name: sync hosts file
      import_role:
        name: ansible_roles/roles/ansible-tdp-common-actions
        tasks_from: update_hosts_file
```
