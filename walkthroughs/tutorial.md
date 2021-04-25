<walkthrough-author
    tutorialname="Cloud Deploy Tutorial"
    repositoryUrl="https://clouddeploy.googlesource.com/tutorial"
    >
</walkthrough-author>

<!-- descriptive tutorial name? --sanderbogdan -->
# Cloud Deploy: Private Preview
## Overview
This tutorial guides you through setting up and using the Google Cloud Deploy service.

You will create a GCP Project, or use an existing one if you choose, to create a complete **test > staging > production** delivery pipeline using Cloud Deploy.

<!-- TODO: We need a graphic/logo/something here for impact. Possibly a graphic of the dev > staging > prod pipeline for emphasis? -->

<!-- TODO: Will it? If so, add link -->
### Supporting materials
Estimated Duration:
<walkthrough-tutorial-duration duration="20"></walkthrough-tutorial-duration>

Click **Next** to proceed.

## About Cloud Shell
This tutorial uses [Google Cloud Shell](https://cloud.google.com/shell) to configure and interact with Cloud Deploy. Cloud Shell is an online development and operations environment accessible anywhere with your browser. You can manage your resources with its online terminal preloaded with utilities such as the gcloud command-line tool, kubectl, and more. You can also develop, build, debug, and deploy your cloud-based apps using the online [Cloud Shell Editor](https://ide.cloud.google.com/).

### Select a Project
First, select a Project to deploy Cloud Deploy. This is the Project that where the Cloud Deploy service as well as the tutorial GKE clusters that will act as your development, staging, and production environments, will be located.

_It is recommended you create a new Project for this tutorial. The tutorial could fail to deploy, or you may experience undesired side effects if using an existing project with conflicting settings._

<walkthrough-project-setup></walkthrough-project-setup>

Click **Next** to proceed.

## Configure Cloud Shell
You'll do your work for this tutorial in Cloud Shell. To begin, open Cloud Shell in your browswer window by clicking the Cloud Shell icon <walkthrough-cloud-shell-icon></walkthrough-cloud-shell-icon>. 

If you don't see the Cloud Shell icon in your window, you can also click below to open Cloud Shell.

<walkthrough-open-cloud-shell-button></walkthrough-open-cloud-shell-button>

Next, you'll download the tutorial code base to your Cloud Shell.

### Clone the tutorial repository
<!-- I am wondering if we include this in bootstrap.sh, as we did with the Experiment tutorial? wdybt? --sanderbogdan -->
The source code for this tutorial is housed in a git repository. Your Cloud Shell already has `git` pre-installed.

Run the following command to clone the tutorial repository. This will clone the tutorial source code you'll use into a `tutorial` folder in your Cloud Shell home directory.

```bash
git clone https://clouddeploy.googlesource.com/tutorial
```

Click **Next** to proceed.

## Deploy tutorial infrastructure
<!-- I am wondering if we include this in bootstrap.sh, as we did with the Experiment tutorial? wdybt? --sanderbogdan -->
Now it's time to deploy the tutorial infrastructure. 

You'll deploy three GKE clusters with the following names into your `{{project-id}}` Project: 

GKE Cluster Name | Use
----- | -----
`test` |  Application test environment
`staging` | Staging environment (pre production)
`prod` | Production environment

_NOTE: If you have an existing GKE cluster in `{{project-id}}` with any of these names, you will need to select another project to use._

These three clusters are deployed into a VPC (Virtual Private Cloud) in `{{project-id}}`. 

<!-- TODO: A graphic would help this be understood better. Simple squares with VPCs etc -->

To create these GKE clusters, and supporting resources, run the `bootstrap.sh` in your Cloud Shell.

```bash
cd tutorial
./bootstrap.sh
```

*Note*: The bootstrap process may take a few minutes to run. 

Once completed, confirm your GKE clusters and supporting resources are properly deployed. 

```bash
gcloud container clusters list
```

Your output should look similar to below, with each cluster having three nodes and a `RUNNING` status.

```terminal
NAME     LOCATION     MASTER_VERSION    MASTER_IP       MACHINE_TYPE   NODE_VERSION      NUM_NODES  STATUS
prod     us-central1  1.17.17-gke.2800  35.194.37.64    n1-standard-2  1.17.17-gke.2800  3          RUNNING
staging  us-central1  1.17.17-gke.2800  35.232.139.69   n1-standard-2  1.17.17-gke.2800  3          RUNNING
test     us-central1  1.17.17-gke.2800  35.188.180.217  n1-standard-2  1.17.17-gke.2800  3          RUNNING
```

Click **Next** to proceed.

## Create tutorial environment
You're now ready to begin configuring Cloud Deploy.

This tutorial focuses on the core concepts and tooling of Cloud Deploy. The primary commands you'll be using are below.

<!-- TODO: update this list of commands -->
Resource  | Commands
------- | --------
Delivery Pipeline | `gcloud alpha deploy delivery-pipelines`
Targets | `gcloud alpha deploy targets`
Release candidate | `gcloud alpha deploy release-candidates`
Rollout | `gcloud alpha deploy rollouts`

<!-- TODO: Keep this updated depending on the app lifecycle -->
### Enable the Cloud Deploy API
<!-- I am wondering if we include this in bootstrap.sh, as we did with the Experiment tutorial? wdybt? --sanderbogdan -->
<!-- TODO: This may change or be wholly unneeded. I'm leaving it here for current testing if nothing else --jduncan -->
<!-- COMMENT: I like the fact that we how how to enable the API programmatically, but perhaps this part of the boostrap.sh? Conversely, the CLI to do this is a bit knotty - hopefully that will be able to simplified forward as well? --sanderbogdan -->
To enable the Cloud Deploy service and API, run the following.

```bash
gcloud config set api_endpoint_overrides/clouddeploy "https://staging-clouddeploy.sandbox.googleapis.com/"
gcloud services enable staging-clouddeploy.sandbox.googleapis.com --project={{project-id}}
```
Click **Next** to proceed.

### Configure Cloud Deploy
Default Cloud Deploy parameters can be configured with the `gcloud` SDK to avoid typing them for every command.

To set a default Cloud Deploy region for the rest of the commands in this tutorial, run the following command on your Cloud Shell: 

```bash
gcloud config set deploy/region $REGION
```

This will be used for any additonal Cloud Deploy commands unless you override it using the `--region` parameter.

<!-- COMMENT: I think this should be a pointer to the Cloud Deploy CLI documentation / or perhaps there is a gcloud CLI document regarding common defaults. TODO: follow up on link recommendation with ddorbin@ --sanderbogdan -->
The full list of Cloud Deploy configurations is available at [TODO].

You are now ready to deploy your first Cloud Deploy resource in your Project.

Click **Next** to proceed.

## Create the Delivery Pipeline
Cloud Deploy uses YAML files to define `delivery-pipeline` and `target` resources. For this tutorial, we have pre-created these files in the previously cloned repository.
<!-- COMMENT: May want to reference specific step # here. --sanderbogdan -->

<!-- COMMENT: We can consider adding linkings to the external facing Cloud Deploy resource documentation for Public Preview --sanderbogdan -->
In this tutorial, you will create a Cloud Deploy _Delivery Pipeline_ for a web application that progresses through three _Targets_: _test, staging, and prod_ GKE clusters.

The first resource you need to create is a `delivery-pipeline`. 

<walkthrough-editor-select-line filePath="tutorial/clouddeploy-config/delivery-pipeline.yaml" startLine="11" startCharacterOffset="0" endLine="19" endCharacterOffset="99">Click here to review the Delivery Pipeline YAML</walkthrough-editor-select-line>
 
Create the _Delivery Pipeline_ using the YAML file and `gcloud alpha deploy apply` command. 

```bash
gcloud alpha deploy apply --file=clouddeploy-config/delivery-pipeline.yaml 
```

Verify the _Delivery Pipeline_ has been created.

<!-- TODO: consider doing a get here instead of list, particularly since we do a list with targets? wdybt? --sanderbogdan -->
```bash
gcloud alpha deploy delivery-pipelines list
```

The output should appear similar to the below.

```terminal
---
createTime: '2021-04-12T18:34:02.614196898Z'
description: web-app delivery pipeline
etag: 2539eacd7f5c256d
name: projects/your-project/locations/us-central1/deliveryPipelines/web-app
serialPipeline:
  stages:
  - targetId: test
  - targetId: staging
  - targetId: prod
uid: b116d89067e64d7eb63f37fe5e99d1ff
updateTime: '2021-04-12T18:34:04.936664219Z'
```

With your _Delivery Pipeline_ confirmed, you're read to create three _Targets_.

Click **Next** to proceed.

## Create Targets
In Cloud Deploy, a _Target_ represents a GKE cluster where an application can be deployed to as part of a _Delivery Pipeline_.

In the tutorial _Delivery Pipeline_, the first _Target_ to be deployed to is the `test` GKE cluster. 

A _Target_ is created by applying a YAML file to Cloud Deploy using `glcoud alpha deploy apply`.

<walkthrough-editor-select-line filePath="tutorial/clouddeploy-config/test-environment.yaml" startLine="11" startCharacterOffset="0" endLine="19" endCharacterOffset="99">Click here to view the test Target YAML</walkthrough-editor-select-line>

Apply the _test_ _Target_ definition using `gcloud alpha deploy apply` in Cloud Shell. 

```bash
gcloud alpha deploy apply --file clouddeploy-config/test-environment.yaml
```

Verify the _Target_ has been created using the `gcloud alpha deploy` command to list _Delivery Pipeline_ _Targets_.

```bash
gcloud alpha deploy targets list --delivery-pipeline=web-app
```

The output should appear similar to the below.

```terminal
---
createTime: '2021-04-15T13:53:31.094996057Z'
description: test cluster
etag: 4c7d828d4f7a3b74
gkeCluster:
  cluster: test
  location: us-central1˜
  project: your-project
name: projects/your-project/locations/us-central1/deliveryPipelines/web-app/targets/test
uid: d1d2ca2dc4bf4884a8d16588cfe6d458
updateTime: '2021-04-15T13:53:31.663277590Z'
```

Click **Next** to proceed.

## Create Staging and Prod Targets
In the following section, you will create _Targets_ for the `staging` and `prod` GKE clusters.

The process to create your Staging and Prod _Targets_ is the same as the _test_ _Target_. 

Start by creating the _staging_ _Target_.

<walkthrough-editor-select-line filePath="tutorial/clouddeploy-config/staging-environment.yaml" startLine="11" startCharacterOffset="0" endLine="19" endCharacterOffset="99">Click here to view the staging Target YAML</walkthrough-editor-select-line>

Apply the _staging_ _Target_ definition using `gcloud alpha deploy apply` in Cloud Shell. 

```bash
gcloud alpha deploy apply --file clouddeploy-config/staging-environment.yaml
```

Repeat the process for the _prod_ _Target_.

<walkthrough-editor-select-line filePath="tutorial/clouddeploy-config/prod-environment.yaml" startLine="11" startCharacterOffset="0" endLine="19" endCharacterOffset="99">Click here to view your prod Target YAML</walkthrough-editor-select-line>

Apply the _prod_ _Target_ definition using `gcloud alpha deploy apply` in Cloud Shell. 

```bash
gcloud alpha deploy apply --file clouddeploy-config/prod-environment.yaml
```

Verify both _Targets_ for the `web-app` _Delivery Pipeline_.

```bash
gcloud alpha deploy targets list --delivery-pipeline=web-app
```

The output should appear similar to the below.

```terminal
---
createTime: '2021-04-15T16:43:59.404939886Z'
description: staging cluster
etag: 9c923d5f1dd88c97
gkeCluster:
  cluster: staging
  location: us-central1˜
  project: your-project
name: projects/your-project/locations/us-central1/deliveryPipelines/web-app/targets/staging
uid: b1a856d72e5d43de817c2ea8380da39b
updateTime: '2021-04-15T16:44:00.272725580Z'
---
createTime: '2021-04-15T13:53:31.094996057Z'
description: test cluster
etag: 4c7d828d4f7a3b74
gkeCluster:
  cluster: test
  location: us-central1˜
  project: your-project
name: projects/your-project/locations/us-central1/deliveryPipelines/web-app/targets/test
uid: d1d2ca2dc4bf4884a8d16588cfe6d458
updateTime: '2021-04-15T13:53:31.663277590Z'
---
createTime: '2021-04-15T16:44:31.295700Z'
description: prod cluster
etag: ff1840e2d8c3010a
gkeCluster:
  cluster: prod
  location: us-central1
  project: your-project
name: projects/your-project/locations/us-central1/deliveryPipelines/web-app/targets/prod
uid: 0c22c1fb08e546ee9ae569ce501bac95
updateTime: '2021-04-15T16:44:32.078235982Z'
```

All Cloud Deploy _Targets_ for the _Delivery Pipeline_ have now been created.

Click **Next** to proceed.

## Build the Application
<!-- TODO: We should check with viglesias@ regarding how he wants to position this copy --sanderbogdan -->
Cloud Deploy integrates with [`skaffold`](https://skaffold.dev/), a leading open source continuous development toolset.

When you ran `bootstrap.sh`, a sample application was cloned from a [Github repository](https://github.com/GoogleContainerTools/skaffold.git) to your Cloud Shell instance in the `web` directory. 

In this section, you'll build that application image so you can progress it through the `webapp` _Delivery Pipeline_.

### Configure Artifact Registry Authentication
Google Cloud's Artifact Registry was enabled as part of executing `bootstrap.sh`. To push a container image to the registry, we must enable the `docker` daemon on your Cloud Shell instance to log in to Artifact Registry using your active SDK authentication token. 

This requires a few commands to be run on your Cloud Shell instance.

These commands allow your user to run `docker` commands on Cloud Shell and also configure the local `docker` daemon to authenticate using `gcloud` for your Artifact Registry domain.

```bash
sudo usermod -a -G docker ${USER}
gcloud auth configure-docker ${REGION}-docker.pkg.dev
```

With these steps complete, authenticate to your Artifact Registry. This allows `skaffold` in the next section to push your created image into Artifact Registry.

```bash
docker login ${REGION}-docker.pkg.dev
```

### Build with Skaffold
Next, build the application image.

The example application source code is located in the `web` directory of your Cloud Shell instance. That directory contains `skaffold.yaml`. This file contains the instructions for `skaffold` to use to build a container image for your application.

<walkthrough-editor-select-line filePath="tutorial/web/skaffold.yaml" startLine="11" startCharacterOffset="0" endLine="19" endCharacterOffset="99">Click here to view webapp's skaffold.yaml</walkthrough-editor-select-line>

The application images are named `leeroy-web` and `leeroy-app` when deployed. To create these container images, run the following command.

```bash
cd web/
skaffold build --default-repo ${REGION}-docker.pkg.dev/{{project-id}}/web-app
```

<!-- TODO: consider removing this sentence given no comparison output to review, and likely inclusion would be long. check with ddorbin@ --sanderbogdan -->
If you are familiar with building container images, the output should look familiar.

To confirm the images have been successfully pushed to Artifact Registry, run the following command. The `--format json` parameter returns the output in a JSON format for readability.

```bash
gcloud artifacts docker images list ${REGION}-docker.pkg.dev/${PROJECT_ID}/web-app --include-tags --format json
```

The output should look similar to the below. 

```terminal
Listing items under project your-project, location us-central1, repository web-app.

[
  {
    "createTime": "2021-04-15T23:15:15.792959Z",
    "package": "us-central1-docker.pkg.dev/your-project/web-app/leeroy-app",    
    "tags": "63ec18a",
    "updateTime": "2021-04-15T23:15:15.792959Z",
    "version": "sha256:80d8a867b82eb402ebe5b48f972c65c2b4cf7657ab30b03dd7b0b21dfc4a6792"
  },
  {
    "createTime": "2021-04-15T23:15:27.320207Z",
    "package": "us-central1-docker.pkg.dev/your-project/web-app/leeroy-web",
    "tags": "63ec18a",
    "updateTime": "2021-04-15T23:15:27.320207Z",
    "version": "sha256:30c37ef69eaf759b8c151adea99b6e8cdde85a81b073b101fbc593eab98bc102"
  }
]
```

By default, `skaffold` sets the tag for an image to the same value as the short form of the `git` commit ID. This can be used to verify the image being added to a Cloud Deploy _Release_.

### Verify the Application Image
To ensure there were no issues when building or pushing the application image, run the following `git` command.

```bash
export GIT_SHA=$(git rev-parse --short HEAD)
```

<!-- TODO: consider removing second sentence as it is too confusing and may cause the reader unnecessary alarm if their value is not the same. --sanderbogdan -->
This value should match the `tags` value in the Artifact Registry output from above. For this example, both values are presented as `63ec18a` (this will likly not be your value, it is by example only).

```bash
gcloud artifacts docker images list ${REGION}-docker.pkg.dev/${PROJECT_ID}/web-app --include-tags --format=value"(tags)"
```

The output should look similar to the below. 

<!-- TODO: is this correct? can the container names be displayed, also --sanderbogdan -->
```terminal
Listing items under project your-project, location us-central1, repository web-app.

63ec18a
63ec18a
```

You can confirm the output matches the git commit ID.
```bash
echo $GIT_SHA
```

If the values match, your application container images are now built, verified, and ready for Cloud Deploy. 

Click **Next** to proceed.

## Create a Release
<!-- TODO: A release, technically, also includes the rendering source and skaffold.yaml; we should somehow weave a statement regarding this into this section, also (IMHO). --sanderbogdan -->
With Cloud Deploy, a _Release_ is a specific version of one or more application images that are associated with a specific _Delivery Pipeline_. Once created, a _Release_ can be promoted through multiple _Targets_ (refered to as a _promotion sequence_).

Because this will be the first _Release_ of the application, this _Release_ will be named `web-app-001`.

To create a _Release_, run the below `gcloud alpha deploy releases create` command.

This command pulls together the tutorial steps thus far, referencing the _Delivery Pipeline_ as well as the container images.

```bash
gcloud alpha deploy releases create web-app-001 --delivery-pipeline web-app --images leeroy-web=${REGION}-docker.pkg.dev/{{project-id}}/web-app/leeroy-web:${WEB_SHA},leeroy-app=${REGION}-docker.pkg.dev/{{project-id}}/web-app/leeroy-app:${APP_SHA}
```

To confirm your ...
<!-- TODO: finish step content -->

## Promotion
<!-- TODO: details; promote through to production -->

## Rollback
<!-- TODO: details; create a second release, rollback test target -->

## Approvals
<!-- TODO: details; add approval to prod target YAML, add IAM permission, approval and promote through-->

## Cloud Deploy Console
<!-- TODO: Couple short paragraphs, pivot out to review Delivery Pipeline and details in Cloud Console -->

# Advanced use
<!-- TODO: review with Jamie/Henry this week -->

## Use Skaffold profiles
<!-- TODO: Helm or Kustomize? Simple sample, similar to the prior Experiment tutorial to demonstrate how to use Skaffold + profiles -->

## Notifications
<!-- TODO: I feel a very simple example, with some post deployment notification message hook that prints a message is good enough. We can use this step's copy to express  -->