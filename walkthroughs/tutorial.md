<walkthrough-author
    tutorialname="Cloud Deploy Tutorial"
    repositoryUrl="https://clouddeploy.googlesource.com/tutorial"
    >
</walkthrough-author>

<!-- descriptive tutorial name? --sanderbogdan -->
# Cloud Deploy: Private Preview tutorial
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
Default Cloud Deploy parameters can be configured with the  `gcloud` SDK to avoid typing them for every command.

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
In this section you'll create the environment for your infrastructure. For this tutorial, you're creating a Cloud Deploy environment that consists of one _Delivery Pipeline_ for a web application that progresses through three _Targets_. These targets are your _test, staging, and prod_ GKE clusters.

Cloud Deploy uses YAML files to define resources. For the tutorial, these files are all in the repository you previously cloned to your Cloud Shell. The first resource you need to create is the Delivery Pipeline. 

<walkthrough-editor-select-line filePath="tutorial/clouddeploy-config/delivery-pipeline.yaml" startLine="11" startCharacterOffset="0" endLine="19" endCharacterOffset="99">Click here to review the Delivery Pipeline yaml file.</walkthrough-editor-select-line>
 
To create your Delivery Pipeline, run the following command in your Cloud Shell. 

```bash
gcloud alpha deploy apply --file=clouddeploy-config/delivery-pipeline.yaml 
```

To verify your Delivery Pipeline has been created, run the following command:

```bash
gcloud alpha deploy delivery-pipelines list
```

The output should look similar to the output below: 

```terminal
---
createTime: '2021-04-12T18:34:02.614196898Z'
description: web-app delivery pipeline
etag: 2539eacd7f5c256d
name: projects/jduncan-cd-testing/locations/us-central1/deliveryPipelines/web-app
serialPipeline:
  stages:
  - targetId: test
  - targetId: staging
  - targetId: prod
uid: b116d89067e64d7eb63f37fe5e99d1ff
updateTime: '2021-04-12T18:34:04.936664219Z'
```

With your Delivery Pipeline confirmed, you're read to create your three Targets. 

Click the Next button to proceed.

## Creating your Testing Target

In Cloud Deploy, a Target is a GKE cluster where an application can be deployed as part of a Delivery Pipeline. In your Delivery Pipeline, the first Target to be deployed to is yout `test` GKE cluster. This is done by applying a YAML file to Cloud Deploy using the `glcoud alpha deploy` command in the SDK.

<walkthrough-editor-select-line filePath="tutorial/clouddeploy-config/test-environment.yaml" startLine="11" startCharacterOffset="0" endLine="19" endCharacterOffset="99">Click here to view your test Target yaml file.</walkthrough-editor-select-line>

To create your test Target, run the following command in your Cloud Shell.

```bash
gcloud alpha deploy apply --file clouddeploy-config/test-environment.yaml
```

Once this completes (a second or two), verify your new Target has been created using the following `gcloud` command to list the existing targets for your `web-app` Delivery Pipeline:

```bash
gcloud alpha deploy targets list --delivery-pipeline=web-app
```

The output should look similar to the example below:

```terminal
---
createTime: '2021-04-15T13:53:31.094996057Z'
description: test cluster
etag: 4c7d828d4f7a3b74
gkeCluster:
  cluster: test
  location: us-central1˜
  project: jduncan-cd-testing
name: projects/jduncan-cd-testing/locations/us-central1/deliveryPipelines/web-app/targets/test
uid: d1d2ca2dc4bf4884a8d16588cfe6d458
updateTime: '2021-04-15T13:53:31.663277590Z'
```

In the following section, you'll create similar Targets for your `staging` and `prod` GKE clusters.

Click the Next button to proceed.

## Creating Staging and Prod Targets

The process to create your Staging and Prod Targets is the same as the Test target you just created. You'll start with your staging Target. 

<walkthrough-editor-select-line filePath="tutorial/clouddeploy-config/staging-environment.yaml" startLine="11" startCharacterOffset="0" endLine="19" endCharacterOffset="99">Click here to view your staging Target yaml file.</walkthrough-editor-select-line>

To create the staging Target run the following command in Cloud Shell:

```bash
gcloud alpha deploy apply --file clouddeploy-config/staging-environment.yaml
```

With that created, create your prod Target next. 

<walkthrough-editor-select-line filePath="tutorial/clouddeploy-config/prod-environment.yaml" startLine="11" startCharacterOffset="0" endLine="19" endCharacterOffset="99">Click here to view your prod Target yaml file.</walkthrough-editor-select-line>

To create your Prod Target run the following command in Cloud Shell:

```bash
gcloud alpha deploy apply --file clouddeploy-config/prod-environment.yaml
```

With both Targets created, verify everything is correct by looking at all of the Targets for the `web-app` Delivery Pipeline:

```bash
gcloud alpha deploy targets list --delivery-pipeline=web-app
```

Your output should look similar to the example below: 

```terminal
---
createTime: '2021-04-15T16:43:59.404939886Z'
description: staging cluster
etag: 9c923d5f1dd88c97
gkeCluster:
  cluster: staging
  location: us-central1˜
  project: jduncan-cd-testing
name: projects/jduncan-cd-testing/locations/us-central1/deliveryPipelines/web-app/targets/staging
uid: b1a856d72e5d43de817c2ea8380da39b
updateTime: '2021-04-15T16:44:00.272725580Z'
---
createTime: '2021-04-15T13:53:31.094996057Z'
description: test cluster
etag: 4c7d828d4f7a3b74
gkeCluster:
  cluster: test
  location: us-central1˜
  project: jduncan-cd-testing
name: projects/jduncan-cd-testing/locations/us-central1/deliveryPipelines/web-app/targets/test
uid: d1d2ca2dc4bf4884a8d16588cfe6d458
updateTime: '2021-04-15T13:53:31.663277590Z'
---
createTime: '2021-04-15T16:44:31.295700Z'
description: prod cluster
etag: ff1840e2d8c3010a
gkeCluster:
  cluster: prod
  location: us-central1
  project: jduncan-cd-testing
name: projects/jduncan-cd-testing/locations/us-central1/deliveryPipelines/web-app/targets/prod
uid: 0c22c1fb08e546ee9ae569ce501bac95
updateTime: '2021-04-15T16:44:32.078235982Z'
```

