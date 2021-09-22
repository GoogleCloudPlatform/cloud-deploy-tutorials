<walkthrough-author
    tutorialname="Google Cloud Deploy Tutorial"
    repositoryUrl="https://clouddeploy.googlesource.com/tutorial"
    >
</walkthrough-author>

# Google Cloud Deploy: Preview

![Cloud Deploy logo](https://walkthroughs.googleusercontent.com/content/cloud_deploy_e2e_gke/images/cloud-deploy-logo-centered.png "Google Cloud Deploy logo")

## Overview
This tutorial guides you through setting up and using the Google [Cloud Deploy](https://console.cloud.google.com/deploy) service.

You'll create a GCP Project (or use an existing one if you want), to create a complete **test > staging > production** delivery pipeline using Google Cloud Deploy.

### About Cloud Shell
This tutorial uses [Google Cloud Shell](https://cloud.google.com/shell) to configure and interact with Google Cloud Deploy. Cloud Shell is an online development and operations environment, accessible anywhere with your browser.

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

This will take approximately 10 minutes to run.

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

Click **Next** to proceed.

## Build the Application
Google Cloud Deploy integrates with [`skaffold`](https://skaffold.dev/), a leading open-source continuous-development toolset.

As part of this tutorial, a sample application from the [Skaffold Github repository](https://github.com/GoogleContainerTools/skaffold.git) is available from your Cloud Shell instance, in the `web` directory.

In this section, you'll build that container image so you can progress it through the `webapp` delivery pipeline.

### Building with Skaffold

The example application source code is in the `web` directory of your Cloud Shell instance. It's a simple web app that listens to a port, provides an HTTP response code and adds a log entry.

The `web` directory contains `skaffold.yaml`, which contains instructions for `skaffold` to build a container image for your application. This configuration uses the [Cloud Build](https://cloud.google.com/build) service to build the container images for your applications.

<walkthrough-editor-open-file filePath="web/skaffold.yaml">Click here to review skaffold.yaml.</walkthrough-editor-open-file>

When deployed, the container images are named `leeroy-web` and `leeroy-app`. To create these container images, run the following command:

```bash
cd web && skaffold build --interactive=false --default-repo $(gcloud config get-value compute/region)-docker.pkg.dev/{{project-id}}/web-app --file-output artifacts.json && cd ..
```

In the next step you will confirm the container images built by `skaffold` were uploaded to the container image registry properly.

Click **Next** to proceed.

## Custom container images

When you ran `bootstrap.sh` a repository in [Google Cloud Artifact Registry](https://cloud.google.com/artifact-registry) was created to serve the images. The previous command referenced the repository with the `--default-repo` parameter. To confirm the images were successfully pushed to Artifact Registry, run the following command:

```bash
gcloud artifacts docker images list $(gcloud config get-value compute/region)-docker.pkg.dev/$(gcloud config get-value project)/web-app --include-tags --format yaml
```
The `--format yaml` parameter returns the output as YAML for readability. The output should look like this:

```terminal
Listing items under project {{project-id}}, location us-central1, repository web-app.

---
createTime: '2021-08-16T14:01:58.125999Z'
package: us-central1-docker.pkg.dev/{{project-id}}/web-app/leeroy-app
tags: v1
updateTime: '2021-08-16T14:01:58.125999Z'
version: sha256:71c0def49cbc6f414d9b2723f302654e6791f0db3948cc7bbf430ac0346224f8
---
createTime: '2021-08-16T14:01:55.719359Z'
package: us-central1-docker.pkg.dev/{{project-id}}/web-app/leeroy-web
tags: v1
updateTime: '2021-08-16T14:01:55.719359Z'
version: sha256:91161798f2f544cb0a21fc8c6cec3c3f824f46d64de5ce18846f74a9cc730d09
```

By default, `skaffold` sets the tag for an image to its related `git` tag if one is available. In this case, a `v1` tag was set on the repository.

Similar information can be found in the `artifacts.json` file that was created by the `skaffold` command. You'll use that file in an upcoming step. <walkthrough-editor-open-file filePath="web/artifacts.json">Click here to review artifacts.json.</walkthrough-editor-open-file>

Click **Next** to proceed.

## Create the delivery pipeline

In this tutorial, you will create a Google Cloud Deploy [_delivery pipeline_](https://console.cloud.google.com/deploy/delivery-pipelines?project={{project-id}}) that progresses a web application through three _targets_: `test`, `staging`, and `prod`. Google Cloud Deploy uses YAML files to define `delivery-pipeline` and `target` resources. For this tutorial, we have pre-created these files in the repository you cloned in Step 2.

<walkthrough-editor-open-file filePath="clouddeploy-config/delivery-pipeline.yaml">Click here to view delivery-pipeline.yaml</walkthrough-editor-open-file>

The following command creates the `delivery-pipeline` resource using the delivery pipeline YAML file:

```bash
gcloud beta deploy apply --file=clouddeploy-config/delivery-pipeline.yaml
```

Verify the delivery pipeline was created:

```bash
gcloud beta deploy delivery-pipelines describe web-app
```

Your output should look like the example below. 

```terminal
Unable to get target test
Unable to get target staging
Unable to get target prod
Delivery Pipeline:
  createTime: '2021-08-16T14:03:18.294884547Z'
  description: web-app delivery pipeline
  etag: 2539eacd7f5c256d
  name: projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app
  serialPipeline:
    stages:
    - targetId: test
    - targetId: staging
    - targetId: prod
  uid: eb0601aa03ac4b088d74c6a5f13f36ae
  updateTime: '2021-08-16T14:03:18.680753520Z'
Targets: []
```

You can also see the [details for your delivery pipeline](https://console.cloud.google.com/deploy/delivery-pipelines/us-central1/web-app?project={{project-id}}) in the GCP control panel.

Notice the first three lines of the output. Your Delivery Pipeline references three Target environments that haven't been created yet. In the next sections you'll create those Targets.

Click **Next** to proceed.

## Test target

In Google Cloud Deploy, a _target_ represents a GKE cluster where an application can be deployed as part of a delivery pipeline.

In the tutorial delivery pipeline, the first target is `test`.

You create a `target` by applying a YAML file to Google Cloud Deploy using `glcoud beta deploy apply`.

<walkthrough-editor-open-file filePath="clouddeploy-config/target-test.yaml">Click here to view the target-test.yaml</walkthrough-editor-open-file>

Create the `test` target:

```bash
gcloud beta deploy apply --file clouddeploy-config/target-test.yaml
```

Verify the `target` was created:

```bash
gcloud beta deploy targets describe test --delivery-pipeline=web-app
```

The output should look like the example below. Important information in this output is that the Target is recognized as a `gke` `cluster`.

```terminal
Target:
  createTime: '2021-08-16T14:04:02.848374540Z'
  description: test cluster
  etag: 7c430c4e71df8f43
  gke:
    cluster: projects/{{project-id}}/locations/us-central1/clusters/test
  name: projects/{{project-id}}/locations/us-central1/targets/test
  uid: c51b1e166442447e921c0e857be754a3
  updateTime: '2021-08-16T14:04:03.165134282Z'
```

You can also view [details for your Target](https://console.cloud.google.com/deploy/delivery-pipelines/us-central1/web-app/targets/test?project={{project-id}}) in the GCP control panel.

Click **Next** to proceed.

## Create staging and prod targets
In this section, you create targets for the `staging` and `prod` clusters. The process is the same as for the `test` target you just created.

Start by creating the `staging` target.

<walkthrough-editor-open-file filePath="clouddeploy-config/target-staging.yaml">Click here to view target-staging.yaml</walkthrough-editor-open-file>

Apply the `staging` target definition:

```bash
gcloud beta deploy apply --file clouddeploy-config/target-staging.yaml
```

Next you will repeat the process for the `prod` target.

<walkthrough-editor-open-file filePath="clouddeploy-config/target-prod.yaml">Click here to view target-prod.yaml</walkthrough-editor-open-file>

Apply the `prod` target definition:

```bash
gcloud beta deploy apply --file clouddeploy-config/target-prod.yaml
```

Verify both targets for the `web-app` delivery pipeline:

```bash
gcloud beta deploy targets list
```

The output should look like this, showing all three created Targets, which are used with your `web-app` Delivery Pipeline.

```terminal
targets:
- createTime: '2021-08-16T14:04:35.715192830Z'
  description: staging cluster
  etag: 59dfe1ad69cced01
  gke:
    cluster: projects/{{project-id}}/locations/us-central1/clusters/staging
  name: projects/{{project-id}}/locations/us-central1/targets/staging
  uid: 906ccca2037c4a339018eb7f92d86d37
  updateTime: '2021-08-16T14:04:36.012290125Z'
- createTime: '2021-08-16T14:04:02.848374540Z'
  description: test cluster
  etag: 7c430c4e71df8f43
  gke:
    cluster: projects/{{project-id}}/locations/us-central1/clusters/test
  name: projects/{{project-id}}/locations/us-central1/targets/test
  uid: c51b1e166442447e921c0e857be754a3
  updateTime: '2021-08-16T14:04:03.165134282Z'
- createTime: '2021-08-16T14:04:41.009584891Z'
  description: prod cluster
  etag: 95f6cfe4a63a7f5f
  gke:
    cluster: projects/{{project-id}}/locations/us-central1/clusters/prod
  name: projects/{{project-id}}/locations/us-central1/targets/prod
  requireApproval: true
  uid: b88f2b6546304fb6897710d058d2b025
  updateTime: '2021-08-16T14:04:41.360370226Z'
```

All Google Cloud Deploy targets for the delivery pipeline have now been created.

Click **Next** to proceed.

## Create a Release

A Google Cloud Deploy `release` is a specific version of one or more container images associated with a specific delivery pipeline. Once a release is created, it can be promoted through multiple targets (the _promotion sequence_). Additionally, creating a release renders your application using `skaffold` and saves the output as a point-in-time reference that's used for the duration of that release.

Because this is the first release of your application, name it `web-app-001`.

Run the following command to create the release. The `--build-artifacts` parameter references the `artifacts.json` file created by `skaffold` earlier. The `--source` parameter references the application source directory where `skaffold.yaml` can be found.

```bash
gcloud beta deploy releases create web-app-001 --delivery-pipeline web-app --build-artifacts web/artifacts.json --source web/
```

The command above references the delivery pipeline and the container images you created earlier in this tutorial.

To confirm your release has been created run the following command:

```bash
gcloud beta deploy releases list --delivery-pipeline web-app
```

Your output should look similar to the example below. Important things to note are that the release has been successfully rendered according to the `renderingState` value, as well as the location of the `skaffold` configuration noted by the `skaffoldConfigUri` parameter.

```terminal
---
buildArtifacts:
- image: leeroy-app
  tag: us-central1-docker.pkg.dev/{{project-id}}/web-app/leeroy-app:v1@sha256:71c0def49cbc6f414d9b2723f302654e6791f0db3948cc7bbf430ac0346224f8
- image: leeroy-web
  tag: us-central1-docker.pkg.dev/{{project-id}}/web-app/leeroy-web:v1@sha256:91161798f2f544cb0a21fc8c6cec3c3f824f46d64de5ce18846f74a9cc730d09
createTime: '2021-08-16T14:05:20.503428Z'
deliveryPipelineSnapshot:
  createTime: '2021-08-16T14:03:18.558786Z'
  description: web-app delivery pipeline
  etag: 2539eacd7f5c256d
  name: projects/123320843249/locations/us-central1/deliveryPipelines/web-app
  serialPipeline:
    stages:
    - targetId: test
    - targetId: staging
    - targetId: prod
  uid: eb0601aa03ac4b088d74c6a5f13f36ae
  updateTime: '2021-08-16T14:03:18.558786Z'
etag: fc081ad5de12a888
name: projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app/releases/web-app-001
renderEndTime: '2021-08-16T14:05:55.992810Z'
renderStartTime: '2021-08-16T14:05:21.803045346Z'
renderState: SUCCESS
renderingBuild: projects/123320843249/locations/us-central1/builds/d9a52630-d06a-4485-90b0-391f84b16b86
skaffoldConfigUri: gs://{{project-id}}_clouddeploy/source/1629122719.128778-7891f1bb5957480d8e974b9f99905896.tgz
skaffoldVersion: 1.24.0
targetArtifacts:
  prod:
    archiveUri: gs://us-central1.deploy-artifacts.{{project-id}}.appspot.com/web-app-001-2fea54fde3ac4def8abe5c63dc73cf32/prod.tar.gz
    manifestPath: manifest.yaml
    skaffoldConfigPath: skaffold.yaml
  staging:
    archiveUri: gs://us-central1.deploy-artifacts.{{project-id}}.appspot.com/web-app-001-2fea54fde3ac4def8abe5c63dc73cf32/staging.tar.gz
    manifestPath: manifest.yaml
    skaffoldConfigPath: skaffold.yaml
  test:
    archiveUri: gs://us-central1.deploy-artifacts.{{project-id}}.appspot.com/web-app-001-2fea54fde3ac4def8abe5c63dc73cf32/test.tar.gz
    manifestPath: manifest.yaml
    skaffoldConfigPath: skaffold.yaml
targetRenders:
  prod:
    renderingBuild: projects/123320843249/locations/us-central1/builds/d9a52630-d06a-4485-90b0-391f84b16b86
    renderingState: SUCCEEDED
  staging:
    renderingBuild: projects/123320843249/locations/us-central1/builds/d9a52630-d06a-4485-90b0-391f84b16b86
    renderingState: SUCCEEDED
  test:
    renderingBuild: projects/123320843249/locations/us-central1/builds/d9a52630-d06a-4485-90b0-391f84b16b86
    renderingState: SUCCEEDED
targetSnapshots:
- createTime: '2021-08-16T14:04:02.948551Z'
  description: test cluster
  etag: 7c430c4e71df8f43
  gke:
    cluster: projects/{{project-id}}/locations/us-central1/clusters/test
  name: projects/123320843249/locations/us-central1/targets/test
  uid: c51b1e166442447e921c0e857be754a3
  updateTime: '2021-08-16T14:04:02.948551Z'
- createTime: '2021-08-16T14:04:35.783821Z'
  description: staging cluster
  etag: 59dfe1ad69cced01
  gke:
    cluster: projects/{{project-id}}/locations/us-central1/clusters/staging
  name: projects/123320843249/locations/us-central1/targets/staging
  uid: 906ccca2037c4a339018eb7f92d86d37
  updateTime: '2021-08-16T14:04:35.783821Z'
- createTime: '2021-08-16T14:04:41.094770Z'
  description: prod cluster
  etag: 95f6cfe4a63a7f5f
  gke:
    cluster: projects/{{project-id}}/locations/us-central1/clusters/prod
  name: projects/123320843249/locations/us-central1/targets/prod
  requireApproval: true
  uid: b88f2b6546304fb6897710d058d2b025
  updateTime: '2021-08-16T14:04:41.094770Z'
uid: 6a18d3470ec84da8ac0f74720f9f4513
```

You can also view [Release details](https://console.cloud.google.com/deploy/delivery-pipelines/us-central1/web-app/releases/web-app-001?project={{project-id}}) in the GCP control panel.

When a release is created, it will also be automatically rolled out to the first Target in the pipeline (unless approval is required, which will be covered in a later step of this tutorial).

You can read more about this in the [Google Cloud Deploy delivery process](https://cloud.google.com/deploy/docs/overview#the_delivery_process) section of the documentation.

Click **Next** to proceed.

## Promoting Applications

With your release created, you can promote your application. When the Release was created in the previous step, it automatically rolled out your application to the initial Target. To confirm your `test` Target has your application deployed, run the following command:

```bash
gcloud beta deploy rollouts list --delivery-pipeline web-app --release web-app-001
```

Your output should look similar to the example below. The start and end times for the deploy are noted, as well that it succeeded.

```terminal
---
approvalState: DOES_NOT_NEED_APPROVAL
createTime: '2021-08-16T14:05:21.961604Z'
deployEndTime: '2021-08-16T14:06:35.278604Z'
deployStartTime: '2021-08-16T14:06:22.420091744Z'
deployingBuild: projects/123320843249/locations/us-central1/builds/4815b788-ec5e-4185-9141-a5b57c71b001
enqueueTime: '2021-08-16T14:06:21.760830Z'
etag: 5cb7b6c342b5f29b
name: projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app/releases/web-app-001/rollouts/web-app-001-to-test-0001
state: SUCCESS
targetId: test
uid: cccd9525d3a0414fa60b2771036841d9
```

Note that the first rollout of a Release will take several minutes, because Google Cloud Deploy renders the manifests for all Targets when the Release is created. If you do not see _state: SUCCESS_ in the output from the previous command, please wait and periodically re-run the command until the rollout completes.

To confirm your application was deployed to your test GKE cluster, run the following commands in your Cloud Shell:

```bash
kubectx test
kubectl get pods -n web-app
```

The output of your `kubectl` command should look similar to the following:

```terminal
NAME                          READY   STATUS    RESTARTS   AGE
leeroy-app-7b8d48f794-svl6g   1/1     Running   0          19s
leeroy-web-5498c5b7fd-czvm8   1/1     Running   0          20s
```

To promote your application to your staging Target, run the following command. The optional `--to-target` parameter can specify a Target to promote to. If this option isn't included, the Release is promoted to the next Target in the Delivery Pipeline.

```bash
gcloud beta deploy releases promote --delivery-pipeline web-app --release web-app-001
```

To confirm your application has been promoted to the `staging` Target, run the following command:

```bash
gcloud beta deploy rollouts list --delivery-pipeline web-app --release web-app-001
```

Your output should contain a section similar to this:

```terminal
---
approvalState: DOES_NOT_NEED_APPROVAL
createTime: '2021-08-16T14:09:49.522315Z'
deployEndTime: '2021-08-16T14:10:02.029182Z'
deployStartTime: '2021-08-16T14:09:50.199876916Z'
deployingBuild: projects/123320843249/locations/us-central1/builds/47218238-c661-466e-9005-cde9ffa6bbf1
etag: 6e25ab47add1d6ee
name: projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app/releases/web-app-001/rollouts/web-app-001-to-staging-0001
state: SUCCESS
targetId: staging
uid: b24b5f42db524fe4b0513c2f930e8196
```
The rollout may take several minutes. If you do not see _state: SUCCESS_ in the output from the previous command, please wait and periodically re-run the command until the rollout completes.

To confirm your application was deployed to your staging GKE cluster, run the following commands in your Cloud Shell:

```bash
kubectx staging
kubectl get pods -n web-app
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

When you created your prod environment, the configuration was in place to require approvals to this Target. To verify this, run this command and look for the `requireApproval` parameter.

```bash
gcloud beta deploy targets describe prod --delivery-pipeline web-app
```

Your output should look similar to the example below. Unlike the previous targets, the prod Target does require approval per the `requireApproval` parameter.

```terminal
Target:
  createTime: '2021-08-16T14:04:41.009584891Z'
  description: prod cluster
  etag: 95f6cfe4a63a7f5f
  gke:
    cluster: projects/{{project-id}}/locations/us-central1/clusters/prod
  name: projects/{{project-id}}/locations/us-central1/targets/prod
  requireApproval: true
  uid: b88f2b6546304fb6897710d058d2b025
  updateTime: '2021-08-16T14:04:41.360370226Z'
```

Go ahead and promote your application to your prod Target with this command

```bash
gcloud beta deploy releases promote --delivery-pipeline web-app --release web-app-001
```

When you look at your rollouts for `web-app-001`, you'll notice that the promotion to prod has a `PENDING_APPROVAL` status.

```bash
gcloud beta deploy rollouts list --delivery-pipeline web-app --release web-app-001
```

In the output, note that the `approvalState` is `NEEDS_APPROVAL` and the state is `PENDING_APPROVAL`.

```terminal
---
approvalState: NEEDS_APPROVAL
createTime: '2021-08-16T14:12:07.466989Z'
etag: 6e9303e5a1b04084
name: projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app/releases/web-app-001/rollouts/web-app-001-to-prod-0001
state: PENDING_APPROVAL
targetId: prod
uid: a5c7d6007fee4d80904d49142581aaa7
```

Next, you'll create a user with the proper IAM roles to approve this promotion to your prod Target and make your production push.

Click **Next** to proceed.

## Defining Approvers

Google Cloud Deploy is designed to integrate with multiple personas within an IT organization. For the product owner or team lead who approves production changes, there's a special IAM Role that can be bound to users and service accounts to give them the capability to approve pipeline promotions.

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

Service Accounts are used by CI tools like [Cloud Build](https://cloud.google.com/build) and [Jenkins](https://www.jenkins.io/) to interact programatically with GCP. This is a typical workflow for anyone integrating Google Cloud Deploy into their CI/CD toolchain.

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
gcloud beta deploy rollouts approve web-app-001-to-prod-0001 --delivery-pipeline web-app --release web-app-001
```

After a short time, your promotion should complete. To verify this, run the following command:

```bash
gcloud beta deploy rollouts list --delivery-pipeline web-app --release web-app-001
```

Your output should look similar to below. 

```terminal
---
approvalState: APPROVED
approveTime: '2021-08-16T14:12:53.289467Z'
createTime: '2021-08-16T14:12:07.466989Z'
deployEndTime: '2021-08-16T14:13:08.195241Z'
deployStartTime: '2021-08-16T14:12:53.760639336Z'
deployingBuild: projects/123320843249/locations/us-central1/builds/b4b1636d-8fc2-4442-ab89-e118bf56834c
enqueueTime: '2021-08-16T14:12:53.289467Z'
etag: b129bfd02c374040
name: projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app/releases/web-app-001/rollouts/web-app-001-to-prod-0001
state: SUCCESS
targetId: prod
uid: a5c7d6007fee4d80904d49142581aaa7
```

The rollout may take several minutes. If you do not see `state: SUCCESS` in the output from the previous command, please wait and periodically re-run the command until the rollout completes.

You can also confirm your `prod` GKE cluster has your apps deployed:

```bash
kubectx prod
kubectl get pod -n web-app
```

Your Google Cloud Deploy workflow approval worked, and your application is now deployed to your prod GKE cluster. In the next section you'll clean up the resources you've created for this tutorial.

Click **Next** to proceed.

## Cleaning Up

To clean up your GKE Targets and other resources, run the provided cleanup script. If you would like to continue to another tutorial, do not run this step, as these resources will be reused.

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

You can find additional tutorials for Google Cloud Deploy [here](https://cloud.google.com/deploy/docs/tutorials).
