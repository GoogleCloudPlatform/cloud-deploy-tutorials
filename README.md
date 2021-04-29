# Cloud Deploy (Experiment)
Copyright Google LLC 2020

Google Confidential, Pre-GA Offering for Google Cloud Platform (see https://cloud.google.com/terms/service-terms)

## Overview

This repository contains content and functionality to help you install and try out the Cloud Deploy service. Currently, this service is not intended for production workloads—do not use it for any live applications.

## Internal Testing

_NOTE_: This method is only for MAD Team internal testing. This is not how the application will be delivered to users for Private Preview or beyond.

To test out the Cloud Deploy tutorial at any time, follow these instructions: 

* Open Cloud Shell in your browser.
* Go to https://clouddeploy.googlesource.com/new-password and follow the instructions to add an authentication cookie to your Cloud Shell instance.
* Clone the repository:
  ```bash
  git clone https://clouddeploy.googlesource.com/tutorial
  ```
* Launch the tutorial window:
  ```bash
  teachme tutorials/walkthroughs/cloud_deploy_e2e_gke.md
  ```

The tutorial window should open in your browser tab on the right side. From that, read and follow the instructions in your Cloud Shell window.

### Issues accessing the tutorial

Please contant the Cloud Deploy tutorial team at clouddeploy-tutorial-team@google.com if you have issues accessing the tutorial using the steps above.

**Additional references**
- [Experiment Source Repo](https://source.cloud.google.com/cloud-deploy-experiment/mcd-experiment/+/master:README.md)
- User Guide (contact mad-eap-feedback@google.com for link/access)
