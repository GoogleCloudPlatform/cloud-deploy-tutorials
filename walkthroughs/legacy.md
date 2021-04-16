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