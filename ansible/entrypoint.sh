#!/bin/sh

echo $GCP_SERVICE_ACCOUNT_FILE_CONTENT > ansible-sa.json
export ANSIBLE_REMOTE_USER=sa_$(cat ansible-sa.json |  jq -r '.client_id')

if [[ -f .env ]]; then
  set -a; source .env; set +a
fi

mkdir -p .ssh
printf '%s\n' "$GCP_PK_FILE_CONTENT" > .ssh/ansible
printf '%s\n' "$GCP_PUB_KEY" > .ssh/ansible.pub

chmod 700 .ssh
chmod 600 .ssh/ansible .ssh/ansible.pub

cp -R .ssh ~/.ssh
cp -R .ssh /root/.ssh

if [[ -d inventory ]]; then
  envsubst < inventory/gcp.yaml.tpl > inventory/gcp.yaml
  ansible-inventory -i inventory/gcp.yaml --list --yaml > inventory/default.yaml
fi

exec "$@"
