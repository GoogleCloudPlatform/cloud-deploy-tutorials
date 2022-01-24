<walkthrough-metadata>
  <meta name="title" content="Cloud Deploy Execution Environments Tutorial" />
  <meta name="description" content="How to use Google Cloud Deploy execution environments" />
  <meta name="component_id" content="1036688" />
  <meta name="keywords" content="Deploy, pipeline, Kubernetes, execution, environments" />
  <meta name="unlisted" content="true" />
</walkthrough-metadata>

# Google Cloud Deploy: Preview

![](https://walkthroughs.googleusercontent.com/content/cloud_deploy_e2e_gke/images/cloud-deploy-logo-centered.png)

## Overview

This interactive tutorial shows you how to create and use custom execution environments using [Google Cloud Deploy](https://cloud.google.com/deploy).

You will use a **test > staging > production** delivery pipeline to deploy an application that uses custom execution environments for each target.

Before starting this tutorial, complete the [Google Cloud Deploy Basic walkthrough](https://cloud.google.com/deploy/docs/tutorials). Complete this tutorial in the same Google Cloud project as the walkthrough.

## About execution environments

Google Cloud Deploy uses the following defaults when rendering and deploying a workload to a target:

* The default [Cloud Build worker pool](https://cloud.google.com/build/docs/private-pools/private-pools-overview) is used for Cloud Deploy builds. The default worker pool is a secure hosted environment where each build runs in an isolated worker.
* The default [GCE Service Account](https://cloud.google.com/deploy/docs/cloud-deploy-service-account#default_service_account) is used to access Cloud Build and your Cloud Deploy targets.
* Google Cloud Deploy creates a Cloud Storage bucket in the same region as the Cloud Deploy resources. This bucket holds all artifacts by default. It has the naming syntax of `<LOCATION>.deploy-artifacts.<PROJECT_ID>.appspot.com`.

In this tutorial you'll create these custom resources and configure Google Cloud Deploy to use them in a custom [execution environment](https://cloud.google.com/deploy/docs/execution-environment).

### About Cloud Shell

This tutorial uses [Google Cloud Shell](https://cloud.google.com/shell) to configure and interact with Google Cloud Deploy. Cloud Shell is an online development and operations environment, accessible anywhere with your browser.

You can manage your resources with its online terminal, preloaded with utilities such as `gcloud`, `kubectl`, and more. You can also develop, build, debug, and deploy your cloud-based apps using the online [Cloud Shell Editor](https://ide.cloud.google.com/).

Estimated Duration:
<walkthrough-tutorial-duration duration="30"></walkthrough-tutorial-duration>

To get started, click **Next**.

## Project setup

Google Cloud organizes resources into projects. This allows you to collect all of the related resources for a single application in one place.

Begin by selecting an existing project for this tutorial.

***This project must be the project you used for the [Google Cloud Deploy Basic walkthrough](https://cloud.google.com/deploy/docs/tutorials), because infrastructure and Google Cloud Deploy targets are reused.***

<walkthrough-project-setup billing="true"></walkthrough-project-setup>

### Select your project

Once selected, set the project in Cloud Shell:

```bash
gcloud config set project {{project-id}}
```

### Configure your workspace

Next, change into the directory for this tutorial and set your workspace:

```bash
cd ~/cloud-deploy-tutorials/tutorials/exec-envs && cloudshell workspace .
```

If your Cloud Shell session times out, you can resume the tutorial by reconnecting to Cloud Shell and rerunning the previous command to change into the above directory.

### Set up this tutorial

Next, run `setup.sh` in your Cloud Shell to configure this tutorial:

```bash
./setup.sh
```

Click **Next** to proceed.

To confirm that your GKE clusters and supporting resources are properly deployed, click **Next**.

## Check infrastructure

Confirm that your GKE clusters and supporting resources are properly deployed:

```bash
gcloud container clusters list
```

The output is similar to the following:

```terminal
NAME: prod
LOCATION: us-central1
MASTER_VERSION: 1.20.11-gke.1300
MASTER_IP: 34.134.12.248
MACHINE_TYPE: n1-standard-2
NODE_VERSION: 1.20.11-gke.1300
NUM_NODES: 3
STATUS: RUNNING

NAME: staging
LOCATION: us-central1
MASTER_VERSION: 1.20.11-gke.1300
MASTER_IP: 35.193.89.33
MACHINE_TYPE: n1-standard-2
NODE_VERSION: 1.20.11-gke.1300
NUM_NODES: 3
STATUS: RUNNING

NAME: test
LOCATION: us-central1
MASTER_VERSION: 1.20.11-gke.1300
MASTER_IP: 104.197.215.105
MACHINE_TYPE: n1-standard-2
NODE_VERSION: 1.20.11-gke.1300
NUM_NODES: 3
STATUS: RUNNING
```

If the command succeeds, each cluster will have three nodes and a `RUNNING` status. If you do not see a similar output, check that you have selected the correct project.

The next step is to build the application.

Click **Next** to build the application.

## Build the application

In this section, you'll build the application so you can progress it through a delivery pipeline.

To create the container images, run the following command:

```bash
cd web-exec-envs && skaffold build --interactive=false --default-repo $(gcloud config get-value compute/region)-docker.pkg.dev/$(gcloud config get-value project)/web-app-exec-envs --file-output artifacts.json && cd ..
```

In the next step you will confirm the container images built by `Skaffold` were uploaded to the container image registry properly.

### Check the container images

When you ran `setup.sh` a repository in [Google Cloud Artifact Registry](https://cloud.google.com/artifact-registry) was created to serve the images. The previous command referenced the repository with the `--default-repo` parameter. To confirm the images were successfully pushed to Artifact Registry, run the following command:

```bash
gcloud artifacts docker images list $(gcloud config get-value compute/region)-docker.pkg.dev/$(gcloud config get-value project)/web-app-exec-envs --include-tags --format yaml
```

To create a service account, click **Next**.

## Create a service account

Create a service account to use in your execution environment. This is a security best practice, because you can assign the least privileges this service account needs to perform its task.

Create the service account by running the following command:

```bash
gcloud iam service-accounts create cd-executionuser
```

The output is similar to the following:

```terminal
Created service account [cd-executionuser].
```

This service account needs the `clouddeploy.jobRunner` and `container.developer` IAM roles to interact with Google Cloud Deploy and deploy workloads to GKE.

Associate the `clouddeploy.jobRunner` role with the service account:

```bash
gcloud projects add-iam-policy-binding {{project-id}} \
--member serviceAccount:cd-executionuser@{{project-id}}.iam.gserviceaccount.com \
--role roles/clouddeploy.jobRunner
```

Your output should include the following section:

```terminal
- members:
  - serviceAccount:cd-executionuser@{{project-id}}.iam.gserviceaccount.com
  role: roles/clouddeploy.jobRunner
```

Run the following command to associate the `container.developer` role with the service account:

```bash
gcloud projects add-iam-policy-binding {{project-id}} \
--member serviceAccount:cd-executionuser@{{project-id}}.iam.gserviceaccount.com \
--role roles/container.developer
```

Your output should include the following section:

```terminal
- members:
  - serviceAccount:cd-executionuser@{{project-id}}.iam.gserviceaccount.com
  role: roles/container.developer
```

To create a custom Cloud Storage bucket to use with Cloud Deploy, click **Next**.

## Create a Cloud Storage bucket

Execution environments have multiple [configuration options](https://cloud.google.com/deploy/docs/execution-environment#changing_the_storage_location) for artifact storage. In this tutorial, you store the render and deploy artifacts for your `test` target in a separate Cloud Storage bucket.

Create a new bucket:

```bash
gsutil mb gs://{{project-id}}-clouddeploy-test-artifacts
```

To confirm your bucket was created, run the following command:

```bash
gsutil ls
```

The output contains the buckets associated with your current project, including the default bucket previously created by Google Cloud Deploy.

To create a private pool, click **Next**.

## Create a Google Cloud Deploy private pool

Google Cloud Deploy uses Cloud Build to render and deploy releases to targets. In this tutorial, you use Cloud Build [private pools](https://cloud.google.com/build/docs/private-pools/) to perform these actions.

To create a custom pool of Cloud Build workers, run the following command:

```bash
gcloud builds worker-pools create clouddeploy-private --region us-central1
```

The output is similar to the following:

```terminal
Created [https://cloudbuild.googleapis.com/v1/projects/{{project-id}}/locations/us-central1/workerPools/projects%2F291844715210%2Flocations%2Fus-central1%2FworkerPools%2Fclouddeploy-private].
NAME                 CREATE_TIME                STATE
clouddeploy-private  2021-09-10T00:40:21+00:00  RUNNING
```

With your private pool created, you're ready to confirm that Google Cloud Deploy can use your custom resources.

Click **Next** to proceed.

## Configure Google Cloud Deploy

### Create a pipeline

To create a new Cloud Deploy pipeline, run the following command:

```bash
gcloud beta deploy apply --file=clouddeploy-config/delivery-pipeline-exec-envs.yaml
```

Verify the delivery pipeline was created:

```bash
gcloud beta deploy delivery-pipelines describe web-app-exec-envs
```

Your output should look like the example below. Notice that the targets are not yet created.

```terminal
Unable to get target test-exec-envs
Unable to get target staging-exec-envs
Unable to get target prod-exec-envs
Delivery Pipeline:
  createTime: '2022-01-04T14:12:18.979581436Z'
  description: web-app delivery pipeline for execution environments
  etag: 8733086084e52ee6
  name: projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app-exec-envs
  serialPipeline:
    stages:
    - targetId: test-exec-envs
    - targetId: staging-exec-envs
    - targetId: prod-exec-envs
  uid: b8deb1a32f434304b92bdba695bbbe59
  updateTime: '2022-01-04T14:12:19.275774368Z'
Targets: []
```

To create a target, click **Next**.

## Create a target

To configure Cloud Deploy to use your custom execution environment, open <walkthrough-editor-open-file filePath="clouddeploy-config/target-test-exec-envs.yaml">
`target-test-exec-envs.yaml`
</walkthrough-editor-open-file>.

The file `target-test-exec-envs.yaml` should look as follows:

```terminal
apiVersion: deploy.cloud.google.com/v1beta1
kind: Target
metadata:
  name: test-exec-envs
description: test cluster
gke:
  cluster: projects/{{project-id}}/locations/us-central1/clusters/test
executionConfigs:
- privatePool:
    artifactStorage: gs://{{project-id}}-clouddeploy-test-artifacts
    serviceAccount: cd-executionuser@{{project-id}}.iam.gserviceaccount.com
    workerPool: projects/{{project-id}}/locations/us-central1/workerPools/clouddeploy-private
  usages:
  - RENDER
  - DEPLOY
```

Notice the references to the custom `workerPool`, `serviceAccount` and `artifactStorage` resources you created earlier.

Run the following command to create the `test` target and associate it with the pipeline:

```bash
gcloud beta deploy apply --file clouddeploy-config/target-test-exec-envs.yaml
```

Run the following command to create the `staging` target:

```bash
gcloud beta deploy apply --file clouddeploy-config/target-staging-exec-envs.yaml
```

Finally, create the `prod` target:

```bash
gcloud beta deploy apply --file clouddeploy-config/target-prod-exec-envs.yaml
```

To confirm that Cloud Deploy is configured, run the following command. You should see the references to your custom resources in the output.

```bash
gcloud beta deploy targets describe test-exec-envs --delivery-pipeline=web-app-exec-envs
```

To create a new release to test the new execution environment, click **Next**.

## Test the execution environment

Run the following command to render a new release of the test application and automatically promote it to the `test` target cluster:

```bash
gcloud beta deploy releases create execution-test-001 --delivery-pipeline web-app-exec-envs --build-artifacts web-exec-envs/artifacts.json --source web-exec-envs/
```

To confirm that the test worked, click **Next**.

## Confirm that the test succeeded

### View the Cloud Storage bucket

After the promotion process to the test target begins, you should see content in your custom Cloud Storage bucket.

Use the following `gsutil` command to list the contents of your Cloud Storage bucket:

```bash
gsutil ls -R gs://{{project-id}}-clouddeploy-test-artifacts
```

The files and directory names will vary, but you should see something similar to the following:

```terminal
gs://{{project-id}}-clouddeploy-test-artifacts/execution-test-001-ef430f02c81e42b6802d7086eb238ddb/:

gs://{{project-id}}-clouddeploy-test-artifacts/execution-test-001-ef430f02c81e42b6802d7086eb238ddb/prod-exec-envs/:
gs://{{project-id}}-clouddeploy-test-artifacts/execution-test-001-ef430f02c81e42b6802d7086eb238ddb/prod-exec-envs/artifacts-80b158be-2bc9-48c6-9025-09e7d5be2c2c.json
gs://{{project-id}}-clouddeploy-test-artifacts/execution-test-001-ef430f02c81e42b6802d7086eb238ddb/prod-exec-envs/manifest.yaml
gs://{{project-id}}-clouddeploy-test-artifacts/execution-test-001-ef430f02c81e42b6802d7086eb238ddb/prod-exec-envs/skaffold.yaml

gs://{{project-id}}-clouddeploy-test-artifacts/execution-test-001-ef430f02c81e42b6802d7086eb238ddb/staging-exec-envs/:
gs://{{project-id}}-clouddeploy-test-artifacts/execution-test-001-ef430f02c81e42b6802d7086eb238ddb/staging-exec-envs/artifacts-f3fc9106-ffcc-4b0c-9cb2-d802358bb07e.json
gs://{{project-id}}-clouddeploy-test-artifacts/execution-test-001-ef430f02c81e42b6802d7086eb238ddb/staging-exec-envs/manifest.yaml
gs://{{project-id}}-clouddeploy-test-artifacts/execution-test-001-ef430f02c81e42b6802d7086eb238ddb/staging-exec-envs/skaffold.yaml

gs://{{project-id}}-clouddeploy-test-artifacts/execution-test-001-ef430f02c81e42b6802d7086eb238ddb/test-exec-envs/:
gs://{{project-id}}-clouddeploy-test-artifacts/execution-test-001-ef430f02c81e42b6802d7086eb238ddb/test-exec-envs/artifacts-69575909-abcb-48ea-ad4f-da168762911e.json
gs://{{project-id}}-clouddeploy-test-artifacts/execution-test-001-ef430f02c81e42b6802d7086eb238ddb/test-exec-envs/manifest.yaml
gs://{{project-id}}-clouddeploy-test-artifacts/execution-test-001-ef430f02c81e42b6802d7086eb238ddb/test-exec-envs/skaffold.yaml
```

### View the service account and public pool

Click the **Navigation menu**
<walkthrough-nav-menu-icon></walkthrough-nav-menu-icon>icon, then click
**History** in **Cloud Build**.

You can see where it is by clicking the following button:

<walkthrough-menu-navigation sectionId="CLOUD_BUILD_SECTION;builds">
</walkthrough-menu-navigation>

You can use Cloud Build to confirm the proper service account and private pool were used for the Google Cloud Deploy workflow.

Click your build. This shows a summary of the resources used for the build process.

These steps confirm that your new Google Cloud Deploy release used your custom execution environment to deploy resources to your test GKE cluster.

### Confirm that the application is running

Run the following command to view the application pods running in the `test` cluster:

```bash
kubectx test && kubectl get pods -n web-app-exec-envs
```

### 🎉 Success

You have successfully created and used a custom execution environment with Google Cloud Deploy.

To learn about next steps, click **Next**.

## Next steps

### Delete the project

If you created a project specifically for this tutorial, you can delete it using
the [Projects page](https://console.cloud.google.com/cloud-resource-manager) in
the Cloud Console to avoid incurring charges to your account for resources used
in this tutorial. This also deletes all underlying resources.

### Delete the pipeline

To delete the pipeline used in this tutorial, run the following command:

```bash
gcloud beta deploy delivery-pipelines delete web-app-exec-envs --force --quiet
```

### Delete the Cloud Build private worker pool

To delete the Cloud Build private worker pool, run the following command:

```bash
gcloud builds worker-pools delete clouddeploy-private --region us-central1
```

### Delete the service account

To delete the service account used for the execution environment, run the following command:

```bash
gcloud iam service-accounts delete cd-executionuser@{{project-id}}.iam.gserviceaccount.com
```

### Delete the Cloud Storage bucket

To delete the Cloud Storage bucket, run the following command:

```bash
gsutil -m rm -r gs://{{project-id}}-clouddeploy-test-artifacts
```

### Delete the target infrastructure and other resources

To delete the target infrastructure and other resources, run the provided cleanup script. If you would like to continue to the execution environments tutorial, do not complete this step.

```bash
./cleanup.sh
```

The script removes the Google Cloud resources and the artifacts in your Cloud Shell instance. The script takes about 10 minutes to complete.

### Clean up `gcloud` configurations

When you ran `bootstrap.sh`, a line was added to your Cloud Shell configuration. For users of the `bash` shell, a line was added to `.bashrc` to reference `$HOME/.gcloud` as the directory `gcloud` uses to keep configurations. If you customized your Cloud Shell environment to use other shells, the corresponding `rc` was similarly edited.

In the `.gcloud` directory a configuration named `clouddeploy` was also created. This features allows `gcloud` configurations to [persist across Cloud Shell sessions and restarts](https://cloud.google.com/shell/docs/configuring-cloud-shell#gcloud_command-line_tool_preferences).

To remove this configuration, remove the line from your `rc` file and delete the `$HOME/.gcloud` directory.

Click **Next** to complete this tutorial.

## Conclusion

Thank you for taking the time to get to know the Google Cloud Deploy Preview from Google Cloud!

<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>

<walkthrough-inline-feedback></walkthrough-inline-feedback>

You can find additional tutorials for Google Cloud Deploy in [Tutorials](https://cloud.google.com/deploy/docs/tutorials).
