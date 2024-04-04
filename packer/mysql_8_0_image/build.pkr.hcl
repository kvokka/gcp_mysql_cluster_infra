variable "project_id" {
  type = string
}

variable "zone" {
  type = string
}

variable "builder_sa" {
  type = string
}

variable "mysql_version" {
  type = string
}

variable "prometheus_exporter_ver" {
  type = string
}

# https://developer.hashicorp.com/packer/docs/templates/hcl_templates/blocks/build/source
source "googlecompute" "mysql-image" {
  # https://github.com/hashicorp/packer-plugin-googlecompute/blob/main/docs-partials/builder/googlecompute/Config-not-required.mdx
  project_id                  = var.project_id
  # Naming was changed, get the actual image families list with `$ gcloud compute images list`
  source_image_family         = "ubuntu-2204-lts"
  image_family                = "ubuntu-2204-mysql"
  zone                        = var.zone
  image_name                  = "mysql-percona-${var.mysql_version}---{{isotime `2006-01-02--15-04-05`}}"
  image_description           = "Mysql image created with Packer from Cloudbuild"
  ssh_username                = "root"
  tags                        = ["packer", "mysql"]
  impersonate_service_account = var.builder_sa
}

build {
  name = "mysql"

  sources = ["sources.googlecompute.mysql-image"]

  provisioner "file" {
    source = "files/system/sysctl.conf"
    destination = "//etc/sysctl.conf"
  }


  provisioner "shell" {
    inline = [
    "curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh",
    "bash add-google-cloud-ops-agent-repo.sh --also-install",
    ]
  }

  provisioner "shell" {
    inline = [
      "echo export ZONE=${var.zone} > /etc/profile.d/set_zone_env_var.sh",
      "echo \"* soft nofile 30000\n\" >> /etc/security/limits.conf",
      "echo \"* hard nofile 60000\n\" >> /etc/security/limits.conf",
    ]
  }

  provisioner "shell" {

# TODO: replace percona-xtrabackup-24 with percona-xtrabackup-80 after backup restore
#   This 2 versions are replacing each other and we have to use the percona-xtrabackup-24 until
#   we finish the upgrade. Usage of 2 versions simualteniosely will just complicate the setup
#   without a real benifit, so this is less evil.
    inline = [
      "apt update",
      "curl -O https://repo.percona.com/apt/percona-release_latest.generic_all.deb",
      "apt install -y gnupg2 lsb-release ./percona-release_latest.generic_all.deb",
      "rm percona-release_latest.generic_all.deb",
      "apt update",
      "percona-release setup ps80",
      "DEBIAN_FRONTEND='noninteractive' apt install -y percona-server-server percona-xtrabackup-24 percona-toolkit qpress",
      "apt install -y libjemalloc-dev python3-mysqldb",
      "systemctl status mysql.service",
    ]

    # Faced several times that ubuntu repository returned an error, but worked correctly after manual
    # restart. Let it be automatic instead
    max_retries = 3

    # More than generous value, just to avoid any possible freeze
    timeout = "15m"
  }

  provisioner "file" {
    source = "files/system/node-exporter.service"
    destination = "//etc/systemd/system/node-exporter.service"
  }

  provisioner "shell" {
    inline = [
      "wget https://github.com/prometheus/node_exporter/releases/download/v${var.prometheus_exporter_ver}/node_exporter-${var.prometheus_exporter_ver}.linux-amd64.tar.gz",
      "tar xvfz node_exporter-*.*-amd64.tar.gz --strip-components=1 -C /usr/local/sbin/",
      "rm node_exporter-${var.prometheus_exporter_ver}.linux-amd64.tar.gz",
      "useradd -s /sbin/false nodeexporter",
      "chown nodeexporter:nodeexporter /usr/local/sbin/node_exporter",
      "systemctl enable node-exporter.service"
    ]
  }

  provisioner "file" {
    source = "files/system/mysql-exporter.service"
    destination = "//etc/systemd/system/mysql-exporter.service"
  }

  provisioner "shell" {
    inline = [
      "curl -s https://api.github.com/repos/prometheus/mysqld_exporter/releases/latest | grep browser_download_url | grep linux-amd64 | cut -d '\"' -f 4 | wget -qi -",
      "tar xvf mysqld_exporter*.tar.gz",
      "mv mysqld_exporter-*.linux-amd64/mysqld_exporter /usr/local/sbin/",
      "rm -fr mysqld_exporter-*",
      "chmod +x /usr/local/sbin/mysqld_exporter",
      "groupadd --system mysqlexporter",
      "useradd -s /sbin/nologin --system -g mysqlexporter mysqlexporter",
      "chown mysqlexporter:mysqlexporter /usr/local/sbin/mysqld_exporter",
      "systemctl enable mysql-exporter.service"
    ]
  }

  provisioner "shell" {
    inline = [
      "mkdir -p //etc/mysql/my.conf.d/"
    ]
  }

  # we are feeding mysql config at the very end, this allows to use small VM for image building
  provisioner "file" {
    source = "files/mysql/my.cnf"
    destination = "//etc/mysql/my.cnf"
  }

  # we are feeding mysql config at the very end, this allows to use small VM for image building
  provisioner "file" {
    source = "files/mysql/100_common.cnf"
    destination = "//etc/mysql/my.conf.d/100_common.cnf"
  }

}
