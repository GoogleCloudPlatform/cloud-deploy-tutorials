<walkthrough-metadata>
  <meta name="title" content="Cloud Deploy External Integration Tutorial" />
  <meta name="description" content="How to integrate with Google Cloud Deploy" />
  <meta name="component_id" content="1036688" />
  <meta name="keywords" content="Deploy, pipeline, Kubernetes, integration, Pub/Sub" />
  <meta name="unlisted" content="true" />
</walkthrough-metadata>

# Google Cloud Deploy: Preview

![](https://walkthroughs.googleusercontent.com/content/cloud_deploy_external_integration_gke/images/cloud-deploy-logo-centered.png)

## Overview

This interactive tutorial shows you how to integrate external services with [Google Cloud Deploy](https://cloud.google.com/deploy).

You will use a **test > staging > production** delivery pipeline to deploy an application and listen for deployment events using Google Cloud Deploy's integration with [Pub/Sub](https://cloud.google.com/pubsub).

Before starting this tutorial, complete the [Google Cloud Deploy Basic walkthrough](https://cloud.google.com/deploy/docs/tutorials). Complete this tutorial in the same Google Cloud project as the walkthrough.

## About external integration

Google Cloud Deploy uses the following Pub/Sub topics to share event information with other services:

* `clouddeploy-resources`: provides information for creation and lifecycle management of Google Cloud Deploy resources such as delivery pipelines, rollouts, and releases
* `clouddeploy-operations`: provides information about operational tasks in Google Cloud Deploy such as promotions
* `clouddeploy-approvals`: provides information about Google Cloud Deploy approvals

In this tutorial you'll create these Pub/Sub topics in your project and run an application to listen for the events in your Cloud Shell when they occur.

### About Cloud Shell

This tutorial uses [Cloud Shell](https://cloud.google.com/shell) to configure and interact with Google Cloud Deploy. Cloud Shell is an online development and operations environment, accessible anywhere with your browser.

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
cd ~/cloud-deploy-tutorials/tutorials/external-integration && cloudshell workspace .
```

If your Cloud Shell session times out, you can resume the tutorial by reconnecting to Cloud Shell and rerunning the previous command to change into the above directory.

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

To create the needed Pub/Sub topics, click **Next**.

## Create Pub/Sub topics

Google Cloud Deploy looks for explictly named Pub/Sub topics to publish events. To create these topics, run the following command in your Cloud Shell:

```bash
gcloud pubsub topics create clouddeploy-resources
gcloud pubsub topics create clouddeploy-operations
gcloud pubsub topics create clouddeploy-approvals
```

### Confirm topic creation

To confirm these topics have been created, navigate to the [Pub/Sub Topics page](https://pantheon.corp.google.com/cloudpubsub/topic/list?project={{project-id}}). You should see all three topics created.

These are the topics that Google Cloud Deploy will use to publish events. Pub/Sub topics are accessed through a subscription. You will use the `clouddeploy-operations` topic, so that topic will need a corresponding subscription.

### Create a topic subscription

To create a subscription for the `clouddeploy-operations` Pub/Sub topic, run the following command in your Cloud Shell:

```bash
gcloud pubsub subscriptions create clouddeploy-resources-sub --topic clouddeploy-resources
```

To begin listening for Google Cloud Deploy events, click **Next**.

## Listen for Google Cloud Deploy events

This walkthrough includes a small Python application named <walkthrough-editor-open-file filePath="listener.py">
listener.py
</walkthrough-editor-open-file>. Before you run `listener.py` you need to satisfy a few dependencies.

### Open a new Cloud Shell tab

In your Cloud Shell window, click the plus icon <walkthrough-spotlight-pointer spotlightId="cloud-shell-add-tab-button">plus icon</walkthrough-spotlight-pointer> to open a second shell session in a new tab. Switch over to your newly created tab for the next commands. Next, change to the same working directory as your first shell. 

```bash
cd ~/cloud-deploy-tutorials/tutorials/external-integration
```

### Set Project ID

Since this is a new Cloud Shell session, you need to set the project ID again using the following command:

```bash
gcloud config set project {{project-id}}
```

### Set environment variable

The `listener.py` application uses an environment variable named `SUBSCRIPTION_NAME` to specify the Pub/Sub topic to subscribe to and listen for messages. Define this variable using the following command in your Cloud Shell to listen to the `clouddeploy-resources-sub` topic.

```bash
export SUBSCRIPTION_NAME=clouddeploy-resources-sub
```

### Install Python dependencies

In your Cloud Shell, run the following command to install the Python library for Pub/Sub.

```bash
pip3 install google-cloud-pubsub
```

With the dependencies met, run the following command:

```bash
python3 listener.py
```

This application will listen for events in the `clouddeploy-operations` topic using the `clouddeploy-operations-sub` subscription. Return to your original Cloud Shell tab for the next steps.

To test your new configuration, click **Next**

## Test Pub/Sub integration

To test the integration between Google Cloud Deploy and the `listener.py` application using Pub/Sub you need to create an event in your Google Cloud Deploy instance. Creating a new delivery pipeline should register a new Pub/Sub message in the `clouddeploy-resources` topic.

### Create a new delivery dipeline

Create a new delivery pipeline using the following command in Cloud Shell:

```bash
gcloud beta deploy apply --file=./delivery-pipeline-pubsub.yaml
```

You should quickly see confirmation that the delivery pipeline was created, similar to the following output:

```terminal
Waiting for the operation on resource projects/{{project-id}}/locations/us-central1/deliveryPipelines/pubsub-test...done.
```

Verify the delivery pipeline was created:

```bash
gcloud beta deploy delivery-pipelines describe pubsub-test
```

Your output should look like the following. Notice that the targets are not yet created.

```terminal
Unable to get target test
Unable to get target staging
Unable to get target prod
Delivery Pipeline:
  createTime: '2022-01-04T14:12:18.979581436Z'
  description: Testing Cloud Deploy and Pub/Sub integration
  etag: 8733086084e52ee6
  name: projects/{{project-id}}/locations/us-central1/deliveryPipelines/pubsub-test
  serialPipeline:
    stages:
    - targetId: test
    - targetId: staging
    - targetId: prod
  uid: b8deb1a32f434304b92bdba695bbbe59
  updateTime: '2022-01-04T14:12:19.275774368Z'
Targets: []
```

Click **Next** to verify that the message was received.

## Verify the message was received

Go back to your second Cloud Shell tab. Soon after your new delivery pipeline is created, you should see a message similar to the following:

```json
Message {
  data: b''
  ordering_key: ''
  attributes: {
    "Action": "Create",
    "DeliveryPipelineId": "pubsub-test",
    "Location": "us-central1",
    "ProjectNumber": "012345678901",
    "Resource": "projects/012345678901/locations/us-central1/deliveryPipelines/pubsub-test",
    "ResourceType": "DeliveryPipeline"
  }
}
```

You've successfully integrated Google Cloud Deploy with the `listener.py` application.

To learn about next steps, click **Next**.

## Next steps

### Delete the pipeline

To clean up the pipeline created as part of this tutorial, run the following command:

```bash
gcloud beta deploy delivery-pipelines delete pubsub-test --force --quiet
```

### Clean up other resources

To clean up your GKE targets and other resources, run the provided cleanup script. If you would like to continue to another Google Cloud Deploy tutorial, do not complete this step.

```bash
./cleanup.sh
```

The script removes the Google Cloud resources and artifacts on your Cloud Shell instance. It takes about 10 minutes to complete.

### Clean up gcloud configurations

When you ran `bootstrap.sh`, a line was added to your Cloud Shell configuration. For users of the `bash` shell, a line was added to `.bashrc` to reference `$HOME/.gcloud` as the directory `gcloud` uses to keep configurations. If you customized your Cloud Shell environments to use other shells, the corresponding `rc` was similarly edited.

In the `.gcloud` directory a configuration named `clouddeploy` was also created. The configuration allows the `gcloud` configurations to [persist across Cloud Shell sessions and restarts](https://cloud.google.com/shell/docs/configuring-cloud-shell#gcloud_command-line_tool_preferences).

To remove this configuration, remove the line from your `rc` file and delete the `$HOME/.gcloud` directory.

Click **Next** to complete this tutorial.

## Conclusion

The `listener.py` application is a simple application that receives a Pub/Sub message from a single subscription and displays the message on your screen. With Google Cloud Deploy's ability to separate events into multiple topics, and Pub/Sub's ability to create multiple distinct subscriptions from those topics, you can direct data quickly and effectively from your CD events into any third party application.

<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>

<walkthrough-inline-feedback></walkthrough-inline-feedback>

You can find additional tutorials for Google Cloud Deploy in [Tutorials](https://cloud.google.com/deploy/docs/tutorials).
