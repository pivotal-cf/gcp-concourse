# PCF on GCP

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

Set the pipeline:

```
# If you don't already have Concourse running.
vagrant init concourse/lite
vagrant up
fly -t lite login -c http://192.168.100.4:8080

# If you're using Minio
docker run -e MINIO_ACCESS_KEY="example-access-key" \
           -e MINIO_SECRET_KEY="example-secret-key" \
           --network host \
           minio/minio server /tmp

fly -t lite set-pipeline -p deploy-pcf -c pipeline.yml -l params.yml
```

Unpause the pipeline and it will create the infrastructure. At the end of
`create-infrastructure` it will print out the external IPs that were created in
GCP. These will need to be configured with the associated DNS settings in the
create-infrastructure output.

Once DNS is set up you can trigger the `configure-director` job.
