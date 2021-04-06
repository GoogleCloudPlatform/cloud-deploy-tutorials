<walkthrough-author
    tutorialname="Cloud Deploy Tutorial"
    repositoryUrl="https://source.cloud.google.com/cloud-deploy-experiment/mcd-experiment/"
    >
</walkthrough-author>

# Cloud Deploy (Experiment)

## Welcome!
This tutorial guides you through setting up and using the **Cloud Deploy** experiment. 

The tutorial includes commands that you execute in the Shell. Click the Copy to Cloud Shell button next to each command, and press **Enter** in the Cloud Shell prompt.

### Setup
**Configure the experiment with project details**

<walkthrough-project-setup></walkthrough-project-setup>

Set the project variables to use throughout the tutorial. 

```bash
gcloud config set core/project {{project-id}}
export PROJECT_ID=$(gcloud config get-value core/project)
```

**Deploy the experiment into the selected project** by running the following command. 
```bash
./bootstrap.sh
source env.sh
```

*Note that it might take 5-10 minutes for `bootstrap.sh` to finish setting up the tutorial.*

### Tutorial
Now click the **Start** button, below, to begin the tutorial.

## Step 1: Tutorial overview
---

This tutorial shows you how to use **Cloud Deploy**. It's divided into two sections:

* **Basic** (steps 2–8) 

  Deployment fundamentals 

* **Advanced** (optional, steps 9–11)

  Advanced deployment using Skaffold and Helm

### Concepts and Tooling
The tutorial is meant to teach the core concepts and tooling of Cloud Deploy, including the following primary resources, definition files, and commands that you will use:

Resource  | Commands
------- | --------
Delivery pipeline | `gcloud-deploy delivery-pipelines`,<br><br> and `gloud-deploy apply`
Environment | `gcloud-deploy environments`,<br><br> and `gloud-deploy apply`
Release candidate | `gcloud-deploy release-candidates`,<br><br> and `gcloud-deploy promote`
Rollout | `gcloud-deploy rollouts`

### Supporting materials
The User Guide includes a detailed walkthough corresponding to each step in this tutorial, if you want to explore more deeply.

### Let's Go!
Click 'Next' to get started!

## Step 2: Define and register your environment
The below tasks correspond to the **Define and register a delivery pipeline and an environment** walkthrough in the User Guide.

---
In this step you create and configure your first **environment** into which to deliver an application.

First, we define the name of the *environment*. We'll call this first environment *staging*. 

Next, we need to create an Environment definition. We've already pre-generated this for you.

<walkthrough-editor-select-line filePath="cloudshell_open/mcd-experiment/config/staging-env.yaml" startLine="11" startCharacterOffset="0" endLine="19" endCharacterOffset="99">Click here to review the *staging* environment yaml file</walkthrough-editor-select-line>
 
Notice that in the displayed yaml the environment has a unique name, along with the necessary connection details.

Now, let’s *register* the environment with the Cloud Deploy service.
```bash
gcloud-deploy apply config/staging-env.yaml 
```

And verify the environment has been created.
```bash
gcloud-deploy environments list
```

## Step 3: Define and register a delivery pipeline
The following tasks correspond to the **Define and register a delivery pipeline and an environment** walkthrough in the User Guide.

---
In this step you define a **delivery pipeline** for an application, and the associated target environment to deploy it to. 

First, we need a name used for the delivery pipeline and application. We'll call the application "web". We've already pre-generated this for you.

<walkthrough-editor-select-line filePath="cloudshell_open/mcd-experiment/config/web-pipeline.yaml" startLine="11" startCharacterOffset="0" endLine="18" endCharacterOffset="99">Click here to review the *web-pipeline* delivery pipeline yaml file</walkthrough-editor-select-line>

Notice that just like environment, the delivery pipeline is given a unique name. The pipeline also includes a promotion sequence of environments (in this case, just one).

Again we use the `gcloud-deploy apply` command to register the delivery pipeline with the Cloud Deploy service. 
```bash
gcloud-deploy apply config/web-pipeline.yaml
```

And verify that the delivery pipeline was created.
```bash
gcloud-deploy delivery-pipelines list
```

## Step 4: Sample application
The following tasks correspond to the **Create a release candidate** walkthrough in the User Guide.

---
Now that you have a delivery pipeline and environment registered with Cloud Deploy, it's time to create a release candidate.

