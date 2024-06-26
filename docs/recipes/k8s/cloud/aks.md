## Prepare AKS

### Verify if we can access the Azure account

Under the project root; run the following command to test the pipeline and Azure role. Use your own Azure account.
You need to make sure that you have log in to your Azure account. The platform provisioner script will create a docker container to run the pipeline scripts with the given recipe.
It will mount `.azure` folder to the docker container to access the Azure config.

```bash
export GITHUB_TOKEN=""
export PIPELINE_INPUT_RECIPE="docs/recipes/tests/test-azure.yaml"

export PIPELINE_CHART_REPO="${GITHUB_TOKEN}@raw.githubusercontent.com/tibco/platform-provisioner/gh-pages/"
./dev/platform-provisioner.sh
```

### Create AKS cluster

After making sure that the pipeline can access the AWS account, we can now use deploy-tp-aks.yaml recipe to create a new AKS for TIBCO Platform.

```bash
export GITHUB_TOKEN=""
export PIPELINE_INPUT_RECIPE="docs/recipes/k8s/cloud/deploy-tp-aks.yaml"

export PIPELINE_CHART_REPO="${GITHUB_TOKEN}@raw.githubusercontent.com/tibco/platform-provisioner/gh-pages/"
./dev/platform-provisioner.sh
```

We now have a new AKS to be ready to deploy TIBCO Platform.

Environment variables that need to set in the recipe:
```yaml
meta:
  globalEnvVariable:
    GITHUB_TOKEN: "" # You need to set GITHUB_TOKEN for CP dev in private repo
    TP_RESOURCE_GROUP: ""
    TP_AUTHORIZED_IP: "" # Your public IP
    TP_CLUSTER_NAME: ""
    TP_TOP_LEVEL_DOMAIN: "" # Your top level domain name eg: azure.dataplanes.pro
    TP_SANDBOX: "" # Your sandbox name
    TP_MAIN_INGRESS_SANDBOX_SUBDOMAIN: "" # Your main ingress subdomain name. full domain will be: <TP_MAIN_INGRESS_SANDBOX_SUBDOMAIN>.<TP_SANDBOX>.<TP_TOP_LEVEL_DOMAIN>
    TP_DNS_RESOURCE_GROUP: "" # The resource group for the DNS zone
```

## Deploy TIBCO Control Plane on AKS

Make sure that your kubeconfig can connect to the target AKS cluster. Then we can install CP on minikube with the following command:

```bash
export GITHUB_TOKEN=""
export PIPELINE_INPUT_RECIPE="docs/recipes/controlplane/tp-cp.yaml"

export PIPELINE_CHART_REPO="${GITHUB_TOKEN}@raw.githubusercontent.com/tibco/platform-provisioner/gh-pages/"
./dev/platform-provisioner.sh
```

By default; maildev will be installed. You can access maildev using: http://maildev.localhost.dataplanes.pro

Environment variables that need to set in the recipe:
```yaml
meta:
  globalEnvVariable:
    GITHUB_TOKEN: "" # You need to set GITHUB_TOKEN for CP dev in private repo
    
    # add new variables
    ACCOUNT: "azure-" # Azure account prefix to trigger authenticating with Azure
    AZURE_RESOURCE_GROUP: ""

    # change existing variables
    CP_PROVIDER: "azure"
    CP_CLUSTER_NAME: ""
    CP_DNS_DOMAIN: ""
    CP_STORAGE_CLASS: "" # eg: azure-files-sc
    TP_CERTIFICATE_CLUSTER_ISSUER: "cic-cert-subscription-scope-production-main"

    # container registry
    CP_CONTAINER_REGISTRY: "" # use jFrog for CP production deployment
    CP_CONTAINER_REGISTRY_USERNAME: ""
    CP_CONTAINER_REGISTRY_PASSWORD: ""
```

