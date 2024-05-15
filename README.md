<!-- TOC -->
* [Platform Provisioner](#platform-provisioner)
  * [Get recipes from TIBCO GitHub](#get-recipes-from-tibco-github)
  * [Run the platform-provisioner in headless mode with docker container](#run-the-platform-provisioner-in-headless-mode-with-docker-container)
    * [Prerequisite](#prerequisite)
    * [Run the platform-provisioner in headless mode](#run-the-platform-provisioner-in-headless-mode)
  * [Run the platform-provisioner in headless mode with tekton pipeline](#run-the-platform-provisioner-in-headless-mode-with-tekton-pipeline)
    * [Prerequisite](#prerequisite-1)
      * [Install tekton with tekton dashboard](#install-tekton-with-tekton-dashboard)
    * [Run the platform-provisioner in headless mode](#run-the-platform-provisioner-in-headless-mode-1)
  * [Docker image for Platform Provisioner](#docker-image-for-platform-provisioner)
<!-- TOC -->

# Platform Provisioner

Platform Provisioner is a system that can provision a platform on any cloud provider (AWS, Azure) or on-prem. It consists of the following components:
* A runtime Docker image: The docker image that contains all the supporting tools to run a pipeline with given recipe.
* Pipelines: The script that can run inside the docker image to parse and run the recipe. Normally, the pipelines encapsulate as a helm chart.
* Recipes: contains all the information to provision a platform.
* Platform Provisioner GUI: The GUI that is used to manage the recipes, pipelines, and runtime backend system. (docker for on-prem, tekton for Kubernetes)

## Get recipes from TIBCO GitHub

This repo provides some recipes to test the pipeline and cloud connection. It is located under [recipes](docs/recipes) folder.

For TIBCO Platform recipes, please see [TIBCO GitHub](https://github.com/tibco/cicinfra-devops/tree/main/recipes/cp-platform-dev/DataPlane/environments).

## Run the platform-provisioner in headless mode with docker container

The platform-provisioner can be run in headless mode with docker container. The docker container contains all the necessary tools to run the pipeline scripts.
The `platform-provisioner.sh` script will create a docker container and run the pipeline scripts with the given recipe.

### Prerequisite

* Docker installed
* Bash shell

### Run the platform-provisioner in headless mode

Go to the directory where you save the recipe and run the following command.
We need to set `GITHUB_TOKEN` to access the pipeline private repo
```bash
export GITHUB_TOKEN=""
export PIPELINE_INPUT_RECIPE=""
export PIPELINE_CHART_REPO="${GITHUB_TOKEN}@raw.githubusercontent.com/tibco/platform-provisioner/gh-pages/"
/bin/bash -c "$(curl -fsSL https://${GITHUB_TOKEN}@raw.githubusercontent.com/tibco/platform-provisioner/main/dev/platform-provisioner.sh)"
```

> [!Note]
> By default, the script will download the latest docker image from dockerhub.
> We have a pre-built docker image at [dockerhub](https://hub.docker.com/repository/docker/syantibco/platform-provisioner/general).

## Run the platform-provisioner in headless mode with tekton pipeline

The platform-provisioner can be run in headless mode with tekton installed in the target Kubernetes cluster. 
In this case, the recipe and pipeline will be scheduled by tekton and run in the target Kubernetes cluster.

### Prerequisite

* Docker installed
* Bash shell
* yq version 4 installed

#### Install tekton with tekton dashboard
```bash
export GITHUB_TOKEN=""
export PIPELINE_SKIP_TEKTON_DASHBOARD=false
export PLATFORM_PROVISIONER_PIPLINE_REPO="https://${GITHUB_TOKEN}@raw.githubusercontent.com/tibco/platform-provisioner/gh-pages/"
/bin/bash -c "$(curl -fsSL https://${GITHUB_TOKEN}@raw.githubusercontent.com/tibco/platform-provisioner/main/dev/platform-provisioner-install.sh)"
```

After the installation, we can run the following command to port-forward the tekton dashboard to local machine.
```bash
kubectl port-forward -n tekton-pipelines service/tekton-dashboard 8080:9097
```

We can now access tekton provided dashboard: http://localhost:8080

### Run the platform-provisioner in headless mode

Go to the directory where you save the recipe and run the following command
```bash
export GITHUB_TOKEN=""
export PIPELINE_INPUT_RECIPE="<path to recipe>"
/bin/bash -c "$(curl -fsSL https://${GITHUB_TOKEN}@raw.githubusercontent.com/tibco/platform-provisioner/main/dev/platform-provisioner-pipelinerun.sh)"
```

You will be able to see the running pipelinerun on Tekton Dashboard by clicking the PipelineRuns on the left.

## Docker image for Platform Provisioner

We provide a Dockerfile to build the docker image. The docker image is used to run the pipeline. It contains the necessary tools to run the pipeline scripts.

<details>
<summary>Steps to build docker image</summary>
To build docker image locally, run the following command:

```bash
cd docker
./build.sh
```

This will build the docker image called `platform-provisioner:latest`.

To build multi-arch docker image and push to remote docker registry, run the following command:

```bash
export DOCKER_REGISTRY="<your docker registry repo>"
export PUSH_DOCKER_IMAGE=true
cd docker
./build.sh
```
This will build the docker image called `<your docker registry repo>/platform-provisioner:latest` and push to remote docker registry.

</details>

> [!Note]
> For other options, please see [docker/build.sh](docker/build.sh).

