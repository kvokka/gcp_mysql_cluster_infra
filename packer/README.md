# Packer

This build step invokes `packer` commands in [Google Cloud Build][cloud-build].

Arguments passed to this builder will be passed to [`packer`][packer] directly, allowing callers to
run [any Packer command][packer-commands].

[cloud-build]: https://cloud.google.com/cloud-build

[packer]: https://www.packer.io

[packer-commands]: https://www.packer.io/docs/commands

## Building the Builder

Before using this builder in a Cloud Build config, it must be built and pushed to the registry in
your project. Run the following command in this directory:

```bash
gcloud builds submit .
```

## New revision rollout

For creation of the mysql image we have to use packer tool.
Please check that you are using desired version of packer,
[details][packer_builder]

To build Mysql image you will use the [builder][mysql_image_builder]. For invocation
run:

```bash
IMAGE=mysql_8_0_image gcloud builds submit --config=$IMAGE/cloudbuild.yaml $IMAGE
```

[packer_builder]: README.md
[mysql_image_builder]: /mysql_8_0_image/README.md

## Old images clean up

There is no way to determine wether the image is in use or not at the building time,
meaning that all the cleanup should be sone manually afterwards on the [page][images]

[images]: https://console.cloud.google.com/compute/images?tab=images&project=my-awesome-project
