# Ansible

This build step invokes `ansible` commands in [Google Cloud Build][cloud-build].

Arguments passed to this builder will be passed to [`ansible`][ansible] directly, allowing callers to
run [any Ansible command][ansible-commands].

[cloud-build]: https://cloud.google.com/cloud-build

[ansible]: https://docs.ansible.com/ansible/latest/getting_started/index.html

[ansible-commands]: https://docs.ansible.com/ansible/latest/command_guide/index.html

## Building the Builder

Before using this builder in a Cloud Build config, it must be built and pushed to the registry in
your project. Run the following command in this directory:

```bash
gcloud builds submit .
```

## Why we run ansible on CloudBuild

For ansible authentication we have to provide the json file with the appropriate
service account. If we use ansible vault, it would mean that we'll have to
manage some way of password sharing from the vault, which is always dirty, since
one password must be used by one entity for one thing. Instead of this, all the
secrets are saved in GCP Secret Manager, and cloudBuild can fetch them in the
process of building, so no secret sharing is involved.
For development purposes it's possible to make a separate service account (and
limit the rights) for that case and store it locally, feeding ansible with a
proper path to this json in a environment variable.

## Structure

### Folders structure

To run any scenario it's implied that you are executed it from `latest`
subfolder, or from the folder with the corresponding revision number

```bash
cd latest
```

### Cluster structure

Each revision contains one master and at least one slave/replica (at the moment of this writing exactly one). The master and slave are in sync trough standard MySQL replication, and since this replication is done inside one cluster we name this "internal replication".

At some point we want to upgrade the cluster to another revision, meaning that we will need to make the replication between new and old masters. This is called "external replication", since it's done with the entities outside of the cluster.

External replication type should be master-master. This should allow us to do easy rollback in case something go wrong at any point of the migration without loosing data.

Master-master replication is async and it might trigger some issues because of replication delay, so at least at this point we'll treat all the upgrades as offline only, while it might be done online. (should be tested after migration and upgrade)

### Upgrading / updating

All the changes, which might require any cluster disturbance MUST be done in a
new cluster, which should be created for that purpose.

For doing so, please run `bin/new_revision` script, which will create a new
revision folder with all the preparations for the provision

## Playbook execution examples

```bash
gcloud builds submit .
gcloud builds submit --substitutions _PLAYBOOK=bootstrap,_GCP_ENVIRONMENT=production
```

## New revision rollout

There are a few steps which should be done manually for each rollout just to
keep flexibility in place. Will describe the process, assuming that we are
upgrading `revision_1` to `revision_12345`

```bash
# we need to be in the root of the ansible stuff folder
cd ansible

# On the both revisions master nodes should be connected to each other though
# master-master replication. This is achievable only if new revision is based on
# backup from `master` instance, rather than `replica`. In order to do so we
# have to grab a fresh backup from the previous revision of the master.
cd revision_1
gcloud builds submit --substitutions _PLAYBOOK=create_backup
cd ..

# create the new revision
bin/new_revision

# for this case it will be in the folder `revision_12345`
cd revision_12345

# Most likely you will need to patch files and pick the proper [image](https://console.cloud.google.com/compute/images?project=my-awesome-project&tab=images)
#   ansible/revision_12345/vars/bootstrap/staging.yaml
#   ansible/revision_12345/vars/bootstrap/production.yaml

# and select the right [backup](https://console.cloud.google.com/storage/browser/mysql-backup;tab=objects?forceOnBucketsSortingFiltering=true&project=my-awesome-project&prefix=&forceOnObjectsSortingFiltering=false&pageState=(%22StorageObjectListTable%22:(%22f%22:%22%255B%255D%22))) to restore from in files
#   ansible/revision_12345/vars/prepare/staging.yaml
#   ansible/revision_12345/vars/prepare/production.yaml

# Here we need to patch the new revision as we like and roll it out when it's ready
gcloud builds submit

# (Optional) if something went wrong we can kill `revision_12345` and deploy it again with
gcloud builds submit --substitutions _PLAYBOOK=kill

# (optional)
# if you restore the backup from the previous revision this step might be omitted.
# when we are cool with the setup, and after the backups are restored
#   (see slack #tech-notifications channel) we have to start replication with
#   `revision_1`
# It should be done in `mysql_expire_logs_days`
gcloud builds submit --substitutions _PLAYBOOK=start_external_replication_down

# To allow easy rollback in the upgrade process we create master-master
# replication. So we need to add backwards replication with
cd ../revision_1
gcloud builds submit --substitutions _PLAYBOOK=start_external_replication_up
```

If we are working with production environment all gcloud commands have to have
the substitution `,_GCP_ENVIRONMENT=production`.

## Available playbooks

* `create_backup` create the backup from master instance. This is required for
new revision roll out because of master-master replication.
* `initialize` bootstrap the new cluster from scratch + adding all the configs
* `start_external_replication_up` Add or repair Mysql replication on the existed
cluster from older revision to newer
* `start_external_replication_down` Add or repair Mysql replication on the
existed cluster from newer revision to older
* `kill` To uninstall the cluster

## Connect to existed VM in the cluster

Now we have external IP address for each VM in the cluster so you can connect
trough SSH to any VM (if you have the access of course). But after the migration
the connection to the VMs should be done though bastion host using internal IP.
For now we are using `bastion` VM for this purpose.

TODO: Remove external IP addresses from VMs after migration is done.

## Development

### Overview

Get full graph of the infra is possible with. Note that `inventory/gcp.yaml`
file should be generated basing on the desired env variables and
`inventory/gcp.yaml.tpl`

```bash
ansible-inventory -i inventory/gcp.yaml --list -y
```
