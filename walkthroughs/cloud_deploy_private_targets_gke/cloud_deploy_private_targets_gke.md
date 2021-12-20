# Google Cloud Deploy: Preview

![](https://walkthroughs.googleusercontent.com/content/cloud_deploy_e2e_gke/images/cloud-deploy-logo-centered.png)

## Overview

This interactive tutorial shows you how to set up and use [Google Cloud Deploy](https://console.cloud.google.com/deploy) to deploy to [private GKE clusters](https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters).

You will use a **test > staging > production** delivery pipeline to deploy an application to private targets.

Commonly, organizations do not want to expose their GKE cluster API endpoints to the public Internet, even if they are configured to accept connections only from a range of known IP addressees. GKE private clusters make it possible for cluster API endpoints to be accessible only via private (i.e. RFC 1918) IP addressing scheme. You can configure Cloud Deploy to deploy to these clusters by using [Cloud Build Private Pools](https://cloud.google.com/build/docs/private-pools/private-pools-overview). This means that Cloud Deploy is able to deploy to your GKE clusters even if they are only accessible from within your VPC.

### About Cloud Shell

This tutorial uses [Google Cloud Shell](https://cloud.google.com/shell) to configure and interact with Google Cloud Deploy. Cloud Shell is an online development and operations environment, accessible anywhere with your browser.

You can manage your resources with its online terminal, preloaded with utilities such as the `gcloud`, `kubectl`, and more. You can also develop, build, debug, and deploy your cloud-based apps using the online [Cloud Shell Editor](https://ide.cloud.google.com/).

Estimated Duration:
<walkthrough-tutorial-duration duration="45"></walkthrough-tutorial-duration>

Click **Start** to proceed.

## Project and workspace setup

Google Cloud organizes resources into projects. This allows you to collect all of the related resources for a single application in one place.

Begin by creating a new project or selecting an existing project for this tutorial.

<walkthrough-project-setup billing="true"></walkthrough-project-setup>

For details, see [Creating a project](https://cloud.google.com/resource-manager/docs/creating-managing-projects#creating_a_project).

### Select your Project in Cloud Shell

Once selected, set the project in Cloud Shell:

```bash
gcloud config set project {{project-id}}
```

### Clone the tutorial repository

Run the following command to clone the tutorial repository into your Cloud Shell environment:

```bash
./scripts/clone-tutorial-repo.sh
```

Next, change into the directory for this tutorial and set your workspace:

```bash
cd cloud-deploy-tutorials/tutorials/private-targets && cloudshell workspace .
```

If your Cloud Shell session times out, you can resume the tutorial by reconnecting to Cloud Shell and rerunning the previous command to change into the above directory.

To deploy your infrastructure, click **Next** to proceed.

## Deploy infrastructure

You will deploy three private GKE clusters with the following names into your `{{project-id}}` Project:

* `test` (often referred to as `dev`)
* `staging`
* `prod`

_Note_: If you have an existing GKE cluster in `{{project-id}}` with any of these names, you need to select a different project.

These GKE clusters are deployed into a Virtual Private Cloud in `{{project-id}}`.

Run `setup.sh` in your Cloud Shell to create the GKE clusters and supporting resources:

```bash
./setup.sh
```

This will take approximately 10 minutes to run.

After the script finishes, confirm that your GKE clusters and supporting resources are properly deployed:

```bash
gcloud container clusters list
```

The output is similar to the following:

```terminal
NAME     LOCATION     MASTER_VERSION    MASTER_IP       MACHINE_TYPE   NODE_VERSION      NUM_NODES  STATUS
prod     us-central1  1.17.17-gke.2800  35.194.37.64    n1-standard-2  1.17.17-gke.2800  3          RUNNING
staging  us-central1  1.17.17-gke.2800  35.232.139.69   n1-standard-2  1.17.17-gke.2800  3          RUNNING
test     us-central1  1.17.17-gke.2800  35.188.180.217  n1-standard-2  1.17.17-gke.2800  3          RUNNING
```

If the command succeeds, each cluster will have three nodes and a `RUNNING` status.

Click **Next** to proceed.

## Build the application

Google Cloud Deploy integrates with [`skaffold`](https://skaffold.dev/), a leading open-source continuous-development toolset.

As part of this tutorial, a sample application from the [Skaffold Github repository](https://github.com/GoogleContainerTools/skaffold.git) is available from your Cloud Shell instance, in the `web-private-targets` directory.

In this section, you'll build the application so you can progress it through the `webapp-private-targets` delivery pipeline.

### Building with skaffold

The example application source code is in the `web-private-targets` directory of your Cloud Shell instance. It's a simple web app that listens to a port, provides an HTTP response code and adds a log entry. You may have deployed this application as part of another Cloud Deploy tutorial.

The `web-private-targets` directory contains `skaffold.yaml`, which contains instructions for `skaffold` to build a container image for your application. This configuration uses the [Cloud Build](https://cloud.google.com/build) service to build the container images for your applications.

<walkthrough-editor-open-file filePath="web/skaffold.yaml">Click here to review skaffold.yaml.</walkthrough-editor-open-file>

When deployed, the container images are named `leeroy-web` and `leeroy-app`. To create these container images, run the following command:

```bash
cd web-private-targets && skaffold build --interactive=false --default-repo $(gcloud config get-value compute/region)-docker.pkg.dev/{{project-id}}/web-app-private-targets --file-output artifacts.json && cd ..
```

In the next step you will confirm the container images built by `skaffold` were uploaded to the container image registry properly.

To check the images, click **Next**.

## Custom container images

When you ran `bootstrap.sh` a repository in [Google Cloud Artifact Registry](https://cloud.google.com/artifact-registry) was created to serve the images. The previous command referenced the repository with the `--default-repo` parameter. To confirm the images were successfully pushed to Artifact Registry, run the following command:

```bash
gcloud artifacts docker images list $(gcloud config get-value compute/region)-docker.pkg.dev/$(gcloud config get-value project)/web-app-private-targets --include-tags --format yaml
```
The `--format yaml` parameter returns the output as YAML for readability. The output should look like this:

```terminal
Listing items under project {{project-id}}, location us-central1, repository web-app-private-targets.

---
createTime: '2021-08-16T14:01:58.125999Z'
package: us-central1-docker.pkg.dev/{{project-id}}/web-app-private-targets/leeroy-app
tags: v1
updateTime: '2021-08-16T14:01:58.125999Z'
version: sha256:71c0def49cbc6f414d9b2723f302654e6791f0db3948cc7bbf430ac0346224f8
---
createTime: '2021-08-16T14:01:55.719359Z'
package: us-central1-docker.pkg.dev/{{project-id}}/web-app-private-targets/leeroy-web
tags: v1
updateTime: '2021-08-16T14:01:55.719359Z'
version: sha256:91161798f2f544cb0a21fc8c6cec3c3f824f46d64de5ce18846f74a9cc730d09
```

By default, `skaffold` sets the tag for an image to its related `git` tag if one is available. In this case, a `v1` tag was set on the repository.

Similar information can be found in the `artifacts.json` file that was created by the `skaffold` command. You'll use that file in an upcoming step. <walkthrough-editor-open-file filePath="web-private-targets/artifacts.json">Click here to review artifacts.json.</walkthrough-editor-open-file>

To create the delivery pipeline, click **Next**.

## Create the delivery pipeline

In this tutorial, you will create a Google Cloud Deploy [_delivery pipeline_](https://console.cloud.google.com/deploy/delivery-pipelines?project={{project-id}}) that progresses a web application through three _targets_: `test`, `staging`, and `prod`. Google Cloud Deploy uses YAML files to define `delivery-pipeline` and `target` resources. For this tutorial, we have pre-created these files in the repository you cloned in Step 2.

<walkthrough-editor-open-file filePath="clouddeploy-config/delivery-pipeline.yaml">Click here to view delivery-pipeline.yaml</walkthrough-editor-open-file>

The following command creates the `delivery-pipeline` resource using the delivery pipeline YAML file:

```bash
gcloud beta deploy apply --file=clouddeploy-config/delivery-pipeline.yaml
```

Verify the delivery pipeline was created:

```bash
gcloud beta deploy delivery-pipelines describe web-app-private-targets
```

Your output should look like the example below.

```terminal
Unable to get target test-private
Unable to get target staging-private
Unable to get target prod-private
Delivery Pipeline:
  createTime: '2021-08-16T14:03:18.294884547Z'
  description: web-app delivery pipeline
  etag: 2539eacd7f5c256d
  name: projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app-private-targets
  serialPipeline:
    stages:
    - targetId: test-private
    - targetId: staging-private
    - targetId: prod-private
  uid: eb0601aa03ac4b088d74c6a5f13f36ae
  updateTime: '2021-08-16T14:03:18.680753520Z'
Targets: []
```

Notice the first three lines of the output. Your delivery pipeline references three target environments that haven't been created yet. In the next sections you'll create those targets.

To create the targets, click **Next**.

## Test target

In Google Cloud Deploy, a _target_ represents a GKE cluster where an application can be deployed as part of a delivery pipeline.

In the tutorial delivery pipeline, the first target is `test`.

You create a `target` by applying a YAML file to Google Cloud Deploy using `gcloud beta deploy apply`.

<walkthrough-editor-open-file filePath="clouddeploy-config/target-test.yaml">Click here to view the file target-test.yaml</walkthrough-editor-open-file>

Create the `test` target:

```bash
gcloud beta deploy apply --file clouddeploy-config/target-test.yaml
```

Verify the `target` was created:

```bash
gcloud beta deploy targets describe test-private --delivery-pipeline=web-app-private-clusters
```

The output should look like the example below. Important information in this output is that the target is recognized as a `gke` `cluster`.

```terminal
Target:
  createTime: '2021-11-26T16:46:34.750867784Z'
  description: test cluster
  etag: 9cfbf9ee2ef2a38b
  executionConfigs:
  - privatePool:
      workerPool: projects/{{project-id}}/locations/us-central1/workerPools/private-pool
    usages:
    - RENDER
    - DEPLOY
  gke:
    cluster: projects/{{project-id}}/locations/us-central1/clusters/test
  name: projects/{{project-id}}/locations/us-central1/targets/test-private
  uid: 8387e458c08648a6a74b3f54e99e543a
  updateTime: '2021-11-26T16:46:34.838965285Z'
```

You can also view [details for your target](https://console.cloud.google.com/deploy/delivery-pipelines/us-central1/web-app-private-targets/targets/test?project={{project-id}}) in the GCP control panel.

To create additional targets, click **Next**.

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

The output should look like this, showing all three created targets, which are used with your `web-app` delivery pipeline.

```terminal
targets:
- createTime: '2021-11-26T16:50:31.969162571Z'
  description: staging cluster
  etag: 35421504f2300713
  executionConfigs:
  - privatePool:
      workerPool: projects/{{project-id}}/locations/us-central1/workerPools/private-pool
    usages:
    - RENDER
    - DEPLOY
  gke:
    cluster: projects/{{project-id}}/locations/us-central1/clusters/staging
  name: projects/{{project-id}}/locations/us-central1/targets/staging-private
  uid: d1902f295f584ee2b9eb867d4d874d44
  updateTime: '2021-11-26T16:50:32.340724144Z'
- createTime: '2021-11-26T16:50:58.855561690Z'
  description: prod cluster
  etag: 63ad42d05b3bbd2d
  executionConfigs:
  - privatePool:
      workerPool: projects/{{project-id}}/locations/us-central1/workerPools/private-pool
    usages:
    - RENDER
    - DEPLOY
  gke:
    cluster: projects/{{project-id}}/locations/us-central1/clusters/prod
  name: projects/{{project-id}}/locations/us-central1/targets/prod-private
  requireApproval: true
  uid: 4abbaace846c49e09a37e762fd2da7fb
  updateTime: '2021-11-26T16:50:58.926184337Z'
- createTime: '2021-11-26T16:46:34.750867784Z'
  description: test cluster
  etag: 9cfbf9ee2ef2a38b
  executionConfigs:
  - privatePool:
      workerPool: projects/{{project-id}}/locations/us-central1/workerPools/private-pool
    usages:
    - RENDER
    - DEPLOY
  gke:
    cluster: projects/{{project-id}}/locations/us-central1/clusters/test
  name: projects/{{project-id}}/locations/us-central1/targets/test-private
  uid: 8387e458c08648a6a74b3f54e99e543a
  updateTime: '2021-11-26T16:46:34.838965285Z'
```

All Google Cloud Deploy targets for the delivery pipeline have now been created.

You can also see the [details for your delivery pipeline](https://console.cloud.google.com/deploy/delivery-pipelines/us-central1/web-app-private-targets?project={{project-id}}) in the GCP control panel.

To create a release, click **Next**.

## Create a release

A Google Cloud Deploy `release` is a specific version of one or more container images associated with a specific delivery pipeline. Once a release is created, it can be promoted through multiple targets (the _promotion sequence_). Additionally, creating a release renders your application using `skaffold` and saves the output as a point-in-time reference that's used for the duration of that release.

Because this is the first release of your application, name it `web-app-001`.

Run the following command to create the release. The `--build-artifacts` parameter references the `artifacts.json` file created by `skaffold` earlier. The `--source` parameter references the application source directory where `skaffold.yaml` can be found.

```bash
gcloud beta deploy releases create web-app-001 --delivery-pipeline web-app-private-targets --build-artifacts web-private-targets/artifacts.json --source web-private-targets/
```

The command above references the delivery pipeline and the container images you created earlier in this tutorial.

To confirm your release has been created, run the following command:

```bash
gcloud beta deploy releases list --delivery-pipeline web-app-private-targets
```

Your output should look similar to the example below. Important things to note are that the release has been successfully rendered according to the `renderingState` value, as well as the location of the `skaffold` configuration noted by the `skaffoldConfigUri` parameter.

```terminal
---
buildArtifacts:
- image: leeroy-app
  tag: us-central1-docker.pkg.dev/{{project-id}}/web-app-private-targets/leeroy-app:v1@sha256:a6e15150c1b7edfcd165c32611b211c181d55a58460bebf89bc41e9319be0639
- image: leeroy-web
  tag: us-central1-docker.pkg.dev/{{project-id}}/web-app-private-targets/leeroy-web:v1@sha256:888bd80787394f631dcf761d5647d627f8d5db45cfd5a87b7e5393930df94728
createTime: '2021-11-26T18:04:48.390179Z'
deliveryPipelineSnapshot:
  createTime: '2021-11-26T18:04:37.173769Z'
  description: web-app delivery pipeline
  etag: 688155effd0069f8
  name: projects/205061390868/locations/us-central1/deliveryPipelines/web-app-private-targets
  serialPipeline:
    stages:
    - targetId: test-private
    - targetId: staging-private
    - targetId: prod-private
  uid: 3548c8fff192403981cb8daf63e0355f
  updateTime: '2021-11-26T18:04:37.173769Z'
etag: a2a4d9e8582e8b7a
name: projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app-private-targets/releases/web-app-001
renderEndTime: '2021-11-26T18:06:28.609514Z'
renderStartTime: '2021-11-26T18:05:58.895146176Z'
renderState: SUCCEEDED
skaffoldConfigUri: gs://{{project-id}}_clouddeploy/source/1637949886.006278-fec7b194fa2b4ddfa06176fb12c7c559.tgz
skaffoldVersion: 1.24.0
targetArtifacts:
  prod-private:
    artifactUri: gs://us-central1.deploy-artifacts.{{project-id}}.appspot.com/web-app-001-dfe89ce365ea4f849df439cb55a8c1f4/prod-private
    manifestPath: manifest.yaml
    skaffoldConfigPath: skaffold.yaml
  staging-private:
    artifactUri: gs://us-central1.deploy-artifacts.{{project-id}}.appspot.com/web-app-001-dfe89ce365ea4f849df439cb55a8c1f4/staging-private
    manifestPath: manifest.yaml
    skaffoldConfigPath: skaffold.yaml
  test-private:
    artifactUri: gs://us-central1.deploy-artifacts.{{project-id}}.appspot.com/web-app-001-dfe89ce365ea4f849df439cb55a8c1f4/test-private
    manifestPath: manifest.yaml
    skaffoldConfigPath: skaffold.yaml
targetRenders:
  prod-private:
    renderingBuild: projects/205061390868/locations/us-central1/builds/49233e75-d8f9-4e53-9f1e-a329cc71aa7d
    renderingState: SUCCEEDED
  staging-private:
    renderingBuild: projects/205061390868/locations/us-central1/builds/4663d672-2874-4811-9122-836613c4a62b
    renderingState: SUCCEEDED
  test-private:
    renderingBuild: projects/205061390868/locations/us-central1/builds/b10e5d5c-1b35-4c7e-bbfb-b95c8200ef86
    renderingState: SUCCEEDED
targetSnapshots:
- createTime: '2021-11-26T16:46:34.827664Z'
  description: test cluster
  etag: dff82badd8ecaea0
  executionConfigs:
  - privatePool:
      serviceAccount: tf-sa-clouddeploy@{{project-id}}.iam.gserviceaccount.com
      workerPool: projects/{{project-id}}/locations/us-central1/workerPools/private-pool
    usages:
    - RENDER
    - DEPLOY
  gke:
    cluster: projects/{{project-id}}/locations/us-central1/clusters/test
  name: projects/205061390868/locations/us-central1/targets/test-private
  uid: 8387e458c08648a6a74b3f54e99e543a
  updateTime: '2021-11-26T17:54:39.819010Z'
- createTime: '2021-11-26T16:50:32.227780Z'
  description: staging cluster
  etag: cd287b8bd53054df
  executionConfigs:
  - privatePool:
      serviceAccount: tf-sa-clouddeploy@{{project-id}}.iam.gserviceaccount.com
      workerPool: projects/{{project-id}}/locations/us-central1/workerPools/private-pool
    usages:
    - RENDER
    - DEPLOY
  gke:
    cluster: projects/{{project-id}}/locations/us-central1/clusters/staging
  name: projects/205061390868/locations/us-central1/targets/staging-private
  uid: d1902f295f584ee2b9eb867d4d874d44
  updateTime: '2021-11-26T17:54:54.865241Z'
- createTime: '2021-11-26T16:50:58.916816Z'
  description: prod cluster
  etag: e46b82b6d3d445f0
  executionConfigs:
  - privatePool:
      serviceAccount: tf-sa-clouddeploy@{{project-id}}.iam.gserviceaccount.com
      workerPool: projects/{{project-id}}/locations/us-central1/workerPools/private-pool
    usages:
    - RENDER
    - DEPLOY
  gke:
    cluster: projects/{{project-id}}/locations/us-central1/clusters/prod
  name: projects/205061390868/locations/us-central1/targets/prod-private
  requireApproval: true
  uid: 4abbaace846c49e09a37e762fd2da7fb
  updateTime: '2021-11-26T17:55:04.644163Z'
uid: 37d76352d5644ff199e23e16a91f1ebc
```

You can also view [release details](https://console.cloud.google.com/deploy/delivery-pipelines/us-central1/web-app-private-targets/releases/web-app-001?project={{project-id}}) in the GCP control panel.

When a release is created, it will also be automatically rolled out to the first target in the pipeline (unless approval is required, which will be covered in a later step of this tutorial).

You can read more about this in the [Google Cloud Deploy delivery process](https://cloud.google.com/deploy/docs/overview#the_delivery_process) section of the documentation.

To promote your application, Click **Next**.

## Promoting the application

With your release created, you can promote your application. When the release was created in the previous step, it automatically rolled out your application to the initial target. To confirm your `test` target has your application deployed, run the following command:

```bash
gcloud beta deploy rollouts list --delivery-pipeline web-app-private-targets --release web-app-001
```

Your output should look similar to the example below. The start and end times for the deploy are noted, as well that it succeeded.

```terminal
---
approvalState: DOES_NOT_NEED_APPROVAL
createTime: '2021-11-26T18:04:57.282245Z'
deployEndTime: '2021-11-26T18:08:10.639076Z'
deployStartTime: '2021-11-26T18:07:55.240234050Z'
deployingBuild: projects/205061390868/locations/us-central1/builds/54c4e521-b3d6-447a-ad96-7d02161af989
enqueueTime: '2021-11-26T18:06:49.103895Z'
etag: d5244a2e73833ff1
name: projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app-private-targets/releases/web-app-001/rollouts/web-app-001-to-test-private-0001
state: SUCCEEDED
targetId: test-private
uid: 07d1fff4358a4494ad3b5436a1ce20bd
```

Note that the first rollout of a release will take several minutes, because Google Cloud Deploy renders the manifests for all targets when the release is created. If you do not see _state: SUCCEEDED_ in the output from the previous command, please wait and periodically re-run the command until the rollout completes.

To confirm your application was deployed to your test GKE cluster, run the following commands in your Cloud Shell:

**TODO**

To promote your application to your staging target, run the following command. The optional `--to-target` parameter can specify a target to promote to. If this option isn't included, the release is promoted to the next target in the delivery pipeline.

```bash
gcloud beta deploy releases promote --delivery-pipeline web-app-private-targets --release web-app-001
```

To confirm your application has been promoted to the `staging` target, run the following command:

```bash
gcloud beta deploy rollouts list --delivery-pipeline web-app-private-targets --release web-app-001
```

Your output should contain a section similar to this:

```terminal
---
approvalState: DOES_NOT_NEED_APPROVAL
createTime: '2021-11-26T18:13:17.655081Z'
deployEndTime: '2021-11-26T18:14:40.769075Z'
deployStartTime: '2021-11-26T18:14:23.895824478Z'
deployingBuild: projects/205061390868/locations/us-central1/builds/a970fa50-b0f8-4eda-841f-5861687edd74
etag: 46d9bd5c872cbb82
name: projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app-private-targets/releases/web-app-001/rollouts/web-app-001-to-staging-private-0001
state: SUCCEEDED
targetId: staging-private
uid: 72688b8aafd1433d894392ffd19e9e20
```
The rollout may take several minutes. If you do not see _state: SUCCEEDED_ in the output from the previous command, please wait and periodically re-run the command until the rollout completes.

To confirm your application was deployed to your staging GKE cluster, run the following commands in your Cloud Shell:

**TODO**

In the next section, you'll look at targets that require approvals before promotions can complete.

To learn more about approvals, click **Next**.

## Approvals

Any target can require an approval before a release promotion can occur. This is designed to protect production and sensitive targets from accidentally promoting a release before it's been fully vetted and tested.

### Requiring approval for promotion to a target

When you created your prod environment, the configuration was in place to require approvals to this target. To verify this, run this command and look for the `requireApproval` parameter.

```bash
gcloud beta deploy targets describe prod-private --delivery-pipeline web-app-private-targets
```

Your output should look similar to the example below. Unlike the previous targets, the prod target does require approval per the `requireApproval` parameter.

```terminal
Target:
  createTime: '2021-11-26T16:50:58.855561690Z'
  description: prod cluster
  etag: e46b82b6d3d445f0
  executionConfigs:
  - privatePool:
      serviceAccount: tf-sa-clouddeploy@{{project-id}}.iam.gserviceaccount.com
      workerPool: projects/{{project-id}}/locations/us-central1/workerPools/private-pool
    usages:
    - RENDER
    - DEPLOY
  gke:
    cluster: projects/{{project-id}}/locations/us-central1/clusters/prod
  name: projects/{{project-id}}/locations/us-central1/targets/prod-private
  requireApproval: true
  uid: 4abbaace846c49e09a37e762fd2da7fb
  updateTime: '2021-11-26T17:55:04.655389661Z'
```

Run the following command to promote your application to your prod target:

```bash
gcloud beta deploy releases promote --delivery-pipeline web-app-private-targets --release web-app-001
```

When you look at your rollouts for `web-app-001`, you'll notice that the promotion to prod has a `PENDING_APPROVAL` status. Run the following command:

```bash
gcloud beta deploy rollouts list --delivery-pipeline web-app-private-targets --release web-app-001
```

In the output, note that the `approvalState` is `NEEDS_APPROVAL` and the state is `PENDING_APPROVAL`.

```terminal
---
approvalState: NEEDS_APPROVAL
createTime: '2021-11-26T18:19:23.548047Z'
etag: 4bcbcebbd8d9afbd
name: projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app-private-targets/releases/web-app-001/rollouts/web-app-001-to-prod-private-0001
state: PENDING_APPROVAL
targetId: prod-private
uid: 14209433d7b34fc68ab4f6b9d9d20889
```
Next, you'll approve this promotion to your prod target and make your production push.

To approve and deploy to production, click **Next**.

## Deploying to prod

To approve your application and promote it to your prod target, use this command:

```bash
gcloud beta deploy rollouts approve web-app-001-to-prod-private-0001 --delivery-pipeline web-app-private-targets --release web-app-001
```

After a short time, your promotion should complete. To verify this, run the following command:

```bash
gcloud beta deploy rollouts list --delivery-pipeline web-app-private-targets --release web-app-001
```

Your output should look similar to the following:

```terminal
---
approvalState: APPROVED
approveTime: '2021-11-26T18:22:13.584006Z'
createTime: '2021-11-26T18:19:23.548047Z'
deployEndTime: '2021-11-26T18:23:57.827408Z'
deployStartTime: '2021-11-26T18:23:40.274983913Z'
deployingBuild: projects/205061390868/locations/us-central1/builds/92f98724-ccd0-44f4-88b8-eef67d628734
enqueueTime: '2021-11-26T18:22:13.584006Z'
etag: 39f37628515b004e
name: projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app-private-targets/releases/web-app-001/rollouts/web-app-001-to-prod-private-0001
state: SUCCEEDED
targetId: prod-private
uid: 14209433d7b34fc68ab4f6b9d9d20889
---
approvalState: DOES_NOT_NEED_APPROVAL
createTime: '2021-11-26T18:13:17.655081Z'
deployEndTime: '2021-11-26T18:14:40.769075Z'
deployStartTime: '2021-11-26T18:14:23.895824478Z'
deployingBuild: projects/205061390868/locations/us-central1/builds/a970fa50-b0f8-4eda-841f-5861687edd74
etag: 46d9bd5c872cbb82
name: projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app-private-targets/releases/web-app-001/rollouts/web-app-001-to-staging-private-0001
state: SUCCEEDED
targetId: staging-private
uid: 72688b8aafd1433d894392ffd19e9e20
---
approvalState: DOES_NOT_NEED_APPROVAL
createTime: '2021-11-26T18:04:57.282245Z'
deployEndTime: '2021-11-26T18:08:10.639076Z'
deployStartTime: '2021-11-26T18:07:55.240234050Z'
deployingBuild: projects/205061390868/locations/us-central1/builds/54c4e521-b3d6-447a-ad96-7d02161af989
enqueueTime: '2021-11-26T18:06:49.103895Z'
etag: d5244a2e73833ff1
name: projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app-private-targets/releases/web-app-001/rollouts/web-app-001-to-test-private-0001
state: SUCCEEDED
targetId: test-private
uid: 07d1fff4358a4494ad3b5436a1ce20bd
```

The rollout may take several minutes. If you do not see `state: SUCCEEDED` in the output from the previous command, please wait and periodically re-run the command until the rollout completes.

**TODO**

### 🎉 Success

Your Google Cloud Deploy workflow approval worked, and your application is now deployed to your prod GKE cluster. In the next section you'll clean up the resources you've created for this tutorial.

To learn about next steps, click **Next**.

## Next steps

### Delete the pipeline

To delete the Cloud Deploy pipeline used in this tutorial, run the following command:

```bash
gcloud beta deploy delivery-pipelines delete web-app-private-targets --force --quiet
```

### Delete the targets

To delete the Cloud Deploy targets, run the following commands:

```bash
gcloud beta deploy targets delete test-private
gcloud beta deploy targets delete staging-private
gcloud beta deploy targets delete prod-private
```

### Delete the target infrastructure and other resources

To clean up your GKE clusters and other resources, run the provided cleanup script.

```bash
./cleanup.sh
```

This script removes the Google Cloud resources and the artifacts in your Cloud Shell instance. The script takes around 10 minutes to complete.

### Clean up gcloud configurations

When you ran `bootstrap.sh`, a line was added to your Cloud Shell configuration. For users of the `bash` shell, a line was added to `.bashrc` to reference `$HOME/.gcloud` as the directory `gcloud` uses to keep configurations. For people who have customized their Cloud Shell environments to use other shells, the corresponding `rc` was similarly edited.

In the `.gcloud` directory a configuration named `clouddeploy` was also created. This features allows `gcloud` configurations to [persist across Cloud Shell sessions and restarts](https://cloud.google.com/shell/docs/configuring-cloud-shell#gcloud_command-line_tool_preferences).

If you want to remove this configuration, remove the line from your `rc` file and delete the `$HOME/.gcloud` directory.

Click **Next** to complete this tutorial.

## Conclusion

Thank you for taking the time to get to know the Google Cloud Deploy Preview from Google Cloud!

<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>

<walkthrough-inline-feedback></walkthrough-inline-feedback>

You can find additional tutorials for Google Cloud Deploy in [Tutorials](https://cloud.google.com/deploy/docs/tutorials).