You've now created the all of the Cloud Deploy Targets as well as your Delivery Pipeline. Now it's time to build your application in order to create a Release Candidate. 

Click the Next button to proceed. 

## Building your Application

Cloud Deploy integrates tightly with [`skaffold`](https://skaffold.dev/), a leading open source Continuous Delivery tool. When you ran `bootstrap.sh`, a sample application was cloned from a [Github repository](https://github.com/GoogleContainerTools/skaffold.git) to your Cloud Shell instance in the `web` directory. 

In this section, you'll build that application image so you can progress it through your Delivery Pipeline.

### Configuring Artifact Registry Authentication

The Google Artifact Registry was enabled as part of running `bootstrap.sh`. To push a container image to the registry, you need to enable the `docker` daemon on your Cloud Shell instance to log in to Artifact Registry using your active SDK authentication token. This requires a few commands to be run on your Cloud Shell instance. These commands allow your user to run `docker` commands on Cloud Shell and also configures the local `docker` daemon to authentication using `gcloud` for your Artifact Registry domain.

```bash
sudo usermod -a -G docker ${USER}
gcloud auth configure-docker ${REGION}-docker.pkg.dev
```

With these steps complete, authenticate to your Artifact Registry. This allows `skaffold` in the next section to push your created image into Artifact Registry.

```bash
docker login ${REGION}-docker.pkg.dev
```
You're now set to build your application image.

### Building with Skaffold

The example application source code is on your Cloud Shell instance in the `web` directory. That directory contains `skaffold.yaml`. This file contains the instructions for `skaffold` to use to build a container image for your application.

<walkthrough-editor-select-line filePath="tutorial/web/skaffold.yaml" startLine="11" startCharacterOffset="0" endLine="19" endCharacterOffset="99">Click here to view skaffold.yaml file.</walkthrough-editor-select-line>

Your application images will be called `leeroy-web` and `leeroy-app` when it's deployed. To create these container images for, run the following command in Cloud Shell.

```bash
cd web/
skaffold build --default-repo ${REGION}-docker.pkg.dev/{{project-id}}/web-app
```

If you're familiar with building container images this output should look familiar to you. To confirm your images have been successfully pushed to your Artifact Registry, run the following command. The `--format json` parameter makes the content output in JSON format to be easier to read:

```bash
gcloud artifacts docker images list ${REGION}-docker.pkg.dev/${PROJECT_ID}/web-app --include-tags --format json
```

Your output should look similar to the example below: 

```terminal
Listing items under project jduncan-cd-testing, location us-central1, repository web-app.

[
  {
    "createTime": "2021-04-15T23:15:15.792959Z",
    "package": "us-central1-docker.pkg.dev/jduncan-cd-testing/web-app/leeroy-app",    
    "tags": "63ec18a",
    "updateTime": "2021-04-15T23:15:15.792959Z",
    "version": "sha256:80d8a867b82eb402ebe5b48f972c65c2b4cf7657ab30b03dd7b0b21dfc4a6792"
  },
  {
    "createTime": "2021-04-15T23:15:27.320207Z",
    "package": "us-central1-docker.pkg.dev/jduncan-cd-testing/web-app/leeroy-web",
    "tags": "63ec18a",
    "updateTime": "2021-04-15T23:15:27.320207Z",
    "version": "sha256:30c37ef69eaf759b8c151adea99b6e8cdde85a81b073b101fbc593eab98bc102"
  }
]
```

By default, `skaffold` sets the tag for an image to the same value as the short form of the `git` commit ID. You can use this to verify the image you're adding to a Cloud Deploy Release.

### Verifying your Application Image

To ensure there were no issues when building or pushing your application image, run the following `git` command.

```bash
export GIT_SHA=$(git rev-parse --short HEAD)
```

This value should match the `tags` value in the Artifact Registry output above. For this example, both values should be `63ec18a`.

```bash
gcloud artifacts docker images list ${REGION}-docker.pkg.dev/${PROJECT_ID}/web-app --include-tags --format=value"(tags)"
```

The output should look similar to this: 

```terminal
Listing items under project jduncan-cd-testing, location us-central1, repository web-app.

63ec18a
63ec18a
```

You can confirm this matches the git commit ID.
```bash
echo $GIT_SHA
```

If the values match, your application container images are now built, verified, and ready for Cloud Deploy. In the next section you'll create a release for your application.

Click the Next button to proceed.

## Creating an Application Release

In Cloud Deploy, a Release is a specific version of one or more application images that are associated with a specific Delivery Pipeline. Once created, a Release can be promoted through multiple Targets.

Because this will be the first release of your application stack, call this release `web-app-001`.

To create a Release, run the following command in your Cloud Shell instance. This command pulls together almost everything you've done so far. It references the Delivery Pipeline as well as the container images:

```bash
gcloud alpha deploy releases create web-app-001 --delivery-pipeline web-app --images leeroy-web=${REGION}-docker.pkg.dev/{{project-id}}/web-app/leeroy-web:${WEB_SHA},leeroy-app=${REGION}-docker.pkg.dev/{{project-id}}/web-app/leeroy-app:${APP_SHA}
```

To confirm your ...
