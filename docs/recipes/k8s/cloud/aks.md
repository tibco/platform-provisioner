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
    TP_CLUSTER_NAME: "" # cluster name
    TP_TOP_LEVEL_DOMAIN: "" # eg. azure.dataplanes.pro for azure envs
    TP_SANDBOX: "" # This will be used for the all ingresses for this AKS. For TIBCO Platform; we create top level domain with sandbox for each Azure       account. The domain will be like: ${TP_SANDBOX}.azure.dataplanes.pro. We can find the supported sandbox in Azure DNS resource group. The sandbox is based on account. eg: "platform-int". If you have region on certificate; the region need to put here like "eu-west-1.platform-int". sandbox list doc: https://confluence.tibco.com/pages/viewpage.action?pageId=190135472 
    TP_MAIN_INGRESS_SANDBOX_SUBDOMAIN: "" # This will be used for the main ingress for this AKS. For TIBCO Platform; we create top level domain with sandbox for each Azure account. The domain will be like: ${TP_SANDBOX}.azure.dataplanes.pro. It is suggested to add an environment prefix to the domain using TP_MAIN_INGRESS_SANDBOX_SUBDOMAIN variable . eg: ${TP_MAIN_INGRESS_SANDBOX_SUBDOMAIN}.${TP_SANDBOX}.azure.dataplanes.pro.
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
    AZURE_RESOURCE_GROUP: "" # Resource group name
    CP_PROVIDER: "azure"
    CP_CLUSTER_NAME: "" # cluster name
    CP_DNS_DOMAIN: "" # This is complete domain including TP_MAIN_INGRESS_SANDBOX_SUBDOMAIN and TP_SANDBOX which were used to while creating TP Cluster eg. ${TP_MAIN_INGRESS_SANDBOX_SUBDOMAIN}.${TP_SANDBOX}.azure.dataplanes.pro
    CP_STORAGE_CLASS: "" # eg. For Azure use `azure-files-sc`

    # container registry
    CP_CONTAINER_REGISTRY: "" # use jFrog for CP production deployment  eg. `csgprduswrepoedge.jfrog.io`
    CP_CONTAINER_REGISTRY_USERNAME: "" # registry username
    CP_CONTAINER_REGISTRY_PASSWORD: "" # registry password
```