For this example, we use the **[Skaffold](http://www.skaffold.dev)** [microservices example](https://github.com/GoogleContainerTools/skaffold/tree/master/examples/microservices), which has been cloned to your Cloud Shell.

Review the files in the `web` directory to see the application being deployed. In particular, let's look at the `skaffold.yaml` file.

<walkthrough-editor-open-file filePath="cloudshell_open/mcd-experiment/web/skaffold.yaml">Click here to review the skaffold.yaml file</walkthrough-editor-open-file>

## Step 5: Create a release candidate
The following tasks correspond to the **Create a release candidate** walkthrough in the User Guide.

---
Now that your delivery pipeline and environment definitions have been created, the next step is to create a **release candidate**.

A release candidate is associated with a delivery pipeline.

First, let’s build and push the application image(s) using **[Skaffold](http://www.skaffold.dev)**.
```bash
cd web

skaffold build --default-repo gcr.io/${PROJECT_ID}

cd ..
```

Now that the application is built and pushed, we use the `gcloud-deploy release-candidates` command to create a release candidate, passing in a reference to the skaffold yaml source directory (the `--source` flag) as well as the list of images built by Skaffold (the `--image` flag). Each release candidate must have a unique name.

Next, call `gcloud-deploy release-candidates create` to create a new release candidate called *release-1*.
```bash
GIT_SHA=$(git rev-parse --short HEAD)

gcloud-deploy release-candidates create \
    --source=web   \
    --delivery-pipeline=web-app    \
    --name=release-1   \
    --image=leeroy-web=gcr.io/${PROJECT_ID}/leeroy-web:${GIT_SHA}-dirty \
    --image=leeroy-app=gcr.io/${PROJECT_ID}/leeroy-app:${GIT_SHA}-dirty
```

Finally, verify that the release candidate has been created.
```bash
gcloud-deploy release-candidates list
```

**Skaffold** is not required to build our example application, but it is intergral to Cloud Deploy. A Skaffold yaml file is required in order to **render** configuration.

Rendering is *the process of generating a configuration manifest*, as part of a deployment. When you create a release candidate, the `--source` flag indicates where to find the Skaffold yaml and the associated configuration files. The `gcloud-deploy` command, in turn, bundles the Skaffold yaml and source directory together (stored in a gcs bucket) for rendering when a **rollout** is created, producing a configuration manifest to apply to a target environment.

The release candidate has not been deployed to an environment yet. That happens in the next step where we discuss rollouts.

## Step 6: Create a rollout
The following tasks correspond to the **Create a rollout** walkthrough in the User Guide.

---
### Create rollout
Now that you've created a release candidate, it’s time to perform a **rollout**. A rollout deploys a release candidate into an environment.

Rollouts are performed in either of two ways:
* As part of creating a release candidate, using the `--target-environment=` flag with `gcloud-deploy release-candidates`
* Directly, using `gcloud-deploy rollouts create`.

Below we create a rollout directly, deploying release candidate *release-1* to environment *staging* and named *staging-release-1*.
```bash
gcloud-deploy rollouts create \
  --name=staging-release-1 \
  --release-candidate=release-1 \
  --environment=staging \
  --delivery-pipeline=web-app
```

Like release candidates, each rollout must have a unique name.

Verify that the rollout was created.
```bash
gcloud-deploy rollouts list --environment=staging
```

### Confirm rollout
Wait a minute or so, then confirm that the rollout has completed by using the command below to check the `Reason`, `Status` and `Type` attributes, of attribute `Rollout Condition`, for **Complete**, **True** and **Complete** respectively. 

***Note**: If the `Rollout Condition` attribute values above are not present, wait a minute or so and then rerun the command.*
```bash
gcloud-deploy rollouts describe staging-release-1
```

Finally, verify that the application was deployed to the target environment. You should see two entries, *leeroy-app* and *leeroy-web*.

***Note**: it may take a moment for the rollout deployment to complete. If you experience 'No resources found in default namespace.', wait and then retry.*
```bash
kubectl --context stage get deployments
```

## Step 7: Adding environments
The following tasks correspond to the **Create and deploy into ‘test’ and ‘prod’ environments** walkthrough in the User Guide.

---
Now that you've deployed into the staging environment, a logical next question is "How can I deploy to multiple environments using my delivery pipeline?" That's exactly what is demonstrated in this step.

First, create two additional environment definitions for deployment: *test* and *prod*. We have already pre-generated each of these definitions for you.

<walkthrough-editor-select-line startLine="11" startCharacterOffset="0" endLine="19" endCharacterOffset="99" filePath="cloudshell_open/mcd-experiment/config/test-env.yaml">Click here to review the *test* environment definition yaml</walkthrough-editor-select-line>

<walkthrough-editor-select-line startLine="11" startCharacterOffset="0" endLine="19" endCharacterOffset="99" filePath="cloudshell_open/mcd-experiment/config/prod-env.yaml"> Click here to review the *prod* environment definition yaml</walkthrough-editor-select-line>

And register the two new environment definitions with Cloud Deploy.
```bash
gcloud-deploy apply config/test-env.yaml
gcloud-deploy apply config/prod-env.yaml
```

We also have to update the **promotion sequence** in the delivery pipeline definition yaml. We've included a `delivery.py` helper script to make this modification for you.
```bash
./deliver.py pipeline add-env --app web --env test,prod
```
<walkthrough-editor-select-line filePath="cloudshell_open/mcd-experiment/config/web-pipeline.yaml" startLine="15" startCharacterOffset="0" endLine="16" endCharacterOffset="99">Click here to review the updated delivery pipeline definition</walkthrough-editor-select-line>

Notice that in the updated delivery pipeline definition the *test*, and *prod* environments are listed sequentially, following *staging*. This ordering is the delivery pipeline's *promotion sequence*.

Finally, let's register the updated delivery pipeline definition with Cloud Deploy using `gcloud-deploy apply`.
```bash
gcloud-deploy apply config/web-pipeline.yaml
```

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