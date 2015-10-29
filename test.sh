#!/usr/bin/env bash

CURRENT_DIR=${PWD}
TMP_DIR=/tmp/ansible-test
mkdir -p $TMP_DIR 2> /dev/null

# Create hosts inventory
cat << EOF > $TMP_DIR/hosts
[webservers]
localhost ansible_connection=local
EOF

# Create group_vars for the webservers
mkdir -p $TMP_DIR/group_vars 2> /dev/null
cat << EOF > $TMP_DIR/group_vars/webservers
es_remove_purge_1_6: false
EOF

# Create Ansible config
cat << EOF > $TMP_DIR/ansible.cfg
[defaults]
roles_path = $CURRENT_DIR/../
host_key_checking = False
EOF

# Create playbook.yml
cat << EOF > $TMP_DIR/playbook.yml
---

- hosts: webservers
  gather_facts: yes
  sudo: no

  roles:
    - ansible-elasticsearch
EOF

export ANSIBLE_CONFIG=$TMP_DIR/ansible.cfg

# Syntax check
ansible-playbook $TMP_DIR/playbook.yml -i $TMP_DIR/hosts --syntax-check

# First run
ansible-playbook $TMP_DIR/playbook.yml -i $TMP_DIR/hosts

# Idempotence test
 ansible-playbook $TMP_DIR/playbook.yml -i $TMP_DIR/hosts | grep -q 'changed=0.*failed=0' \
 	&& (echo 'Idempotence test: pass' && exit 0) \
 	|| (echo 'Idempotence test: fail' && exit 1)

apt-get install net-tools

sleep 10

netstat -tulpn | grep 9200 \
    && (echo 'Elasticsearch test: pass' && exit 0) \
 	|| (echo 'Elasticsearch test: fail' && exit 1)

#{
#  status: 200,
#  name: "Utgard-Loki",
#  cluster_name: "elasticsearch",
#  version: {
#    number: "1.6.0",
#    build_hash: "cdd3ac4dde4f69524ec0a14de3828cb95bbb86d0",
#    build_timestamp: "2015-06-09T13:36:34Z",
#    build_snapshot: false,
#    lucene_version: "4.10.4"
#  },
#  tagline: "You Know, for Search"
#}
