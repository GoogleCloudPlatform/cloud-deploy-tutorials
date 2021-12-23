# Google Cloud Deploy Tutorial Policies

Copyright Google LLC 2021

## Overview

This directory contains templates for YAML-encoded organizational policy that is necessary to run the Cloud Deploy tutorials.

This may be useful when you want to run the tutorials in a restricted Org. It is required that you have the ability to override policy in specific projects.

## Usage

You must perform these steps before starting the Cloud Deploy tutorial(s).

This is because, without these policy modifications, organizational policies may prevent the required creation of defualt service accounts with the required permissions.

Ensure that you are logged in as a privileged user and that your `gcloud` SDK is set to the correct project, and run:

```
./apply-policies.sh
```

The policies that will be overridden for the current project are:

```
compute.requireOsLogin
compute.requireShieldedVm
compute.restrictVpcPeering
compute.restrictVpnPeerIPs
compute.vmCanIpForward
iam.automaticIamGrantsForDefaultServiceAccounts
```

You can now begin the Cloud Deploy tutorial of your choice.
