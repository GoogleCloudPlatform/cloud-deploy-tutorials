<walkthrough-author
    tutorialname="Google Cloud Deploy Tutorial - Execution Environments"
    repositoryUrl="https://clouddeploy.googlesource.com/tutorial"
    >
</walkthrough-author>

# Google Cloud Deploy: Preview

![Google Cloud Deploy logo](https://walkthroughs.googleusercontent.com/content/cloud_deploy_e2e_gke/images/cloud-deploy-logo-centered.png "Google Cloud Deploy logo")

## Overview
This tutorial guides you through creating and using custom Execution Environments with the Google [Cloud Deploy](https://console.cloud.google.com/deploy) service.

Following on from the Google Cloud Deploy End-to-end tutorial, you will use a **test > staging > production** delivery pipeline to deploy an application that will use custom execution environments for for each target.

Please note that you must complete the [Google Cloud Deploy Walkthrough]( https://cloud.google.com/deploy/docs/tutorials) before starting this one, and you must run them in the same project.

If you have not done so, please visit [the tutorials page](https://cloud.google.com/deploy/docs/tutorials), complete the Google Cloud Deploy End-to-end tutorial first, then resume this tutorial.

## About Execution Environments
Google Cloud Deploy uses the following defaults when rendering and deploying a workload to a target. They are: 

* The default [Cloud Build worker pool](https://cloud.google.com/build/docs/private-pools/private-pools-overview) is used for Cloud Deploy builds. The default worker pool is a secure hosted environment where each build runs in an isolated worker.
* The default [GCE Service Account](https://cloud.google.com/deploy/docs/cloud-deploy-service-account#default_service_account) is used to access Cloud Build and your Cloud Deploy targets.
* Google Cloud Deploy creates a GCS bucket in the same region as the Cloud Deploy resources. This bucket holds all artifacts by default. It has the the naming syntax of `<location>.deploy-artifacts.<project ID>.appspot.com`.

In this tutorial we'll create these custom resources and configure Google Cloud Deploy to use them in a custom [Execution Environment](https://cloud.google.com/deploy/docs/execution-environment).

### About Cloud Shell
This tutorial uses [Google Cloud Shell](https://cloud.google.com/shell) to configure and interact with Google Cloud Deploy. Cloud Shell is an online development and operations environment, accessible anywhere with your browser.

You can manage your resources with its online terminal, preloaded with utilities such as the `gcloud`, `kubectl`, and more. You can also develop, build, debug, and deploy your cloud-based apps using the online [Cloud Shell Editor](https://ide.cloud.google.com/).

Estimated Duration:
<walkthrough-tutorial-duration duration="30"></walkthrough-tutorial-duration>

Click **Next** to proceed.

## Project setup
GCP organizes resources into projects. This allows you to collect all of the related resources for a single application in one place.

Begin by selecting an existing project for this tutorial.

***This project must be the project you used for the [Google Cloud Deploy End-to-end walkthrough](https://cloud.google.com/deploy/docs/tutorials), because infrastructure and Google Cloud Deploy Targets are reused.***

<walkthrough-project-setup billing="true"></walkthrough-project-setup>

### Select your Project

Once selected, set the same Project in your Cloud Shell `gcloud` configuration with this command:

```bash
gcloud config set project {{project-id}}
```

Click **Next** to proceed.

## Check Infrastructure

First, confirm that your GKE clusters and supporting resources are properly deployed:

```bash
gcloud container clusters list
```

Your output should look like this:

```terminal
NAME     LOCATION     MASTER_VERSION   MASTER_IP       MACHINE_TYPE   NODE_VERSION     NUM_NODES  STATUS
prod     us-central1  1.18.20-gke.501  34.68.73.47     n1-standard-2  1.18.20-gke.501  3          RUNNING
staging  us-central1  1.18.20-gke.501  34.134.168.213  n1-standard-2  1.18.20-gke.501  3          RUNNING
test     us-central1  1.18.20-gke.501  35.239.164.76   n1-standard-2  1.18.20-gke.501  3          RUNNING
```

If the command succeeds, each cluster will have three nodes and a `RUNNING` status. If you do not see output similar to the above, check that you have selected the correct project.

Click **Next** to proceed.

## Creating Service Accounts

In this step, we'll create a new GCP service account to use in our Execution Environment. This is a security best practice because we can assign the least privileges this service account needs to perform its task. First, create the service account: 

```bash
gcloud iam service-accounts create cd-executionuser

```

Your confirmation will look similar to: 

```terminal
Created service account [cd-executionuser].
```

This service account needs to have the `clouddeploy.jobRunner` and `container.developer` IAM roles to interact with Google Cloud Deploy and deploy workloads to GKE. We'll do that next. 

```bash
gcloud projects add-iam-policy-binding {{project-id}} \
--member serviceAccount:cd-executionuser@{{project-id}}.iam.gserviceaccount.com \
--role roles/clouddeploy.jobRunner \

gcloud projects add-iam-policy-binding {{project-id}} \
--member serviceAccount:cd-executionuser@{{project-id}}.iam.gserviceaccount.com \
--role roles/container.developer
```

Your output should include the following output: 

```terminal
- members:
  - serviceAccount:cd-executionuser@{{project-id}}.iam.gserviceaccount.com
  role: roles/clouddeploy.jobRunner
```

With these steps complete, we'll create a custom GCS bucket next.

Click **Next** to proceed.

## Creating a GCS Bucket

Execution environments have multiple [configuration options](https://cloud.google.com/deploy/docs/execution-environment#changing_the_storage_location) for artifact storage. In this tutorial we'll store the render and deploy artifacts for our `dev` Target in a separate GCS bucket.  To create a new bucket, run the following command in Cloud Shell: 

```bash

gsutil mb gs://{{project-id}}-clouddeploy-test-artifacts
```

To confirm your bucket was created, run the following command: 

```bash

gsutil ls
```

This will list all of the GCS buckets associated with your current project, including the default bucket previously created by Google Cloud Deploy. Next, you'll create a custom worker pool.

Click **Next** to proceed.

## Creating a Google Cloud Deploy Private Worker Pool

As previously mentioned, Google Cloud Deploy uses Cloud Build to render and deploy releases to targets. In this tutorial, we will use a Cloud Build [Private Worker Pools](https://cloud.google.com/build/docs/private-pools/) to perform these activities.

To create a custom pool of Cloud Build workers, run the following command:

```bash
gcloud builds worker-pools create clouddeploy-private --region us-central1
```

You should see output similar to this:

```terminal
Created [https://cloudbuild.googleapis.com/v1/projects/{{project-id}}/locations/us-central1/workerPools/projects%2F291844715210%2Flocations%2Fus-central1%2FworkerPools%2Fclouddeploy-private].
NAME                 CREATE_TIME                STATE
clouddeploy-private  2021-09-10T00:40:21+00:00  RUNNING
```

With your Private Worker Pool created, you're ready to configure Google Cloud Deploy to use your custom resources.

Click **Next** to proceed.

## Configuring Google Cloud Deploy

To make use of your custom Execution Environment, open <walkthrough-editor-open-file filePath="clouddeploy-config/target-test.yaml">
target-test.yaml
</walkthrough-editor-open-file>.

Edit `target-test.yaml` to make it look as follows: 

```bash
apiVersion: deploy.cloud.google.com/v1beta1
kind: Target
metadata:
  name: test
description: test cluster
gke:
  cluster: projects/{{project-id}}/locations/us-central1/clusters/test
executionConfigs:
- privatePool:
    workerPool: projects/{{project-id}}/locations/us-central1/workerPools/clouddeploy-private
    serviceAccount: cd-executionuser@{{project-id}}.iam.gserviceaccount.com
    artifactStorage: gs://{{project-id}}-clouddeploy-test-artifacts
  usages:
  - RENDER
  - DEPLOY
```

Once edited, apply the changes to your `test` Target with the following command:

```bash
gcloud beta deploy apply --file clouddeploy-config/target-test.yaml
```

To confirm the changes have taken affect, run the following command. You should notice the `privatePool` stanza in the output.

```bash
gcloud beta deploy targets describe test --delivery-pipeline=web-app
```

Next, we'll create a new release to test the new Execution Environment.

Click **Next** to proceed.

## Testing Your Execution Environment

```bash
gcloud beta deploy releases create execution-test-001 --delivery-pipeline web-app --build-artifacts web/artifacts.json --source web/
```

This will render a new release of the test application and automatically promote it to the test target cluster. 

Click **Next** to proceed.

## Confirming It Worked

### GCS Bucket

Once the promotion process to the test target begins, you should see content in your custom GCS bucket. Use the `gsutil command` to explore your GCS bucket. 

```bash
gsutil ls gs://{{project-id}}-clouddeploy-test-artifacts
```

The files and directory names will vary, but you should see something similar to this content: 

```terminal 
gs://{{project-id}}-clouddeploy-test-artifacts/execution-test-001-13698fa76b004da495fab8911917f25c/test/artifacts-3b9337ff-389d-4bb2-93a4-cea598667214.json
gs://{{project-id}}-clouddeploy-test-artifacts/execution-test-001-13698fa76b004da495fab8911917f25c/test/manifest.yaml
gs://{{project-id}}-clouddeploy-test-artifacts/execution-test-001-13698fa76b004da495fab8911917f25c/test/skaffold.yaml
```

### Service Account and Private Pool

The [Cloud Build UI](https://console.cloud.google.com/cloud-build/builds;region=us-central1?project={{project-id}}) makes it easy to confirm the proper Service Account and Private Pool were used for the Google Cloud Deploy workflow. Click on your Build > Execution Details and it gives you a complete summary of the resources used for the build process.

These steps confirm that your new Google Cloud Deploy release used your custom Execution Environment to deploy resources to your test GKE cluster. 

Click **Next** to proceed.

## Cleaning Up

To clean up your GKE Targets and other resources, run the provided cleanup script. If you would like to continue to another tutorial, do not complete this step.

```bash
./cleanup.sh
```

This will remove the GCP resources as well as the artifacts on your Cloud Shell instance. It will take around 10 minutes to complete.

### Cleaning up gcloud configurations

When you ran `bootstrap.sh`, a line was added to your Cloud Shell configuration. For users of the `bash` shell, a line was added to `.bashrc` to reference `$HOME/.gcloud` as the directory `glcoud` uses to keep configurations. For people who have customized their Cloud Shell environments to use other shells, the corresponding `rc` was similarly edited.

In the `.gcloud` directory a configuration named `clouddeploy` was also created. This features allows `gcloud` configurations to [persist across Cloud Shell sessions and restarts](https://cloud.google.com/shell/docs/configuring-cloud-shell#gcloud_command-line_tool_preferences).

If you want to remove this configuration, remove the line from your `rc` file and delete the `$HOME/.gcloud` directory.

Click **Next** to complete this tutorial.

## Conclusion

Thank you for taking the time to get to know the Google Cloud Deploy Preview from Google Cloud!

<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>

<walkthrough-inline-feedback></walkthrough-inline-feedback>
