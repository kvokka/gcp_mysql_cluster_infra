# Packer GCE build

This directory contains an example that creates a GCE image using `packer`.

Example Packer build is using [HCL2 syntax](https://www.packer.io/guides/hcl) and creates
GCE image basing on Ubuntu Linux.

## Executing the Packer Builder

1. Adjust packer variables

   Edit provided `variables.pkrvars.hcl` example file and set following variables accordingly:
   * `project_id` - identifier of your project
   * `zone` - GCP Compute Engine zone for packer instance
   * `builder_sa` - Packer's service account email in a format of `name@{PROJECT_ID}.iam.gserviceaccount.com`

2. Run the build

   ```sh
   gcloud builds submit .
   ```
