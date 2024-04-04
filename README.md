# Mysql cluster

## Packer

The tool for MySQL images creation, all the details in [packer][packer]

[packer]: /packer/README.md

## Ansible

At this point we are using Ansible 8. For local installation use
([installation guide][ansible_install]) and ansible GCP plugin ([intallation guide][ansible_gcp_glugin_install])

Preferable way of usage is cloudbuild. Firstly, ensure that we have the
[builder][ansible_builder]

[ansible_install]: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#ensuring-pip-is-available
[ansible_gcp_glugin_install]: https://docs.ansible.com/ansible/latest/scenario_guides/guide_gce.html#requisites
[ansible_builder]: /ansible/README.md
