# PCF on GCP

![alt tag](https://raw.githubusercontent.com/krishicks/patrick/master/embed.png)

This pipeline uses Terraform to create all the infrastructure required to run a
3 AZ PCF deployment on GCP.

To use it, you'll need to change all of the CHANGEME values in params.yml.

You'll also need to enable:

* GCP Compute API [here](https://console.cloud.google.com/apis/api/compute_component)
* GCP Storage API [here](https://console.cloud.google.com/apis/api/storage_component)
* GCP SQL API [here](https://console.cloud.google.com/apis/api/sql_component)
* GCP DNS API [here](https://console.cloud.google.com/apis/api/dns)
* GCP Cloud Resource Manager API [here](https://console.cloud.google.com/apis/api/cloudresourcemanager.googleapis.com/overview)

This pipeline downloads artifacts from DockerHub, GitHub, and the configured
S3-compatible object store, and as such the Concourse instance must have access
to those. You can use AWS S3 as your S3-compatible object store, but note that
Terraform outputs a .tfstate file that contains plaintext secrets. For this
reason Minio is preferrable to keep the visibility of the .tfstate local to
Concourse.

If you don't already have Concourse running:

```
vagrant init concourse/lite
vagrant up
fly -t lite login -c http://192.168.100.4:8080
```

If you want to use Minio as your S3-compatible object store:

```
docker run -e MINIO_ACCESS_KEY="example-access-key" \
           -e MINIO_SECRET_KEY="example-secret-key" \
           --detach \
           --network host \
           minio/minio server /tmp
```

Set the pipeline:

```
fly -t lite set-pipeline -p deploy-pcf -c pipeline.yml -l params.yml
```

## Usage

Unpause the pipeline if you haven't already.

`upload-opsman-image` will automatically upload the latest matching version of Operations Manager.

Once that is complete you can trigger the `create-infrastructure` job. `create-infrastructure` will output at the end the DNS settings that you must configure before continuing.

Once DNS is set up you can run `configure-director`. From there the pipeline should automatically run through to the end.

### Tearing down the environment

There is a job, `wipe-env`, which you can run to destroy the infrastructure
that was created by `create-infrastructure`. If you want to bring the
environment up again, run create-infrastructure. This can also be used if
create-infrastructure fails for some reason, where Terraform creates only some
of the infrastructure.
