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

### Select your Project

Once selected, set the same Project in your Cloud Shell `gcloud` configuration with this command:

```bash
gcloud config set project {{project-id}}
```

Click **Next** to proceed.

## Deploy infrastructure

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

Next you'll configure your Cloud Deploy Region parameter.

Click **Next** to proceed.

## Build the Application
Cloud Deploy integrates with [`skaffold`](https://skaffold.dev/), a leading open-source continuous-development toolset.

As part of this tutorial, a sample application has been cloned from a [Github repository](https://github.com/GoogleContainerTools/skaffold.git) to your Cloud Shell instance, in the `web` directory.

In this section, you'll build that application image so you can progress it through the `webapp` delivery pipeline.

### Build with Skaffold

The example application source code is in the `web` directory of your Cloud Shell instance. It's a simple web app that listens to a port, provides an HTTP response code and adds a log entry.

The `web` directory contains `skaffold.yaml`, which contains instructions for `skaffold` to build a container image for your application. This configuration uses the [Cloud Build](https://cloud.google.com/build) service to build the container images for your applications.

<walkthrough-editor-open-file filePath="web/skaffold.yaml">Click here to review skaffold.yaml.</walkthrough-editor-open-file>

When deployed, the application images are named `leeroy-web` and `leeroy-app`. To create these container images, run the following command:

```bash
cd web && skaffold build --interactive=false --default-repo $(gcloud config get-value compute/region)-docker.pkg.dev/{{project-id}}/web-app --file-output artifacts.json && cd ..
```

When you ran `bootstrap.sh` a [Google Cloud Artifact Registry](https://cloud.google.com/artifact-registry) was created to serve the images. The previous command referenced the repository with the `--default-repo` parameter. To confirm the images were successfully pushed to Artifact Registry:

```bash
gcloud artifacts docker images list $(gcloud config get-value compute/region)-docker.pkg.dev/$(gcloud config get-value project)/web-app --include-tags --format yaml
```
The `--format yaml` parameter returns the output as YAML for readability. The output should look like this:

```terminal
Listing items under project {{project-id}}, location us-central1, repository web-app.

---
createTime: '2021-05-13T20:31:13.636063Z'
package: us-central1-docker.pkg.dev/{{project-id}}/web-app/leeroy-app
tags: release-1.0-3-gf0649a5
updateTime: '2021-05-13T20:31:13.636063Z'
version: sha256:b5b63cb3deb5068b6d8a651bbd40947f81e2406ee7e5e9da507f0d39cada71d9
---
createTime: '2021-05-13T20:31:12.513087Z'
package: us-central1-docker.pkg.dev/{{project-id}}/web-app/leeroy-web
tags: release-1.0-3-gf0649a5
updateTime: '2021-05-13T20:31:12.513087Z'
version: sha256:d6a2da6aff0638ef4b6eb50134ab0109deb60a7434f690ed48462ed22e888905
```

By default, `skaffold` sets the tag for an image to its related `git` tag if one is available. In this case, a `v1` tag was set on the repository.

Similar information can be found in the `artifacts.json` file that was created by the `skaffold` command. You'll use that file in an upcoming step. <walkthrough-editor-open-file filePath="web/artifacts.json">Click here to review artifacts.json.</walkthrough-editor-open-file>

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
Unable to get target projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app/targets/test
Unable to get target projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app/targets/staging
Unable to get target projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app/targets/prod
Delivery Pipeline:
  createTime: '2021-05-13T20:22:22.880283007Z'
  description: web-app delivery pipeline
  etag: 2539eacd7f5c256d
  name: projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app
  serialPipeline:
    stages:
    - targetId: test
    - targetId: staging
    - targetId: prod
  uid: 7f9c9f7e90ee44869a21ce2215b5536c
  updateTime: '2021-05-13T20:22:24.151840532Z'
Targets: []
```

You can also see the [details for your delivery pipeline](https://console.cloud.google.com/deploy/delivery-pipelines/us-central1/web-app?project={{project-id}}) in the GCP control panel.

Notice the first three lines of the output. Your Delivery Pipeline references three Target environments that haven't been created yet. In the next sections you'll create those Targets.

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

Verify the `target` was created:

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

You can also view [details for your Target](https://console.cloud.google.com/deploy/delivery-pipelines/us-central1/web-app/targets/test?project={{project-id}}) in the GCP control panel.

Click **Next** to proceed.

## Create staging and prod targets
In this section, you create targets for the `staging` and `prod` clusters. The process is the same as for the `test` target you just created.

Start by creating the `staging` target.

<walkthrough-editor-open-file filePath="tutorial/clouddeploy-config/staging-environment.yaml">Click here to view staging-environment.yaml</walkthrough-editor-open-file>

Apply the `staging` target definition:

```bash
gcloud alpha deploy apply --file clouddeploy-config/staging-environment.yaml
```

Next you will repeat the process for the `prod` target.

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
approvalRequired: true
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

Because this is the first release of your application, name it `web-app-001`.

Run the following command to create the release. The `--build-artifacts` parameter references the `artifacts.json` file created by `skaffold` earlier. The `--source` parameter references the application source directory where `skaffold.yaml` can be found.

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
  tag: us-central1-docker.pkg.dev/{{project-id}}/web-app/leeroy-app:v1@sha256:23269937afe8c3827d40999902e48ad8a9ddb2a3d0fe1efbfcedd75c847ce43e
- imageName: leeroy-web
  tag: us-central1-docker.pkg.dev/{{project-id}}/web-app/leeroy-web:v1@sha256:51882af00331ccca196aa56e8bff69b377ed449a9cbbc013dd08d365bf385b36
createTime: '2021-05-14T10:23:16.378352077Z'
deliveryPipelineSnapshot:
  createTime: '1970-01-01T00:00:37.541324Z'
  description: web-app delivery pipeline
  etag: 2539eacd7f5c256d
  name: projects/408335957468/locations/us-central1/deliveryPipelines/web-app
  serialPipeline:
    stages:
    - targetId: test
    - targetId: staging
    - targetId: prod
  uid: c1c26b080e7e40379f0491862326d2fc
  updateTime: '1970-01-01T00:00:37.541324Z'
etag: a857d99c459bf9b5
manifestBucket: gs://{{project-id}}_clouddeploy/render
name: projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app/releases/web-app-001
renderState: SUCCESS
skaffoldConfigUri: gs://{{project-id}}_clouddeploy/source/1620987794.922149-81438ff3065c4d61b7dbfa46cbfd7bf8.tgz
targetSnapshots:
- createTime: '1970-01-01T00:00:40.904926Z'
  description: test cluster
  etag: 794c266d0db4cc28
  gkeCluster:
    cluster: test
    location: us-central1
    project: {{project-id}}
  name: projects/408335957468/locations/us-central1/deliveryPipelines/web-app/targets/test
  uid: b1fe05c0fb3249dd921660afb53e7974
  updateTime: '1970-01-01T00:00:40.904926Z'
- createTime: '1970-01-01T00:00:07.845918Z'
  description: staging cluster
  etag: d30e217167b30cd4
  gkeCluster:
    cluster: staging
    location: us-central1
    project: {{project-id}}
  name: projects/408335957468/locations/us-central1/deliveryPipelines/web-app/targets/staging
  uid: 7676fb491be94f1e90a0d0476a1f8308
  updateTime: '1970-01-01T00:00:07.845918Z'
- approvalRequired: true
  createTime: '1970-01-01T00:00:22.407141Z'
  description: prod cluster
  etag: 78c6e5a779b43e72
  gkeCluster:
    cluster: prod
    location: us-central1
    project: {{project-id}}
  name: projects/408335957468/locations/us-central1/deliveryPipelines/web-app/targets/prod
  uid: da928681694840e5b3976dd5b0a958d5
  updateTime: '1970-01-01T00:00:22.407141Z'
uid: 25b7ee6d14394a40a70b09fb4a006f64
```

You can also view [Release details](https://console.cloud.google.com/deploy/delivery-pipelines/us-central1/web-app/releases/web-app-001?project={{project-id}}) in the GCP control panel.

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
approvalState: DOES_NOT_NEED_APPROVAL
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

Note that the first rollout of a Release will take several minutes, because Cloud Deploy renders the manifests for all Targets when the Release is created. If you do not see _state: SUCCESS_ in the output from the previous command, please wait and periodically re-run the command until the rollout completes.

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

To promote your application to your staging Target, run the following command. The optional `--to-target` parameter can specify a Target to promote to. If this option isn't included, the Release is promoted to the next Target in the Delivery Pipeline.

```bash
gcloud alpha deploy releases promote --delivery-pipeline web-app --release web-app-001
```

To confirm your application has been promoted to the `staging` Target, run the following command:

```bash
gcloud alpha deploy rollouts list --delivery-pipeline web-app --release web-app-001
```

Your output should contain a section similar to this:

```terminal
---
approvalState: DOES_NOT_NEED_APPROVAL
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
The rollout may take several minutes. If you do not see _state: SUCCESS_ in the output from the previous command, please wait and periodically re-run the command until the rollout completes.

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
gcloud alpha deploy releases promote --delivery-pipeline web-app --release web-app-001
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

Due to the nature of this one-person tutorial, we're not going to actually use another account to approve the process. **This step is optional and not required for completion of subesequent steps**. But we will walk through creating a service account and binding it to the `clouddeploy.approver` role.

First, create a new service account.

```bash
gcloud iam service-accounts create pipeline-approver --display-name 'Web-App Pipeline Approver'
```

Confirm your new Service Account was created.

```bash
gcloud iam service-accounts list
```

Your output should include your new Approver Service Account as well as Service Accounts for each GKE cluster that were created with the bootstrap process. Note the `EMAIL` address for your new Approver service account. The command in the next step will use this email address.

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

After a short time, your promotion should complete. To verify this, run the following command:

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

The rollout may take several minutes. If you do not see _state: SUCCESS_ in the output from the previous command, please wait and periodically re-run the command until the rollout completes.

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

### Cleaning up gcloud configurations

When you ran `bootstrap.sh`, a line was added to your Cloud Shell configuration. For users of the `bash` shell, a line was added to `.bashrc` to reference `$HOME/.gcloud` as the directory `glcoud` uses to keep configurations. For people who have customized their Cloud Shell environments to use other shells, the corresponding `rc` was similarly edited.

In the `.gcloud` directory a configuration named `clouddeploy` was also created. This features allows `gcloud` configurations to [persist across Cloud Shell sessions and restarts](https://cloud.google.com/shell/docs/configuring-cloud-shell#gcloud_command-line_tool_preferences).

If you want to remove this configuration, remove the line from your `rc` file and delete the `$HOME/.gcloud` directory.

Click **Next** to complete this tutorial.

## Conclusion

Thank you for taking the time to get to know the Cloud Deploy Preview from Google Cloud!

<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>

<walkthrough-inline-feedback></walkthrough-inline-feedback>
