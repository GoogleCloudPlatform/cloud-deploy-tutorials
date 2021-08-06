<walkthrough-author
    tutorialname="Cloud Deploy Tutorial - Profiles"
    repositoryUrl="https://clouddeploy.googlesource.com/tutorial"
    >
</walkthrough-author>

# Cloud Deploy: Public Preview

![Cloud Deploy logo](https://walkthroughs.googleusercontent.com/content/cloud_deploy_e2e_gke/images/cloud-deploy-logo-centered.png "Cloud Deploy logo")

## Overview
This tutorial guides you through using Skaffold Profiles with the Google [Cloud Deploy](https://console.cloud.google.com/deploy) service.

Following on from the Cloud Deploy End-to-end tutorial, you will use a **test > staging > production** delivery pipeline to deploy an application that is customized for each target.

Please note that completion of the Cloud Deploy End-to-end tutorial is a prerequisite for this tutorial. If you have not done so, please complete this first, then resume here.

## About Profiles
A common pattern for building and progressing an application safely and reliably to production is to build the artifact only once, and to use data stored separately to configure the application.

Typically there is a requirement for an application's configuration to vary depending on the environment (***test, staging, production***, and so on) to which it is deployed.

Examples of these requirements include:

* Service discovery details, DNS names, or IP addresses for dependencies, such as other services or databases used by the application
* Resource usage requests and limits, such as CPU and RAM
* Scaling information, such as the minimum and maximum number of application instances that should run

To facilitate this pattern, Cloud Deploy integrates with [`Skaffold`](https://skaffold.dev/), a leading open-source continuous-development toolset, which includes features to enable these kinds of deploy-time configuration.

Skaffold, in turn, supports the use of multiple underlying tools that enable application manifest templatization and overlays.

This tutorial uses [Kustomize](https://kustomize.io/), but [Helm](https://helm.sh/) is another example of a tool that is commonly used to templatize and/or manage Kubernetes manifests.

You can read more about these tools via the following links:

* [Skaffold Profiles](https://skaffold.dev/docs/environment/profiles/)
* [Using Kustomize](https://github.com/kubernetes-sigs/kustomize/blob/master/README.md)
* [Using Kustomize with Skaffold](https://skaffold.dev/docs/pipeline-stages/deployers/kustomize/)

These capabilities are built in to Cloud Deploy, which means that you can concentrate on your application configuration.

### About Cloud Shell
This tutorial uses [Google Cloud Shell](https://cloud.google.com/shell) to configure and interact with Cloud Deploy. Cloud Shell is an online development and operations environment, accessible anywhere with your browser.

You can manage your resources with its online terminal, preloaded with utilities such as the `gcloud`, `kubectl`, and more. You can also develop, build, debug, and deploy your cloud-based apps using the online [Cloud Shell Editor](https://ide.cloud.google.com/).

Estimated Duration:
<walkthrough-tutorial-duration duration="45"></walkthrough-tutorial-duration>

Click **Next** to proceed.

## Project setup
GCP organizes resources into projects. This allows you to collect all of the related resources for a single application in one place.

Begin by selecting an existing project for this tutorial.

***This project must be the project you used for the Cloud Deploy End-to-end tutorial, because infrastructure and Cloud Deploy Targets are reused.***

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

## Review the Application

As part of this tutorial, a sample application from the [Skaffold Github repository](https://github.com/GoogleContainerTools/skaffold.git) is available from your Cloud Shell instance, in the `web-profiles` directory. This is similar to the application used in the Cloud Deploy End-to-end tutorial, with some modifications that are specific to this tutorial.

### Application Configuration

The example application source code is in the `web-profiles` directory of your Cloud Shell instance. It's a simple web app that signs on with a log entry, listens on a port, and provides an HTTP response to each incoming request.

Run the following command to show the structure of the application and its configuration:

```bash
tree web-profiles
```

You should see output similar to the following:

```terminal
web-profiles
├── artifacts.json
├── leeroy-app-profiles
│   ├── Dockerfile
│   ├── app.go
│   └── kubernetes
│       ├── base
│       │   ├── deployment.yaml
│       │   └── kustomization.yaml
│       ├── prod
│       │   ├── kustomization.yaml
│       │   └── target.yaml
│       ├── staging
│       │   ├── kustomization.yaml
│       │   └── target.yaml
│       └── test
│           ├── kustomization.yaml
│           └── target.yaml
├── leeroy-web-profiles
│   ├── Dockerfile
│   ├── kubernetes
│   │   └── deployment.yaml
│   └── web.go
└── skaffold.yaml
```
Notice:

* The `base` directory, which contains Kubernetes configuration common to all targets for the `leeroy-app-profiles` application
* The `prod`, `staging` and `test` directories, which contain configuration that specific to each target

The `web-profiles` directory contains `skaffold.yaml`, which contains directives for `Skaffold` to build and deploy container images for your application. This configuration uses the [Cloud Build](https://cloud.google.com/build) service to build the container images.

<walkthrough-editor-open-file filePath="web-profiles/skaffold.yaml">Click here to review skaffold.yaml.</walkthrough-editor-open-file>

Notice the `profiles` section of this file, which associates a named profile for each target (***test, staging, prod***) with a specific `kustomize` configuration. Each profile refers to the configuration directory that corresponds to each Cloud Deploy Target.

Click **Next** to proceed.

## Application Code

The application provides a simple web service that returns a message that identifies the target to which it has been deployed, as well as logging this information at startup.

<walkthrough-editor-open-file filePath="web-profiles/leeroy-app-profiles/app.go">Click here to review app.go.</walkthrough-editor-open-file>

Note the calls to `os.Getenv` to retrieve and output the `TARGET` environment variable, which is dynamically supplied in the application manifest when the application is deployed.

Click **Next** to proceed.

## Build the Application

In this section, you'll build the application so you can progress it through the `webapp-profiles` delivery pipeline.

To create these container images, run the following command:

```bash
cd web-profiles && skaffold build --interactive=false --default-repo $(gcloud config get-value compute/region)-docker.pkg.dev/$(gcloud config get-value project)/web-app-profiles --file-output artifacts.json && cd ..
```

In the next step you will confirm the container images built by `Skaffold` were uploaded to the container image registry properly.

### Custom container images

When you ran `bootstrap.sh` a repository in [Google Cloud Artifact Registry](https://cloud.google.com/artifact-registry) was created to serve the images. The previous command referenced the repository with the `--default-repo` parameter. To confirm the images were successfully pushed to Artifact Registry, run the following command:

```bash
gcloud artifacts docker images list $(gcloud config get-value compute/region)-docker.pkg.dev/$(gcloud config get-value project)/web-app-profiles --include-tags --format yaml
```
The `--format yaml` parameter returns the output as YAML for readability. The output should look like this:

```terminal
Listing items under project {{project-id}}, location us-central1, repository web-app-profiles.
---
createTime: '2021-08-06T10:23:19.838015Z'
package: us-central1-docker.pkg.dev/{{project-id}}/web-app-profiles/leeroy-app-profiles
tags: v1
updateTime: '2021-08-06T10:23:19.838015Z'
version: sha256:014f32588ff27d4418cc2ed63ceca96b48e53ec9c76b52f57fa5463b36e7ac78
---
createTime: '2021-08-06T10:23:20.236063Z'
package: us-central1-docker.pkg.dev/{{project-id}}/web-app-profiles/leeroy-web-profiles
tags: v1
updateTime: '2021-08-06T10:23:20.236063Z'
version: sha256:e9e97c1b488efa6a6910dce8aa8318f677daae543972efbcf2f3c52a9b15a54f
```

By default, `skaffold` sets the tag for an image to its related `git` tag if one is available. In this case, a `v1` tag was set on the repository.

Similar information can be found in the `artifacts.json` file that was created by the `skaffold` command. You'll use that file in an upcoming step.

<walkthrough-editor-open-file filePath="web-profiles/artifacts.json">Click here to review artifacts.json.</walkthrough-editor-open-file>

Click **Next** to proceed.

## Create the delivery pipeline

In this tutorial, you will create a Cloud Deploy [_delivery pipeline_](https://console.cloud.google.com/deploy/delivery-pipelines?project={{project-id}}) that progresses a web application through three _targets_: `test`, `staging`, and `prod`. Cloud Deploy uses YAML files to define `delivery-pipeline` and `target` resources. For this tutorial, we have pre-created these files in the repository you cloned in Step 2.

<walkthrough-editor-open-file filePath="clouddeploy-config/delivery-pipeline-profiles.yaml">Click here to view delivery-pipeline-profiles.yaml</walkthrough-editor-open-file>

Note that this file associates each target in the pipeline with a profile of the same name. These names need not map directly, but in this case are made to match for clarity.

The following command creates the `delivery-pipeline-profiles` resource using the delivery pipeline YAML file:

```bash
gcloud alpha deploy apply --file=clouddeploy-config/delivery-pipeline-profiles.yaml
```

Verify the delivery pipeline was created:

```bash
gcloud alpha deploy delivery-pipelines describe web-app-profiles
```

Your output should look like the example below. Notice that the targets are reused from the Cloud Deploy End-to-end tutorial, but this Pipeline has a `profile` associated with each `targetID`:

```terminal
Delivery Pipeline:
  createTime: '2021-08-06T10:26:26.535630776Z'
  description: web-app delivery pipeline with Skaffold profiles
  etag: c1bb971f4a5c558a
  name: projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app-profiles
  serialPipeline:
    stages:
    - profiles:
      - test
      targetId: test
    - profiles:
      - staging
      targetId: staging
    - profiles:
      - prod
      targetId: prod
  uid: 3fd543c2d8174d868240660103374fda
  updateTime: '2021-08-06T10:26:26.646493691Z'
Targets:
- Target: test
- Target: staging
- Target: prod
```

You can also see the [details for your delivery pipeline](https://console.cloud.google.com/deploy/delivery-pipelines/us-central1/web-app-profiles?project={{project-id}}) in the GCP control panel.

Click **Next** to proceed.

## Create a Release

A Cloud Deploy `release` is a specific version of one or more container images associated with a specific delivery pipeline. Once a release is created, it can be promoted through multiple targets (the _promotion sequence_). Additionally, creating a release renders your application using `Skaffold` and saves the output as a point-in-time reference that's used for the duration of that release.

Because this is the first release of your application, name it `web-app-profiles-001`.

Run the following command to create the release. The `--build-artifacts` parameter references the `artifacts.json` file created by `skaffold` earlier. The `--source` parameter references the application source directory where `skaffold.yaml` can be found.

```bash
gcloud alpha deploy releases create web-app-profiles-001 --delivery-pipeline web-app-profiles --build-artifacts web-profiles/artifacts.json --source web-profiles/
```

The command above references the delivery pipeline and the container images you created earlier in this tutorial.

To confirm your release has been created run the following command:

```bash
gcloud alpha deploy releases list --delivery-pipeline web-app-profiles
```

Your output should look similar to the example below. Important things to note are that the release has been successfully rendered according to the `renderState` value, as well as the location of the `skaffold` configuration noted by the `skaffoldConfigUri` parameter.

```terminal
---
buildArtifacts:
- image: leeroy-app-profiles
  tag: us-central1-docker.pkg.dev/{{project-id}}/web-app-profiles/leeroy-app-profiles:v1-5-g83011bc@sha256:014f32588ff27d4418cc2ed63ceca96b48e53ec9c76b52f57fa5463b36e7ac78
- image: leeroy-web-profiles
  tag: us-central1-docker.pkg.dev/{{project-id}}/web-app-profiles/leeroy-web-profiles:v1-5-g83011bc@sha256:e9e97c1b488efa6a6910dce8aa8318f677daae543972efbcf2f3c52a9b15a54f
createTime: '2021-08-06T10:30:13.197733Z'
deliveryPipelineSnapshot:
  createTime: '2021-08-06T10:26:26.619816Z'
  description: web-app delivery pipeline with Skaffold profiles
  etag: c1bb971f4a5c558a
  name: projects/243106549432/locations/us-central1/deliveryPipelines/web-app-profiles
  serialPipeline:
    stages:
    - profiles:
      - test
      targetId: test
    - profiles:
      - staging
      targetId: staging
    - profiles:
      - prod
      targetId: prod
  uid: 3fd543c2d8174d868240660103374fda
  updateTime: '2021-08-06T10:26:26.619816Z'
etag: b435e6ac67132e33
name: projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app-profiles/releases/web-app-profiles-001
renderEndTime: '2021-08-06T10:31:04.647304Z'
renderStartTime: '2021-08-06T10:30:13.961549226Z'
renderState: SUCCESS
renderingBuild: projects/243106549432/locations/us-central1/builds/0b05f583-4c8f-408a-8ad8-1b689dbe358a
skaffoldConfigUri: gs://{{project-id}}_clouddeploy/source/1628245811.169313-6ed66c0a6bf741308c30e83b86168c50.tgz
skaffoldVersion: 1.24.0
targetArtifacts:
  prod:
    archiveUri: gs://us-central1.deploy-artifacts.{{project-id}}.appspot.com/web-app-profiles-001-6d720dd1985d4503befdc102893e85e3/prod.tar.gz
    manifestPath: manifest.yaml
    skaffoldConfigPath: skaffold.yaml
  staging:
    archiveUri: gs://us-central1.deploy-artifacts.{{project-id}}.appspot.com/web-app-profiles-001-6d720dd1985d4503befdc102893e85e3/staging.tar.gz
    manifestPath: manifest.yaml
    skaffoldConfigPath: skaffold.yaml
  test:
    archiveUri: gs://us-central1.deploy-artifacts.{{project-id}}.appspot.com/web-app-profiles-001-6d720dd1985d4503befdc102893e85e3/test.tar.gz
    manifestPath: manifest.yaml
    skaffoldConfigPath: skaffold.yaml
targetSnapshots:
- createTime: '2021-08-06T09:28:29.322569Z'
  description: test cluster
  etag: a7ce6c8bf6e97d7b
  gkeCluster:
    cluster: test
    location: us-central1
    project: {{project-id}}
  name: projects/243106549432/locations/us-central1/targets/test
  uid: 7e415505c0584a248af10fed2e806e21
  updateTime: '2021-08-06T09:28:29.322569Z'
- createTime: '2021-08-06T09:57:10.602755Z'
  description: staging cluster
  etag: 28c2b2833b3492e3
  gkeCluster:
    cluster: staging
    location: us-central1
    project: {{project-id}}
  name: projects/243106549432/locations/us-central1/targets/staging
  uid: 4668da68e8574e1488eaf17e7d04ce3a
  updateTime: '2021-08-06T09:57:10.602755Z'
- createTime: '2021-08-06T09:57:20.053816Z'
  description: prod cluster
  etag: 63b7d7eef1d91401
  gkeCluster:
    cluster: prod
    location: us-central1
    project: {{project-id}}
  name: projects/243106549432/locations/us-central1/targets/prod
  requireApproval: true
  uid: fc826c8a8ad240af892e745024fc9e60
  updateTime: '2021-08-06T09:57:20.053816Z'
uid: 005a6e67629d43f380a147d2838911e1

```

You can also view [Release details](https://console.cloud.google.com/deploy/delivery-pipelines/us-central1/web-app-profiles/releases/web-app-profiles-001?project={{project-id}}) in the GCP control panel.

Click **Next** to proceed.

## Confirming Rollout

When the Release was created in the previous step, it automatically rolled out your application to the initial Target. To confirm your `test` Target has your application deployed, run the following command:

```bash
gcloud alpha deploy rollouts list --delivery-pipeline web-app-profiles --release web-app-profiles-001
```

Your output should look similar to the example below. The start and end times for the deploy are noted, as well that it succeeded.

```terminal
---
approvalState: DOES_NOT_NEED_APPROVAL
createTime: '2021-08-06T10:30:18.002901Z'
deployEndTime: '2021-08-06T10:31:26.837528Z'
deployStartTime: '2021-08-06T10:31:14.483531118Z'
deployingBuild: projects/243106549432/locations/us-central1/builds/c6b5de5d-c5eb-4ab7-ae80-0fd382d1c55c
enqueueTime: '2021-08-06T10:31:13.947897Z'
etag: ccae280ea72c95e1
name: projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app-profiles/releases/web-app-profiles-001/rollouts/web-app-profiles-001-to-test-0001
state: SUCCESS
targetId: test
uid: 627c468869f3471880dec4f80ff60c79
```

Note that the first rollout of a Release will take several minutes, because Cloud Deploy renders the manifests for all Targets when the Release is created. If you do not see _state: SUCCESS_ in the output from the previous command, please wait and periodically re-run the command until the rollout completes.

To confirm your application was deployed to your test GKE cluster, run the following commands in your Cloud Shell:

```bash
kubectx test && kubectl get pods -n web-app-profiles
```

The output of your `kubectl` command should look similar to the following:

```terminal
NAME                                   READY   STATUS    RESTARTS   AGE
leeroy-app-profiles-7b8d48f794-svl6g   1/1     Running   0          19s
leeroy-web-profiles-5498c5b7fd-czvm8   1/1     Running   0          20s
```

Recall from earlier in this tutorial that the Cloud Deploy configuration was structured to contain configuration specific to each Target.

<walkthrough-editor-open-file filePath="web-profiles/leeroy-app-profiles/kubernetes/test/target.yaml">Click here to review target.yaml for the `test` Target.</walkthrough-editor-open-file>

Notice at the bottom of the file that this overlay includes setting the value of the `TARGET` environment variable to `test`.

To confirm that your application configuration has been specialized for the `test` Target, run the following commands in your Cloud Shell:

```bash
kubectx test && kubectl logs -l app=leeroy-app-profiles -n web-app-profiles
```

The output of your `kubectl` command should look similar to the following:

```terminal
Switched to context "test".
2021/08/06 10:31:28 leeroy app server ready, runnning in target: test
```

Click **Next** to proceed.

## Promoting Applications

To promote your application to your staging Target, run the following command. The optional `--to-target` parameter can specify a Target to promote to. If this option isn't included, the Release is promoted to the next Target in the Delivery Pipeline.

```bash
gcloud alpha deploy releases promote --delivery-pipeline web-app-profiles --release web-app-profiles-001
```

To confirm your application has been promoted to the `staging` Target, run the following command:

```bash
gcloud alpha deploy rollouts list --delivery-pipeline web-app-profiles --release web-app-profiles-001
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
name: projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app-profiles/releases/web-app-profiles-001/rollouts/web-app-profiles-001-to-staging-0001
state: SUCCESS
target: staging
uid: f37126ebe3764108beb081c7e2930d7a
```
The rollout may take several minutes. If you do not see _state: SUCCESS_ in the output from the previous command, please wait and periodically re-run the command until the rollout completes.

To confirm your application was deployed to your staging GKE cluster, run the following commands in your Cloud Shell:

```bash
kubectx staging && kubectl get pods -n web-app-profiles
```

The output of your `kubectl` command should look similar to the following:

```terminal
NAME                                   READY   STATUS    RESTARTS   AGE
leeroy-app-profiles-7b8d48f794-hb4lh   1/1     Running   0          19s
leeroy-app-profiles-7b8d48f794-svl6g   1/1     Running   0          19s
leeroy-web-profiles-5498c5b7fd-czvm8   1/1     Running   0          20s
```

Notice that in the `staging` environment, two instances of the `leeroy-app-profiles` pod should be running.

<walkthrough-editor-open-file filePath="web-profiles/leeroy-app-profiles/kubernetes/staging/target.yaml">Click here to review target.yaml for the `staging` Target.</walkthrough-editor-open-file>

Notice at the bottom of the file that this overlay includes setting the value of the `TARGET` environment variable to `staging`, as well as setting the number of replicas of the app to 2.

To confirm that your application configuration has been specialized for the `staging` Target, run the following commands in your Cloud Shell:

```bash
kubectx staging && kubectl logs -l app=leeroy-app-profiles -n web-app-profiles
```

The output of your `kubectl` command should look similar to the following:

```terminal
Switched to context "staging".
2021/08/06 10:35:08 leeroy app server ready, runnning in target: staging
2021/08/06 10:35:09 leeroy app server ready, runnning in target: staging
```

Click **Next** to proceed.

## Approvals

When you created your Cloud Deploy Pipeline, the configuration was in place to require approvals to this Target. To verify this, run this command and look for the `requireApproval` parameter.

```bash
gcloud alpha deploy targets describe prod --delivery-pipeline web-app-profiles
```

Your output should look similar to the example below. Unlike the previous targets, the prod Target does require approval per the `requireApproval` parameter.

```terminal
Target:
  createTime: '2021-08-06T09:57:19.947350447Z'
  description: prod cluster
  etag: 63b7d7eef1d91401
  gkeCluster:
    cluster: prod
    location: us-central1
    project: {{project-id}}
  name: projects/{{project-id}}/locations/us-central1/targets/prod
  requireApproval: true
  uid: fc826c8a8ad240af892e745024fc9e60
  updateTime: '2021-08-06T09:57:20.081243182Z'
```

Go ahead and promote your application to your prod Target with this command:

```bash
gcloud alpha deploy releases promote --delivery-pipeline web-app-profiles --release web-app-profiles-001
```

When you look at your rollouts for `web-app-profiles-001`, you'll notice that the promotion to prod has a `PENDING_APPROVAL` status.

```bash
gcloud alpha deploy rollouts list --delivery-pipeline web-app-profiles --release web-app-profiles-001
```

In the output, note that the `approvalState` is `NEEDS_APPROVAL` and the state is `PENDING_APPROVAL`.

```terminal
---
approvalState: NEEDS_APPROVAL
createTime: '2021-08-06T10:40:01.770182Z'
etag: 6e9303e5a1b04084
name: projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app-profiles/releases/web-app-profiles-001/rollouts/web-app-profiles-001-to-prod-0001
state: PENDING_APPROVAL
targetId: prod
uid: fd681c5fa9484659a34d9fb582475364
---
```

Click **Next** to proceed.

## Deploying to Prod

To approve your application and promote it to your prod Target, use this command:

```bash
gcloud alpha deploy rollouts approve web-app-profiles-001-to-prod-0001 --delivery-pipeline web-app-profiles --release web-app-profiles-001
```

After a short time, your promotion should complete. To verify this, run the following command:

```bash
gcloud alpha deploy rollouts list --delivery-pipeline web-app-profiles --release web-app-profiles-001
```

Your output should contain output similar to the following:

```terminal
---
approvalState: APPROVED
approveTime: '2021-08-06T10:41:52.197639Z'
createTime: '2021-08-06T10:40:01.770182Z'
deployEndTime: '2021-08-06T10:42:06.016017Z'
deployStartTime: '2021-08-06T10:41:52.766512216Z'
deployingBuild: projects/243106549432/locations/us-central1/builds/16b66075-e655-47b1-97bb-feb4efd225f4
enqueueTime: '2021-08-06T10:41:52.197639Z'
etag: 5cb659630a96cc3f
name: projects/{{project-id}}/locations/us-central1/deliveryPipelines/web-app-profiles/releases/web-app-profiles-001/rollouts/web-app-profiles-001-to-prod-0001
state: SUCCESS
targetId: prod
---
```

The rollout may take several minutes. If you do not see `state: SUCCESS` in the output from the previous command, please wait and periodically re-run the command until the rollout completes.

You can also confirm your `prod` GKE cluster has your apps deployed:

```bash
kubectx prod && kubectl get pods -n web-app-profiles
```

The output of your `kubectl` command should look similar to the following:

```terminal
NAME                                   READY   STATUS    RESTARTS   AGE
leeroy-app-profiles-78c4bd6f65-cx8zw   1/1     Running   0          107s
leeroy-app-profiles-78c4bd6f65-ml49w   1/1     Running   0          107s
leeroy-app-profiles-78c4bd6f65-qg47l   1/1     Running   0          107s
leeroy-web-profiles-8448cd558f-mhzgd   1/1     Running   0          107s
```

Notice that in the `prod` environment, three instances of the `leeroy-app-profiles` pod should be running.

<walkthrough-editor-open-file filePath="web-profiles/leeroy-app-profiles/kubernetes/prod/target.yaml">Click here to review target.yaml for the `prod` Target.</walkthrough-editor-open-file>

Notice at the bottom of the file that this overlay includes setting the value of the `TARGET` environment variable to `prod`, as well as setting the number of replicas of the app to 3.

To confirm that your application configuration has been specialized for the `prod` Target, run the following commands in your Cloud Shell:

```bash
kubectx prod && kubectl logs -l app=leeroy-app-profiles -n web-app-profiles
```

The output of your `kubectl` command should look similar to the following:

```terminal
Switched to context "prod".
2021/08/06 10:42:08 leeroy app server ready, runnning in target: prod
2021/08/06 10:42:07 leeroy app server ready, runnning in target: prod
2021/08/06 10:42:10 leeroy app server ready, runnning in target: prod
```

Your Cloud Deploy per-Target configuration worked, and your application is now deployed to your prod GKE cluster. In the next section you'll clean up the resources you've created for this tutorial.

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

Thank you for taking the time to get to know the Cloud Deploy Preview from Google Cloud!

<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>

<walkthrough-inline-feedback></walkthrough-inline-feedback>
