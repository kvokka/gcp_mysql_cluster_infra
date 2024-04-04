ARG BASE_IMAGE=python:3.11-alpine3.18
FROM ${BASE_IMAGE}

ARG ANSIBLE_VERSION

COPY entrypoint.sh /entrypoint.sh

RUN apk update && \
  apk add --update openssh-client jq envsubst mariadb-connector-c-dev pkgconfig && \
  apk add --virtual build-deps gcc musl-dev && \
  apk add --no-cache mariadb && \
  pip install ansible==$ANSIBLE_VERSION google-auth requests PyMySQL netaddr && \
  ansible-galaxy role install --roles-path=/etc/ansible/roles googlecloudplatform.google_cloud_ops_agents && \
  ansible-galaxy collection install google.cloud ansible.posix community.general community.mysql && \
  rm -rf /var/cache/apk/* && \
  pip cache purge && \
  apk del build-deps

ENTRYPOINT ["/entrypoint.sh"]
