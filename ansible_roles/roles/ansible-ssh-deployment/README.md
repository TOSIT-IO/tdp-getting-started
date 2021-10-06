# ansible-ssh-deployment

Creates a a set of ssh keys locally and then deploys the public key to all hosts.

# Example playbook

```yaml
- hosts: localhost
  tasks:
    - name: Generate new ssh key
      import_role:
        name: ansible_roles/roles/ansible-ssh-deployment
        tasks_from: generate-user-ssh-keys

- hosts: all
  tasks:
    - name: Deploy public key to hosts and add to authorized_hosts file
      import_role:
        name: ansible_roles/roles/ansible-ssh-deployment
        tasks_from: deploy-user-ssh-keys
```