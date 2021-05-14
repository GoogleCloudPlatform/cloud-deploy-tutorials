<walkthrough-author
    tutorialname="Cloud Deploy Tutorial"
    repositoryUrl="https://clouddeploy.googlesource.com/tutorial"
    >
</walkthrough-author>

# Cloud Deploy: Private Preview
## Overview
This tutorial guides you through setting up and using the Google [Cloud Deploy](https://console.cloud.google.com/deploy) service.

You'll create a GCP Project (or use an existing one if you want), to create a complete **test > staging > production** delivery pipeline using Cloud Deploy.

### About Cloud Shell
This tutorial uses [Google Cloud Shell](https://cloud.google.com/shell) to configure and interact with Cloud Deploy. Cloud Shell is an online development and operations environment, accessible anywhere with your browser. 

You can manage your resources with its online terminal, preloaded with utilities such as the `gcloud`, `kubectl`, and more. You can also develop, build, debug, and deploy your cloud-based apps using the online [Cloud Shell Editor](https://ide.cloud.google.com/).

Estimated Duration:
<walkthrough-tutorial-duration duration="45"></walkthrough-tutorial-duration>

Click **Start** to proceed.

## Project setup
GCP organizes resources into projects. This allows you to
collect all of the related resources for a single application in one place.

Begin by creating a new project or selecting an existing project for this
tutorial.

<walkthrough-project-setup billing="true"></walkthrough-project-setup>

For details, see
[Creating a project](https://cloud.google.com/resource-manager/docs/creating-managing-projects#creating_a_project).

### Selecting your Project

Once selected, set the same Project in your Cloud Shell `gcloud` configuration with this command:

```bash
gcloud config set project {{project-id}}
```

Click **Next** to proceed.

## Deploy tutorial infrastructure

You'll deploy three GKE clusters with the following names into your `{{project-id}}` Project: 

* `test` (often referred to as `dev`)
* `staging`
* `prod`

_Note_: If you have an existing GKE cluster in `{{project-id}}` with any of these names, you need to select a different project.

These GKE clusters are deployed into a Virtual Private Cloud in `{{project-id}}`. Next, run `bootstrap.sh` in your Cloud Shell to create the GKE clusters and supporting resources:

```bash
./bootstrap.sh
```

This will take a few minutes to run.

After the script finishes, confirm that your GKE clusters and supporting resources are properly deployed:

```bash
gcloud container clusters list
```

Your output should look like this:

```terminal
NAME     LOCATION     MASTER_VERSION    MASTER_IP       MACHINE_TYPE   NODE_VERSION      NUM_NODES  STATUS
prod     us-central1  1.17.17-gke.2800  35.194.37.64    n1-standard-2  1.17.17-gke.2800  3          RUNNING
staging  us-central1  1.17.17-gke.2800  35.232.139.69   n1-standard-2  1.17.17-gke.2800  3          RUNNING
test     us-central1  1.17.17-gke.2800  35.188.180.217  n1-standard-2  1.17.17-gke.2800  3          RUNNING
```

If the command succeeds, each cluster will have three nodes and a `RUNNING` status.

### Configure Cloud Deploy Region
Default Cloud Deploy parameters can be configured with `gcloud` to avoid typing them for every command.

Run the following command in Cloud Shell to set a default region for the rest of the commands in this tutorial: 

```bash
gcloud config set deploy/region $(gcloud config get-value compute/region)
```

This will be used for any additonal Cloud Deploy commands unless you override it using the `--region` parameter. In the next section you'll use `skaffold` to build your sample application.

Click **Next** to proceed.

## Build the Application
Cloud Deploy integrates with [`skaffold`](https://skaffold.dev/), a leading open-source continuous-development toolset.

As part of this tutorial, a sample application has been cloned from a [Github repository](https://github.com/GoogleContainerTools/skaffold.git) to your Cloud Shell instance, in the `web` directory. 

In this section, you'll build that application image so you can progress it through the `webapp` delivery pipeline.

### Build with Skaffold

The example application source code is in the `web` directory of your Cloud Shell instance. It's a simple web app that listens to a port, provides an HTTP response code and adds a log entry.

The `web` directory contains `skaffold.yaml`, which contains instructions for `skaffold` to build a container image for your application. This configuration uses the [Cloud Build](https://cloud.google.com/build) service to build the container images for your applications.

<walkthrough-editor-open-file filePath="tutorial/web/skaffold.yaml">Click here to review skaffold.yaml.</walkthrough-editor-open-file>

When deployed, the application images are named `leeroy-web` and `leeroy-app`. To create these container images, run the following command:

```bash
cd web && skaffold build --interactive=false --default-repo $(gcloud config get-value compute/region)-docker.pkg.dev/{{project-id}}/web-app --file-output artifacts.json && cd ..
```

Confirm the images were successfully pushed to Artifact Registry:

```bash
gcloud artifacts docker images list $(gcloud config get-value compute/region)-docker.pkg.dev/$(gcloud config get-value project)/web-app --include-tags --format json
```
The `--format json` parameter returns the output as JSON for readability. The output should look like this: 

```terminal
Listing items under project {{project-id}}, location us-central1, repository web-app.

[
  {
    "createTime": "2021-04-15T23:15:15.792959Z",
    "package": "us-central1-docker.pkg.dev/{{project-id}}/web-app/leeroy-app",    
    "tags": "v1",
    "updateTime": "2021-04-15T23:15:15.792959Z",
    "version": "sha256:80d8a867b82eb402ebe5b48f972c65c2b4cf7657ab30b03dd7b0b21dfc4a6792"
  },
  {
    "createTime": "2021-04-15T23:15:27.320207Z",
    "package": "us-central1-docker.pkg.dev/{{project-id}}/web-app/leeroy-web",
    "tags": "v1",
    "updateTime": "2021-04-15T23:15:27.320207Z",
    "version": "sha256:30c37ef69eaf759b8c151adea99b6e8cdde85a81b073b101fbc593eab98bc102"
  }
]
```

By default, `skaffold` sets the tag for an image to its related `git` tag if one is available. In this case, a `v1` tag was set on the repository.

Similar information can be found in the `artifacts.json` file that was created by the `skaffold` command. You'll use that file in an upcoming step. <walkthrough-editor-open-file filePath="tutorial/artifacts.json">Click here to review artifacts.json.</walkthrough-editor-open-file>

Click **Next** to proceed.

## Create the delivery pipeline

In this tutorial, you will create a Cloud Deploy [_delivery pipeline_](https://console.cloud.google.com/deploy/delivery-pipelines?project={{project-id}}) that progresses a web application through three _targets_: `test`, `staging`, and `prod`. Cloud Deploy uses YAML files to define `delivery-pipeline` and `target` resources. For this tutorial, we have pre-created these files in the repository you cloned in Step 2.

<walkthrough-editor-open-file filePath="tutorial/clouddeploy-config/delivery-pipeline.yaml">Click here to view delivery-pipeline.yaml</walkthrough-editor-open-file>
 
The following command creates the `delivery-pipeline` resource using the delivery pipeline YAML file: 

```bash
gcloud alpha deploy apply --file=clouddeploy-config/delivery-pipeline.yaml 
```

Verify the delivery pipeline was created:

```bash
gcloud alpha deploy delivery-pipelines describe web-app
```

The output should look like this:

```terminal
Delivery Pipeline:
  createTime: '2021-05-04T20:10:05.892293560Z'
  description: web-app delivery pipeline
  etag: 2539eacd7f5c256d
  name: projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app
  serialPipeline:
    stages:
    - targetId: test
    - targetId: staging
    - targetId: prod
  uid: 1e7225f13eb147ebb0c39752fed2951d
  updateTime: '2021-05-04T20:10:06.647329907Z'
Targets:[]
```

You can also see the [details for your delivery pipeline](https://console.cloud.google.com/deploy/delivery-pipelines/us-central1/web-app?project={{project-id}}) in the GCP control panel.

With your delivery pipeline confirmed, you're ready to create the three _targets_.

Click **Next** to proceed.

## Test target

In Cloud Deploy, a _target_ represents a GKE cluster where an application can be deployed as part of a delivery pipeline.

In the tutorial delivery pipeline, the first target is `test`.

You create a `target` by applying a YAML file to Cloud Deploy using `glcoud alpha deploy apply`.

<walkthrough-editor-open-file filePath="tutorial/clouddeploy-config/test-environment.yaml">Click here to view the test-environment.yaml</walkthrough-editor-open-file>

Create the `test` target: 

```bash
gcloud alpha deploy apply --file clouddeploy-config/test-environment.yaml
```

Verify the `target` was created using `gcloud alpha deploy` to list `target`s.

```bash
gcloud alpha deploy targets list --delivery-pipeline=web-app
```

The output should look like this:

```terminal
---
createTime: '2021-04-15T13:53:31.094996057Z'
description: test cluster
etag: 4c7d828d4f7a3b74
gkeCluster:
  cluster: test
  location: us-central1
  project: {{project-id}}
name: projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app/targets/test
uid: d1d2ca2dc4bf4884a8d16588cfe6d458
updateTime: '2021-04-15T13:53:31.663277590Z'
```

You can also view [details for your Target](https://console.cloud.google.com/deploy/delivery-pipelines/us-central1/web-app/targets/test?project={{project-id}) in the GCP control panel. 

Click **Next** to proceed.

## Create staging and prod targets
In this section, you create targets for the `staging` and `prod` clusters. The process is the same as for the `test` target you just created. 

Start by creating the `staging` target.

<walkthrough-editor-open-file filePath="tutorial/clouddeploy-config/staging-environment.yaml">Click here to view staging-environment.yaml</walkthrough-editor-open-file>

Apply the `staging` target definition: 

```bash
gcloud alpha deploy apply --file clouddeploy-config/staging-environment.yaml
```

Repeat the process for the `prod` target.

<walkthrough-editor-open-file filePath="tutorial/clouddeploy-config/prod-environment.yaml">Click here to view prod-environment.yaml</walkthrough-editor-open-file>

Apply the `prod` target definition:

```bash
gcloud alpha deploy apply --file clouddeploy-config/prod-environment.yaml
```

Verify both targets for the `web-app` delivery pipeline:

```bash
gcloud alpha deploy targets list --delivery-pipeline=web-app
```

The output should look like this:

```terminal
---
createTime: '2021-04-15T16:43:59.404939886Z'
description: staging cluster
etag: 9c923d5f1dd88c97
gkeCluster:
  cluster: staging
  location: us-central1
  project: {{project-id}}
name: projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app/targets/staging
uid: b1a856d72e5d43de817c2ea8380da39b
updateTime: '2021-04-15T16:44:00.272725580Z'
---
createTime: '2021-04-15T13:53:31.094996057Z'
description: test cluster
etag: 4c7d828d4f7a3b74
gkeCluster:
  cluster: test
  location: us-central1
  project: {{project-id}}
name: projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app/targets/test
uid: d1d2ca2dc4bf4884a8d16588cfe6d458
updateTime: '2021-04-15T13:53:31.663277590Z'
---
createTime: '2021-04-15T16:44:31.295700Z'
description: prod cluster
etag: ff1840e2d8c3010a
gkeCluster:
  cluster: prod
  location: us-central1
  project: {{project-id}}
name: projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app/targets/prod
uid: 0c22c1fb08e546ee9ae569ce501bac95
updateTime: '2021-04-15T16:44:32.078235982Z'
```

All Cloud Deploy targets for the delivery pipeline have now been created.

Click **Next** to proceed.

## Create a Release

A Cloud Deploy `release` is a specific version of one or more application images associated with a specific delivery pipeline. Once a release is created, it can be promoted through multiple targets (the _promotion sequence_). Additionally, creating a release renders your application using `skaffold` and saves the output as a point-in-time reference that's used for the duration of that release.

Because this is the first release of our application, we'll name it `web-app-001`.

Run the following command to create the release:

```bash
gcloud alpha deploy releases create web-app-001 --delivery-pipeline web-app --build-artifacts web/artifacts.json --source web/
```

The command above references the delivery pipeline and the container images you created earlier in this tutorial.

To confirm your release has been created run the following command: 

```bash
gcloud alpha deploy releases list --delivery-pipeline web-app
```

Your output should look similar to this: 

```terminal
---
buildArtifacts:
- imageName: leeroy-app
  tag: 'us-central1-docker.pkg.dev/{{project-id}}/web-app/leeroy-app:'
- imageName: leeroy-web
  tag: 'us-central1-docker.pkg.dev/{{project-id}}/web-app/leeroy-web:'
createTime: '2021-04-29T00:30:59.672965025Z'deliveryPipelineSnapshot:
  createTime: '1970-01-01T00:00:30.486775Z'
  description: web-app delivery pipeline
  etag: 2539eacd7f5c256d
  name: projects/619472186817/locations/us-central1/deliveryPipelines/web-app
  serialPipeline:
    stages:
    - targetId: test
    - targetId: staging
    - targetId: prod
```

You can also view [Release details](https://console.cloud.google.com/deploy/delivery-pipelines/us-central1/web-app/releases/web-app?project={{project-id}) in the GCP control panel.

With your release created, it's time to promote your application through your environments. 

Click **Next** to proceed.

## Promoting Applications

With your release created, you can promote your application. When the Release was created in the previous step, it automatically promoted your application to the initial Target. To confirm your `test` Target has your application deployed, run the following command:

```bash
gcloud alpha deploy rollouts list --delivery-pipeline web-app --release web-app-001
```

Your output should look similar to this:

```terminal
---
createTime: '2021-04-30T18:46:45.657293361Z'
deployBuild: 3915c189-e9b4-4c6e-b757-322d8db18188
deployEndTime: '2021-04-30T18:47:31.951451Z'
deployStartTime: '2021-04-30T18:46:47.234151706Z'
etag: d4a044da3c830258
name: projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app/releases/web-app-001/rollouts/web-app-001-to-test-0002
state: SUCCESS
target: test
uid: f37126ebe3764108beb081c7e2930d7a
```

To confirm your application was deployed to your test GKE cluster, run the following commands in your Cloud Shell: 

```bash
kubectx test
kubectl get pods -n default
```

The output of your `kubectl` command should look similar to the following: 

```terminal
NAME                          READY   STATUS    RESTARTS   AGE
leeroy-app-7b8d48f794-svl6g   1/1     Running   0          19s
leeroy-web-5498c5b7fd-czvm8   1/1     Running   0          20s
```

To promote your application to your staging Target, run the following command: 

```bash
gcloud alpha deploy releases promote --delivery-pipeline web-app --release web-app-001 --to-target staging
```

To confirm your application has been promoted to the `staging` Target, run the following command:

```bash
gcloud alpha deploy rollouts list --delivery-pipeline web-app --release web-app-001
```

Your output should contain a section similar to this:

```terminal
---
createTime: '2021-04-30T18:46:45.657293361Z'
deployBuild: 3915c189-e9b4-4c6e-b757-322d8db18188
deployEndTime: '2021-04-30T18:47:31.951451Z'
deployStartTime: '2021-04-30T18:46:47.234151706Z'
etag: d4a044da3c830258
name: projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app/releases/web-app-001/rollouts/web-app-001-to-staging-0001
state: SUCCESS
target: staging
uid: f37126ebe3764108beb081c7e2930d7a
```

To confirm your application was deployed to your staging GKE cluster, run the following commands in your Cloud Shell:

```bash
kubectx staging
kubectl get pods -n default
```

The output of your `kubectl` command should look similar to the following:

```terminal
NAME                          READY   STATUS    RESTARTS   AGE
leeroy-app-7b8d48f794-svl6g   1/1     Running   0          19s
leeroy-web-5498c5b7fd-czvm8   1/1     Running   0          20s
```

In the next section, you'll look at Targets that require approvals before Promotions can complete.

Click **Next** to proceed. 

## Approvals

Any Target can require an Approval before a Release promotion can occur. This is designed to protect production and sensitive Targets from accidentally promoting a release before it's been fully vetted and tested.

### Requiring Approval for Promotion to a Target

When you created your prod environment, the configuration was in place to require approvals to this Target. To verify this, run this command and look for the `approvalRequired` parameter.

```bash
gcloud alpha deploy targets describe prod --delivery-pipeline web-app
```

Your output should look similar to this: 

```terminal
Target:
  approvalRequired: true
  createTime: '2021-04-30T18:40:11.068571913Z'
  description: prod cluster
  etag: 74a0c6560ae0ace7
  gkeCluster:
    cluster: prod
    location: us-central1
    project: {{project-id}}
  name: projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app/targets/prod
  uid: 95fbe354bc07435f8248712a44035ca0
  updateTime: '2021-04-30T20:39:57.398607646Z'
```

Go ahead and promote your application to your prod Target with this command 

```bash
gcloud alpha deploy releases promote --delivery-pipeline web-app --release web-app-001 --to-target prod
```

When you look at your rollouts for `web-app-001`, you'll notice that the promotion to prod has a `PENDING_APPROVAL` status.

```bash
gcloud alpha deploy rollouts list --delivery-pipeline web-app --release web-app-001
```

```terminal
approvalState: NEEDS_APPROVAL
createTime: '2021-05-03T17:23:18.183598192Z'
etag: ac30600d82dcb0f
name: projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app/releases/web-app-001/rollouts/web-app-001-to-prod-0001
state: PENDING_APPROVAL
target: prod
uid: f7de1bc9af4e46e499cc0c134b3758a6
```

Next, you'll create a user with the proper IAM roles to approve this promotion to your prod Target and make your production push. 

Click **Next** to proceed.

## Defining Approvers

Cloud Deploy is designed to integrate with multiple personas within an IT organization. For the product owner or team lead who approves production changes, there's a special IAM Role that can be bound to users and service accounts to give them the capability to approve pipeline promotions. 

Due to the nature of this one-person tutorial, we're not going to actually use another account to approve the process. But we will walk through creating a service account and binding it to the `clouddeploy.approver` role.

First, create a new service account. 

```bash
gcloud iam service-accounts create pipeline-approver --display-name 'Web-App Pipeline Approver'
```

Confirm your new Service Account was created. 

```bash
gcloud iam service-accounts list
```

Your output should include your new Approver Service Account as well as Service Accounts for each GKE cluster that were created with the bootstrap process. Note the `EMAIL` address for your new Approver service account. You'll need it in the next step.

```terminal
DISPLAY NAME                            EMAIL                                                           DISABLED
Cluster Service Account for test        tf-sa-test@{{project-id}}.iam.gserviceaccount.com         False
Cluster Service Account for prod        tf-sa-prod@{{project-id}}.iam.gserviceaccount.com         False
Cluster Service Account for staging     tf-sa-staging@{{project-id}}.iam.gserviceaccount.com      False
Web-App Pipeline Approver               pipeline-approver@{{project-id}}.iam.gserviceaccount.com  False
Compute Engine default service account  619472186817-compute@developer.gserviceaccount.com              False
```

Service Accounts are used by CI tools like [Cloud Build](https://cloud.google.com/build) and [Jenkins](https://www.jenkins.io/) to interact programatically with GCP. This is a typical workflow for anyone integrating Cloud Deploy into their CI/CD toolchain.

### Add Approval Permissions

To bind the `clouddeploy.approver` role to your new Service Account, run this command. 

```bash
gcloud projects add-iam-policy-binding {{project-id}} --member=serviceAccount:pipeline-approver@{{project-id}}.iam.gserviceaccount.com --role=roles/clouddeploy.approver
```

In the long output, you should notice this output. 

```terminal
- members:
  - serviceAccount:pipeline-approver@{{project-id}}.iam.gserviceaccount.com
  role: roles/clouddeploy.approver
```

In the next section you'll promote your application to your prod Target.

Click **Next** to proceed.

## Deploying to Prod

To approve your application and promote it to your prod Target, use this command: 

```bash
gcloud alpha deploy rollouts approve web-app-001-to-prod-0001 --delivery-pipeline web-app --release web-app-001
```

After a short time, your promotion should complete. Verify this by running the `gcloud alpha deploy rollouts list --delivery-pipeline web-app` command: 

```bash
gcloud alpha deploy rollouts list --delivery-pipeline web-app --release web-app-001
```

Your output should look similar to this: 

```terminal
approvalState: APPROVED
createTime: '2021-05-03T17:23:18.183598192Z'
deployBuild: 27c9a286-2a88-419e-be5b-a79fa6248f60
deployEndTime: '2021-05-03T19:00:26.526217Z'
deployStartTime: '2021-05-03T18:59:46.114953201Z'
etag: 205ff1e1a8d8c4f6
name: projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app/releases/web-app-001/rollouts/web-app-001-to-prod-0001
state: SUCCESS
target: prod
uid: f7de1bc9af4e46e499cc0c134b3758a6
```

You can also confirm your `prod` GKE cluster has your apps deployed: 

```bash
kubectx prod
kubectl get pod -n default
```

Your Cloud Deploy workflow approval worked, and your application is now deployed to your prod GKE cluster. In the next section you'll clean up the resources you've created for this tutorial. 

Click **Next** to proceed.

## Cleaning Up

To clean up your GKE Targets and other resources, run the provided cleanup script.

```bash
./cleanup.sh
```

This will remove the GCP resources as well as the artifacts on your Cloud Shell instance. It may take a few minutes to complete.

Click **Next** to complete this tutorial.

## Conclusion

Thank you for taking the time to get to know the Cloud Deploy tool from Google Cloud! 

<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>

<walkthrough-inline-feedback></walkthrough-inline-feedback>

Here's what you can do next:


