<walkthrough-author
    tutorialname="Cloud Deploy Tutorial"
    repositoryUrl="https://clouddeploy.googlesource.com/tutorial"
    >
</walkthrough-author>

# Cloud Deploy Quickstart

## Overview
This tutorial guides you through setting up and using the Google Cloud Deploy service. In the initial guides, you'll create a GCP Project (or use an existing one if you choose) to create a complete **test > staging > production** pipeline using Cloud Deploy.

<!-- TODO: We need a graphic/logo/something here for impact. Possibly a graphic of the dev > staging > prod pipeline for emphasis? -->

<!-- TODO: Will it? If so, add link -->
### Supporting materials

The User Guide includes a detailed walkthough corresponding to each step in this tutorial, if you want to explore more deeply.

Estimated Duration:
<walkthrough-tutorial-duration duration="20"></walkthrough-tutorial-duration>

Click the Start button below to begin.

## Configuring Cloud Shell

This tutorial uses [Google Cloud Shell](https://cloud.google.com/shell) to configure and interact with Cloud Deploy. Cloud Shell is an online development and operations environment accessible anywhere with your browser. You can manage your resources with its online terminal preloaded with utilities such as the gcloud command-line tool, kubectl, and more. You can also develop, build, debug, and deploy your cloud-based apps using the online [Cloud Shell Editor](https://ide.cloud.google.com/).

### Selecting a Project
First, select a Project to deploy Cloud Deploy. You can also create a new Project if you want. This is the Project that will house the Cloud Deploy components as well as the three GKE clusters that will act as your development, staging, and production environments.

_The Cloud Deploy Team highly recommends for you to create a new project for this tutorial. You're not going to be doing anything damaging, but depending on names for infrastructure in an existing project, the tutorial could fail to deploy or you could have unwanted things happen._

<walkthrough-project-setup></walkthrough-project-setup>

Next, you'll get your work environment configured in Cloud Shell. Click the Next button below to continue.

## Configuring Cloud Shell

You'll do your work for this tutorial in Cloud Shell. To begin, open Cloud Shell in your browswer window by clicking the Cloud Shell icon <walkthrough-cloud-shell-icon></walkthrough-cloud-shell-icon>. 

If you don't see the Cloud Shell icon in your window, you can also click below to open Cloud Shell.

<walkthrough-open-cloud-shell-button></walkthrough-open-cloud-shell-button>

Next, you'll download the tutorial code base to your Cloud Shell.

### Accessing the Tutorial Code

The source code for this tutorial is housed in a git repository. Your Cloud Shell VM has `git` pre-installed, so you don't need to worry about managing any packages. On your Cloud Shell instance, run the following command to clone the repository to your local disk. 

```bash
git clone https://clouddeploy.googlesource.com/tutorial
```

This clones the tutorial source code you'll use into the `tutorial` folder in your Cloud Shell home directroy. Now it's time to deploy your infrastructure. 

Click the Next button to continue.

## Deploying Infrastructure

You'll deploy three GKE clusters with the following names into your *{{project-id}}* Project: 

GKE Cluster Name | Purpose
----- | -----
`test` | Application testing environment
`staging` | Staging environment prior to production push
`prod` | Production environment

_If you have an existing GKE cluster in {{project-id} with any of those names, you'll need to select another project to use._

Next, you'll deploy three GKE clusters into individual VPCs in _{{project-id}}_. This is your application deployment infrastructure. 

<!-- TODO: A graphic would help this be undesrtood better. Simple squares with VPCs etc -->

To your GKE clusters and all the additional needed resources for this tutorial, there's a `bootstrap.sh` script in the tutorial source code.  

To execute the `bootstrap.sh` , run the following commands in your Cloud Shell

```bash
cd tutorial
./bootstrap.sh
```

The bootstrap process may take a few minutes to run. Once completed successfully, confirm your GKE clusters are up and functioning by running the following command: 

```bash
gcloud container clusters list
```

Your output should look similar to this, and all three clusters should have 3 nodes and have a `RUNNING` status.

```terminal
NAME     LOCATION     MASTER_VERSION    MASTER_IP       MACHINE_TYPE   NODE_VERSION      NUM_NODES  STATUS
prod     us-central1  1.17.17-gke.2800  35.194.37.64    n1-standard-2  1.17.17-gke.2800  3          RUNNING
staging  us-central1  1.17.17-gke.2800  35.232.139.69   n1-standard-2  1.17.17-gke.2800  3          RUNNING
test     us-central1  1.17.17-gke.2800  35.188.180.217  n1-standard-2  1.17.17-gke.2800  3          RUNNING
```

You're now ready to begin configuring Cloud Deploy. Click the Next button below to proceed.

## Creating Your Cloud Deploy Environment

This tutorial focuses on core concepts and tooling of Cloud Deploy. The primary commands you'll be using are:

<!-- TODO: update this list of commands -->
Resource  | Commands
------- | --------
Delivery Pipeline | `gcloud alpha deploy delivery-pipelines`
Targets | `gcloud alpha deploy targets`
Release candidate | `gcloud alpha deploy release-candidates`
Rollout | `gcloud alpha deploy rollouts`

<!-- TODO: Keep this updated depending on the app lifecycle -->
### Enabling the Cloud Deploy API

<!-- TODO: This may change or be wholly unneeded. I'm leaving it here for current testing if nothing else --jduncan -->
Because Cloud Deploy is currently a Private Preview product, you need to enable the API. To accomplish this, run the following commands in your Cloud Shell.

```bash
gcloud config set api_endpoint_overrides/clouddeploy "https://staging-clouddeploy.sandbox.googleapis.com/"
gcloud services enable staging-clouddeploy.sandbox.googleapis.com --project={{project-id}}
```

### Configuring Cloud Deploy

Some Cloud Deploy parameters can be configured in your `gcloud` SDK to avoid typing them for every command. To set a default Cloud Deploy region for the rest of the commands in this tutoria, run the following command on your Cloud Shell: 

```bash
gcloud config set deploy/region $REGION
```

This will be used for any additonal Cloud Deploy commands unless your override it using the `--region` parameter. The full list of Cloud Deploy configurations is available at [TODO]. You're ready to deploy your first Cloud Deploy resource in your Project.

Click the Next button to proceed.

## Creating Your Delivery Pipeline

In this section you'll create the environment for your infrastructure. For this tutorial, you're creating a Cloud Deploy environment that consists of one _Delivery Pipeline_ for a web application that progresses through three _Targets_. These targets are your _test, staging, and prod_ GKE clusters.

Cloud Deploy uses YAML files to define resources. For the tutorial, these files are all in the repository you previously cloned to your Cloud Shell. The first resource you need to create is the Delivery Pipeline. 

<walkthrough-editor-select-line filePath="tutorial/clouddeploy-config/delivery-pipeline.yaml" startLine="11" startCharacterOffset="0" endLine="19" endCharacterOffset="99">Click here to review the Delivery Pipeline yaml file.</walkthrough-editor-select-line>
 
To create your Delivery Pipeline, run the following command in your Cloud Shell. 

```bash
gcloud alpha deploy apply --file=clouddeploy-config/delivery-pipeline.yaml 
```

To verify your Delivery Pipeline has been created, run the following command:

```bash
gcloud alpha deploy delivery-pipelines list
```

The output should look similar to the output below: 

```terminal
---
createTime: '2021-04-12T18:34:02.614196898Z'
description: web-app delivery pipeline
etag: 2539eacd7f5c256d
name: projects/jduncan-cd-testing/locations/us-central1/deliveryPipelines/web-app
serialPipeline:
  stages:
  - targetId: test
  - targetId: staging
  - targetId: prod
uid: b116d89067e64d7eb63f37fe5e99d1ff
updateTime: '2021-04-12T18:34:04.936664219Z'
```

With your Delivery Pipeline confirmed, you're read to create your three Targets. 

Click the Next button to proceed.

## Creating your Testing Target

In Cloud Deploy, a Target is a GKE cluster where an application can be deployed as part of a Delivery Pipeline. In your Delivery Pipeline, the first Target to be deployed to is yout `test` GKE cluster. This is done by applying a YAML file to Cloud Deploy using the `glcoud alpha deploy` command in the SDK.

<walkthrough-editor-select-line filePath="tutorial/clouddeploy-config/test-environment.yaml" startLine="11" startCharacterOffset="0" endLine="19" endCharacterOffset="99">Click here to view your test Target yaml file.</walkthrough-editor-select-line>

To create your test Target, run the following command in your Cloud Shell.

```bash
gcloud alpha deploy apply --file clouddeploy-config/test-environment.yaml
```

Once this completes (a second or two), verify your new Target has been created using the following `gcloud` command to list the existing targets for your `web-app` Delivery Pipeline:

```bash
gcloud alpha deploy targets list --delivery-pipeline=web-app
```

The output should look similar to the example below:

```terminal
---
createTime: '2021-04-15T13:53:31.094996057Z'
description: test cluster
etag: 4c7d828d4f7a3b74
gkeCluster:
  cluster: test
  location: us-central1˜
  project: jduncan-cd-testing
name: projects/jduncan-cd-testing/locations/us-central1/deliveryPipelines/web-app/targets/test
uid: d1d2ca2dc4bf4884a8d16588cfe6d458
updateTime: '2021-04-15T13:53:31.663277590Z'
```

In the following section, you'll create similar Targets for your `staging` and `prod` GKE clusters.

Click the Next button to proceed.

## Creating Staging and Prod Targets

The process to create your Staging and Prod Targets is the same as the Test target you just created. You'll start with your staging Target. 

<walkthrough-editor-select-line filePath="tutorial/clouddeploy-config/staging-environment.yaml" startLine="11" startCharacterOffset="0" endLine="19" endCharacterOffset="99">Click here to view your staging Target yaml file.</walkthrough-editor-select-line>

To create the staging Target run the following command in Cloud Shell:

```bash
gcloud alpha deploy apply --file clouddeploy-config/staging-environment.yaml
```

With that created, create your prod Target next. 

<walkthrough-editor-select-line filePath="tutorial/clouddeploy-config/prod-environment.yaml" startLine="11" startCharacterOffset="0" endLine="19" endCharacterOffset="99">Click here to view your prod Target yaml file.</walkthrough-editor-select-line>

To create your Prod Target run the following command in Cloud Shell:

```bash
gcloud alpha deploy apply --file clouddeploy-config/prod-environment.yaml
```

With both Targets created, verify everything is correct by looking at all of the Targets for the `web-app` Delivery Pipeline:

```bash
gcloud alpha deploy targets list --delivery-pipeline=web-app
```

Your output should look similar to the example below: 

```terminal
---
createTime: '2021-04-15T16:43:59.404939886Z'
description: staging cluster
etag: 9c923d5f1dd88c97
gkeCluster:
  cluster: staging
  location: us-central1˜
  project: jduncan-cd-testing
name: projects/jduncan-cd-testing/locations/us-central1/deliveryPipelines/web-app/targets/staging
uid: b1a856d72e5d43de817c2ea8380da39b
updateTime: '2021-04-15T16:44:00.272725580Z'
---
createTime: '2021-04-15T13:53:31.094996057Z'
description: test cluster
etag: 4c7d828d4f7a3b74
gkeCluster:
  cluster: test
  location: us-central1˜
  project: jduncan-cd-testing
name: projects/jduncan-cd-testing/locations/us-central1/deliveryPipelines/web-app/targets/test
uid: d1d2ca2dc4bf4884a8d16588cfe6d458
updateTime: '2021-04-15T13:53:31.663277590Z'
---
createTime: '2021-04-15T16:44:31.295700Z'
description: prod cluster
etag: ff1840e2d8c3010a
gkeCluster:
  cluster: prod
  location: us-central1
  project: jduncan-cd-testing
name: projects/jduncan-cd-testing/locations/us-central1/deliveryPipelines/web-app/targets/prod
uid: 0c22c1fb08e546ee9ae569ce501bac95
updateTime: '2021-04-15T16:44:32.078235982Z'
```

You've now created the all of the Cloud Deploy Targets as well as your Delivery Pipeline. Now it's time to build your application in order to create a Release Candidate. 

Click the Next button to proceed. 

## Building your Application

Cloud Deploy integrates tightly with [`skaffold`](https://skaffold.dev/), a leading open source Continuous Delivery tool. When you ran `bootstrap.sh`, a sample application was cloned from a [Github repository](https://github.com/GoogleContainerTools/skaffold.git) to your Cloud Shell instance in the `web` directory. 

In this section, you'll build that application image so you can progress it through your Delivery Pipeline.

### Configuring Artifact Registry Authentication

The Google Artifact Registry was enabled as part of running `bootstrap.sh`. To push a container image to the registry, you need to enable the `docker` daemon on your Cloud Shell instance to log in to Artifact Registry using your active SDK authentication token. This requires a few commands to be run on your Cloud Shell instance. These commands allow your user to run `docker` commands on Cloud Shell and also configures the local `docker` daemon to authentication using `gcloud` for your Artifact Registry domain.

```bash
sudo usermod -a -G docker ${USER}
gcloud auth configure-docker ${REGION}-docker.pkg.dev
```

With these steps complete, authenticate to your Artifact Registry. This allows `skaffold` in the next section to push your created image into Artifact Registry.

```bash
docker login ${REGION}-docker.pkg.dev
```
You're now set to build your application image.

### Building with Skaffold

The example application source code is on your Cloud Shell instance in the `web` directory. That directory contains `skaffold.yaml`. This file contains the instructions for `skaffold` to use to build a container image for your application.

<walkthrough-editor-select-line filePath="tutorial/web/skaffold.yaml" startLine="11" startCharacterOffset="0" endLine="19" endCharacterOffset="99">Click here to view skaffold.yaml file.</walkthrough-editor-select-line>

Your application images will be called `leeroy-web` and `leeroy-app` when it's deployed. To create these container images for, run the following command in Cloud Shell.

```bash
cd web/
skaffold build --default-repo ${REGION}-docker.pkg.dev/{{project-id}}/web-app
```

If you're familiar with building container images this output should look familiar to you. To confirm your images have been successfully pushed to your Artifact Registry, run the following command. The `--format jason` parameter makes the content output in JSON format to be easier to read:

```bash
gcloud artifacts docker images list ${REGION}-docker.pkg.dev/${PROJECT_ID}/web-app --include-tags --format json
```

Your output should look similar to the example below: 

```terminal
Listing items under project jduncan-cd-testing, location us-central1, repository web-app.

[
  {
    "createTime": "2021-04-15T23:15:15.792959Z",
    "package": "us-central1-docker.pkg.dev/jduncan-cd-testing/web-app/leeroy-app",    "tags": "63ec18a",
    "updateTime": "2021-04-15T23:15:15.792959Z",
    "version": "sha256:80d8a867b82eb402ebe5b48f972c65c2b4cf7657ab30b03dd7b0b21dfc4a6792"
  },
  {
    "createTime": "2021-04-15T23:15:27.320207Z",
    "package": "us-central1-docker.pkg.dev/jduncan-cd-testing/web-app/leeroy-web",
    "tags": "63ec18a",
    "updateTime": "2021-04-15T23:15:27.320207Z",
    "version": "sha256:30c37ef69eaf759b8c151adea99b6e8cdde85a81b073b101fbc593eab98bc102"
  }
]
```

By default, `skaffold` sets the tag for an image to the same value as the short form of the `git` commit ID. You can use this to verify the image you're adding to a Cloud Deploy Release.

### Verifying your Application Image

To ensure there were no issues when building or pushing your application image, run the following `git` command. This value should match

```bash
export GIT_SHA=$(git rev-parse --short HEAD)
```

This value should match the `tags` value in the Artifact Registry output above. For this example, both values should be `63ec18a`.

```bash
gcloud artifacts docker images list ${REGION}-docker.pkg.dev/${PROJECT_ID}/web-app --include-tags --format=value"(tags)"
```

The output should look similar to this: 

```terminal
Listing items under project jduncan-cd-testing, location us-central1, repository web-app.

63ec18a
63ec18a
```

You can confirm this matches the git commit ID.
```bash
echo $GIT_SHA
```

If the values match, your application container images are now built, verified, and ready for Cloud Deploy. In the next section you'll create a release for your application.

Click the Next button to proceed.

## Creating an Application Release

In Cloud Deploy, a Release is a specific version of one or more application images that are associated with a specific Delivery Pipeline. Once created, a Release can be promoted through multiple Targets.

Because this will be the first release of your application stack, call this release `leeroy-001`.

To create a Release, run the following command in your Cloud Shell instance. This command pulls together almost everything you've done so far. It references the Delivery Pipeline as well as the container images:

```bash
gcloud alpha deploy releases create leeroy-001 --delivery-pipeline web-app --images leeroy-web=${REGION}-docker.pkg.dev/{{project-id}}/web-app/leeroy-web:${WEB_SHA},leeroy-app=${REGION}-docker.pkg.dev/{{project-id}}/web-app/leeroy-app:${APP_SHA}
```

To confirm your 





## Step 8: Promoting through environments
The following tasks correspond to the **Create and deploy into 'test' and 'prod' environments** section in the User Guide.

---
### Create a new release candidate
With an updated delivery pipeline definition that includes a *promotion sequence*, now we create a new release candidate.

This time we create a release candidate and, implicitly, a rollout that is directly deployed into the *test* environment using the `glcoud-deploy releases-candidates` command with the `--target-environment` flag. This way we skip deploying into *staging* and deploy directly into *test*.

***Note**: the generated rollout is given the same name as the release candidate when you use `target-environment`, implicitly.*

We do this to illustrate how to 'jump the line' in case you need to deploy a release candidate directly into a specific environment. This is important for the purposes of quickly deploying critical patches, for instance.

Create a new release candidate and deploy directly into *test*, named `release-2`.
```bash
GIT_SHA=$(git rev-parse --short HEAD)

gcloud-deploy release-candidates create \
    --source=web \
    --delivery-pipeline=web-app \
    --target-environment=test \
    --name=release-2 \
    --image=leeroy-web=gcr.io/${PROJECT_ID}/leeroy-web:${GIT_SHA}-dirty \
    --image=leeroy-app=gcr.io/${PROJECT_ID}/leeroy-app:${GIT_SHA}-dirty
```

### Confirm rollout
Wait a minute or two before using `gcloud-deploy promote` to promote to the next environment in the promotion sequence.

You can confirm whether the rollout has completed by using `gcloud-deploy rollouts describe` to check the `Reason`, `Status` and `Type` attributes, of attribute `Rollout Condition`, for **Complete**, **True** and **Complete** respectively. 

***Note**: If the `Rollout Condition` attribute values above are not present, wait a minute or so and then rerun the command.*
```bash
gcloud-deploy rollouts describe release-2
```

### Promote a release candidate
Once you confirm that the rollout to *test* has completed, **promote** the release candidate to *prod* explicitly, using the `gcloud-deploy promote` command with the `--target-environment` flag.
```bash
gcloud-deploy promote  \
    --delivery-pipeline=web-app     \
    --rollout-name=prod-release-2     \
    --source-environment=test     \
    --target-environment=prod
```

Again, confirm both rollouts were created:
```bash
gcloud-deploy rollouts list --environment=test
gcloud-deploy rollouts list --environment=prod
```

### Confirm promotion
Verify the application was deployed to *test* and *prod*.

***Note**: it may take a moment for the rollout deployment to complete. If you experience 'No resources found in default namespace.', wait and then retry.*
```bash
kubectl --context test get deployments
kubectl --context prod get deployments
```

## Step 9: Advanced deployments 
The following tasks correspond to the **Customize your pipeline using Skaffold** section in the User Guide.

---
### Great job!
In the prior tutorial steps we covered all of the basics of Cloud Deploy. We showed you how to create new **environments** as well as **delivery pipelines**, and to associate the two. 

We also demonstrated how **release candidates**, representing an appliation release, could be matched with a target environment to create a **rollout**, resulting in a deployment. We also demonstrated how to **promote** the release candidate forward using the **promotion sequence** defined in the delivery pipeline.

We finally demonstrated how you can use **Skaffold** to define and render a configuration manifest for deployment.

### Go deeper
Having learned these fundamentals, you're now equipped to further experiment with **Cloud Deploy** for application deployment. *If this is enough for you, you don't need to proceed further*.

If you want to proceed, however, in the following tutorial steps we cover advanced deployment scenarios using capabilities such as **[Skaffold profiles](https://skaffold.dev/docs/environment/profiles/)** and **[Helm](https://helm.sh/)**.

## Step 10: Create separate Skaffold profiles
The following tasks correspond to the **Create separate Skaffold profiles per environment** walkthrough in the User Guide.

---
Now that we have multiple environments, we can use **[Skaffold](http://www.skaffold.dev/)** to deploy different configuration manifests using different [Skaffold Profiles](https://skaffold.dev/docs/environment/profiles/) per  environment. 

### Add profiles to Skaffold yaml
To get started, first update the Skaffold yaml for your application to reference a separate Skaffold profile for each environment.

<walkthrough-editor-open-file filePath="cloudshell_open/mcd-experiment/web/skaffold.yaml">Click here to open the skaffold.yaml</walkthrough-editor-open-file> file, then replace **all** of the content by copying the following into the file, **and saving it, using `ctrl-s`**:
```yaml
apiVersion: skaffold/v2beta7
kind: Config
build:
  artifacts:
    - image: gcr.io/{{project-id}}/leeroy-web
      context: leeroy-web
    - image: gcr.io/{{project-id}}/leeroy-app
      context: leeroy-app
  tagPolicy:
    gitCommit: {}
portForward:
  - resourceType: deployment
    resourceName: leeroy-web
    port: 8080
    localPort: 9000
profiles:
  - name: staging
    deploy:
      kubectl:
        manifests:
          - leeroy-app/kubernetes/deployment.yaml
          - leeroy-web/kubernetes/deployment.yaml
  - name: testing
    deploy:
      kubectl:
        manifests:
          - leeroy-app/kubernetes/deployment.yaml
          - leeroy-web/kubernetes/deployment.yaml
  - name: production
    deploy:
      kubectl:
        manifests:
          - leeroy-app/kubernetes/deployment.yaml
          - leeroy-web/kubernetes/deployment.yaml
```
Notice the new [profiles section](https://skaffold.dev/docs/references/yaml/#profiles), with separate profiles for each of our three target environments: `staging`, `test`, and `prod`.

In each of these profile definitions, you can specify how to render the configuration manifest. In this tutorial step we copy the same configuration manifests for each profile, but these could be different or could use different tooling (such as [Helm](https://helm.sh/) or [Kustomize](https://github.com/kubernetes-sigs/kustomize)).

### Bind Skaffold profiles with delivery pipeline
Next, we update the delivery pipeline definition to use the newly created and saved Skaffold profiles for each environment. To do so, we specify a `renderSpec` and `skaffoldProfiles` attribute next to each environment in the promotion sequence.

<walkthrough-editor-open-file filePath="cloudshell_open/mcd-experiment/config/web-pipeline.yaml">Click here to open the Delivery Pipeline yaml file</walkthrough-editor-open-file>, then replace **all** of the content by copying the following into the file, **and saving it, using `ctrl-s`**:
```yaml
apiVersion: clouddeploy.googleapis.com/v1alpha1
kind: DeliveryPipeline
metadata:
  name: web-app 
spec:
  environments:
    - environmentName: staging 
      renderSpec:
        skaffoldProfiles: ["staging"]
    - environmentName: test 
      renderSpec:
        skaffoldProfiles: ["testing"]
    - environmentName: prod 
      renderSpec:
        skaffoldProfiles: ["production"]
```

After you've saved the modified delivery pipeline with environment-associated Skaffold profiles, register the updated delivery pipeline definition.
```bash
  gcloud-deploy apply config/web-pipeline.yaml
```

In the next and final tutorial step, we cover use of **[Helm charts](https://helm.sh/docs/topics/charts/)**.

## Step 11: Using Skaffold and Helm charts 
The following tasks correspond to the **Deploy using Skaffold profiles and Helm charts** and **Promote Helm charts through multiple environments** walkthroughs in the User Guide.

---
In this final tutorial step, we associate our previously created delivery pipeline and Skaffold profiles for configuration management (also referred to as **rendering**), on a per-environment basis. We also switch to another Skaffold sample application, [helm-deployment](https://github.com/GoogleContainerTools/skaffold/tree/master/examples/helm-deployment), in order to make this final step clearer and easier.

### Update Skaffold profiles with Helm
**[Helm](https://helm.sh/)** simplifies Kubernetes configuration management. We use **Skaffold, Helm, and Cloud Deploy** *together* to render different manifests per environment.

*We don't need to modify them*, but it's worthwhile to briefly review the contents of the Helm Chart, values, and template files if you haven't seen these before.

<walkthrough-editor-open-file filePath="cloudshell_open/mcd-experiment/web-helm/charts/Chart.yaml">Click here to review the Helm Chart file</walkthrough-editor-open-file>

<walkthrough-editor-open-file filePath="cloudshell_open/mcd-experiment/web-helm/charts/templates/deployment.yaml">Click here to review the Helm Chart deployment template file</walkthrough-editor-open-file>

<walkthrough-editor-open-file filePath="cloudshell_open/mcd-experiment/web-helm/charts/values.yaml">Click here to review the Helm Chart values file</walkthrough-editor-open-file>

To get started using Helm to render environment-specific configuration manifests, we need to modify the existing helm-deployment Skaffold yaml. 

Notice how we retain the Skaffold profiles section from our last tutorial. We pair each profile with its respective environment deployment, but here we have instead replaced the raw Kubernetes manifest with a Helm rendering, using the `setValues` directive to modify the `replicaCount` per environment. 

<walkthrough-editor-open-file filePath="cloudshell_open/mcd-experiment/web-helm/skaffold.yaml">Click here to open the skaffold.yaml</walkthrough-editor-open-file> then replace **all** of the content by copying the following into the file, **and saving it, using `ctrl-s`**:
```yaml
apiVersion: skaffold/v2beta7
kind: Config
build:
  artifacts:
  - image: gcr.io/{{project-id}}/skaffold-helm
profiles:
  - name: staging
    deploy:
      helm:
        releases:
        - name: skaffold-helm
          chartPath: charts
          artifactOverrides:
            image: skaffold-helm
          setValues:
            replicaCount: 1
  - name: testing
    deploy:
      helm:
        releases:
        - name: skaffold-helm
          chartPath: charts
          artifactOverrides:
            image: skaffold-helm
          setValues:
            replicaCount: 2
  - name: production
    deploy:
      helm:
        releases:
        - name: skaffold-helm
          chartPath: charts
          artifactOverrides:
            image: skaffold-helm
          setValues:
            replicaCount: 3
```

Though we probably should create new delivery pipeline and environment definitions because this is a different application, we'll keep things simple and won't modify the existing environment or delivery pipeline definitions. They'll work as they are.

### Create a release candidate
Moving on, we need to build and place the `skaffold-helm` container for this new appliation.
```bash
cd web-helm

skaffold build --default-repo gcr.io/${PROJECT_ID}

cd ..
```

Next, we need to create a release candidate, again using the `--target-environment` flag to deploy directly into the *test* environment.
```bash
GIT_SHA=$(git rev-parse --short HEAD)

gcloud-deploy release-candidates create \
    --source=web-helm \
    --delivery-pipeline=web-app \
    --target-environment=test \
    --name=release-3 \
    --image=skaffold-helm=gcr.io/${PROJECT_ID}/skaffold-helm:${GIT_SHA}-dirty
```

### Confirm rollout
Wait a minute or two before promoting to the next environment. You can again confirm whether a rollout has completed, using `gcloud-deploy rollouts describe` to check the `Reasons`, `Status` and `Type` attributes, of attribute `Rollout Condition`, for **Complete**, **True** and **Complete** respectively.

***Note**: If the `Rollout Condition` attribute values above are not present, wait a minute or so and then rerun the command.*
```bash
gcloud-deploy rollouts describe release-3
```

### Promote the release candidate
Once the Rollout to the *test* environment has completed, you can promote the release candidate from *test* to *prod*.
```bash
gcloud-deploy promote --delivery-pipeline=web-app \
    --rollout-name=prod-release-3 \
    --source-environment=test
```

### Confirm the rollouts
Finally, we verify the deployment of unique configuration manifests per environment, using Skaffold and Helm, by confirming the expected specified `replicaCount` values for *test* and *prod* environments (values of 2 and 3, respectively).

***Note**: it may take a moment for the rollout deployment to complete. If you do not see `skaffold-helm` in either table, wait and then retry until it appears.*
```bash
kubectl --context test get rs
kubectl --context prod get rs
```

## Congratulations and thank you!
---
<walkthrough-conclusion-trophy/>

That's it! With these advanced tutorial steps you can now specify individual configuration *renderings* per environment.

We want to thank you again for participating in the Cloud Deploy experiment release! 

We'd love to hear from you. If you have any additional feedback, thoughts, or questions please reach out to us at **mad-eap-feedback@google.com**!

## Cleaning up
(Optional)

---
When you're done, you can clean up the Tutorial with the following command.

```bash
./cleanup.sh
```