ELK
=========

Installs a single-node ELK cluster on a machine - on either Ubuntu/debian or RedHat based systems.

Requirements
------------

Role Variables
--------------

### Defaults

```
es_ca_cert_path: /etc/elasticsearch/certs/http_ca.crt   # Path to the ES CA
es_su_user: mordin                                      # Default username of the new superuser that will be created
es_su_password: toortoor                                # Default password of the new superuser that will be created
es_secure: false                                           # Whether authentication and ssl will be enabled
es_create_beat_writer: false                               # Create a user that beats can use to push data to ES
es_beat_user: beat-writer                                  # Default beat username
es_beat_password: toortoor                                 # Default beat password
```

Dependencies
------------

Example Playbook
----------------

    - hosts: elk
      roles:
         - { role: elk, secure: true, create_beat_writer: true }

License
-------

BSD

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).
