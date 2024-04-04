---
plugin: google.cloud.gcp_compute
projects:
  - "my-awesome-project"
auth_kind: "serviceaccount"
service_account_file: ansible-sa.json
keyed_groups:
- key: labels
  parent_group: cluster
filters:
  - "labels.component = mysql"
  - "labels.environment = $GCP_ENVIRONMENT"
  - "labels.revision = $MYSQL_CLUSTER_REVISION"
