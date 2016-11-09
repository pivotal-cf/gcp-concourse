# Customer0 PCF+GCP Concourse Pipeline


### Pre_Reps for POC Deployment

1. Create a Service Account with "Editor" Role on the target GCP Project
2. Create a Concourse instance with public access for downloads.  Look [here](http://concourse.ci/vagrant.html) for `vagrant` instructions if an ephemeral concourse instance is desired
3. `git clone` this repo
4. **EDIT!!!** `ci/pipeline-parameters/c0-gcp-concourse-base.yml` and replace all variables/parameters you will want for your concourse individual pipeline run
5. **AFTER!!!** Completing Step 4 above ... log into concourse & create the pipeline
  - `fly -t [YOUR CONCOURSE TARGET] set-pipeline -p c0-gcp-concourse-base -c ci/c0-gcp-concourse-base.yml -l ci/pipeline-parameters/c0-gcp-concourse-base.yml` 
6. Unpause the pipeline
7. Run  **`init-env`** Job manually,  you will need to review the output and record for the DNS records that must now be made resolvable **BEFORE!!!** continuing to the next step:
  - Example:

```
==============================================================================================
This gcp_pcf_terraform_template has an 'Init' set of terraform that has pre-created IPs...
==============================================================================================
Activated service account credentials for: [c0-concourse@pcf-demos.google.com.iam.gserviceaccount.com]
Updated property [core/project].
Updated property [compute/region].
You have now deployed Public IPs to GCP that must be resolvable to:
----------------------------------------------------------------------------------------------
*.sys.gcp-poc.customer0.net == 130.211.9.202
*.cfapps.gcp-poc.customer0.net == 130.211.9.202
ssh.sys.gcp-poc.customer0.net == 146.148.58.174
doppler.sys.gcp-poc.customer0.net == 146.148.58.174
loggregator.sys.gcp-poc.customer0.net == 146.148.58.174
tcp.gcp-poc.customer0.net == 104.198.241.71
opsman.gcp-poc.customer0.net == 104.154.98.48
----------------------------------------------------------------------------------------------
```
8. **AFTER!!!** Completing Step 7 above ... Run the **`deploy-iaas`** Job manually, if valid values were passed, a successful ERT deployment on GCP will be the result.