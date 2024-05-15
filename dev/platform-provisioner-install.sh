#!/bin/bash

#
# © 2024 Cloud Software Group, Inc.
# All Rights Reserved. Confidential & Proprietary.
#

#######################################
# platform-provisioner-install.sh: this will deploy all supporting components for Platform Provisioner in headless mode with tekton pipeline
# Globals:
#   PIPLINE_GUI_DOCKER_IMAGE_REPO: the ECR repo to pull Platform Provisioner images
#   PIPLINE_GUI_DOCKER_IMAGE_USERNAME: the username for ECR to pull Platform Provisioner images
#   PIPLINE_GUI_DOCKER_IMAGE_TOKEN: the read-only token for ECR to pull Platform Provisioner images
#   PIPLINE_NAMESPACE: the namespace to deploy the pipeline and provisioner GUI
#   PLATFORM_PROVISIONER_PIPLINE_REPO: the repo to pull the pipeline and provisioner GUI helm charts
#   PIPELINE_DOCKER_IMAGE: the docker image for the pipeline
#   PIPELINE_SKIP_PROVISIONER_UI: true or other string if true, will skip installing platform-provisioner GUI
#   PIPELINE_SKIP_TEKTON_DASHBOARD: true or other string if true, will skip installing tekton dashboard
# Arguments:
#   None
# Returns:
#   0 if thing was deleted, non-zero on error
# Notes:
#   None
# Samples:
#    export PIPLINE_GUI_DOCKER_IMAGE_TOKEN="your-ecr-token"
#    export PIPLINE_GUI_DOCKER_IMAGE_REPO="your-ecr-repo"
#   ./platform-provisioner-install.sh
#######################################

[[ -z "${PIPELINE_DOCKER_IMAGE}" ]] && export PIPELINE_DOCKER_IMAGE=${PIPELINE_DOCKER_IMAGE:-"syantibco/platform-provisioner:latest"}
[[ -z "${PIPELINE_SKIP_PROVISIONER_UI}" ]] && export PIPELINE_SKIP_PROVISIONER_UI=${PIPELINE_SKIP_PROVISIONER_UI:-true}
[[ -z "${PIPELINE_SKIP_TEKTON_DASHBOARD}" ]] && export PIPELINE_SKIP_TEKTON_DASHBOARD=${PIPELINE_SKIP_TEKTON_DASHBOARD:-true}
[[ -z "${TEKTON_PIPELINE_RELEASE}" ]] && export TEKTON_PIPELINE_RELEASE=${TEKTON_PIPELINE_RELEASE:-"v0.59.0"}
[[ -z "${TEKTON_DASHBOARD_RELEASE}" ]] && export TEKTON_DASHBOARD_RELEASE=${TEKTON_DASHBOARD_RELEASE:-"v0.46.0"}

if [[ ${PIPELINE_SKIP_PROVISIONER_UI} == "false" ]]; then
  # your ECR read-only token
  if [[ -z ${PIPLINE_GUI_DOCKER_IMAGE_TOKEN} ]]; then
    echo "PIPLINE_GUI_DOCKER_IMAGE_TOKEN is not set"
    exit 1
  fi

  if [[ -z ${PIPLINE_GUI_DOCKER_IMAGE_REPO} ]]; then
    echo "PIPLINE_GUI_DOCKER_IMAGE_REPO is not set"
    exit 1
  fi
  [[ -z "${PIPLINE_GUI_DOCKER_IMAGE_USERNAME}" ]] && export PIPLINE_GUI_DOCKER_IMAGE_USERNAME=${PIPLINE_GUI_DOCKER_IMAGE_USERNAME:-"AWS"}
fi

# The tekton version to install
kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/previous/${TEKTON_PIPELINE_RELEASE}/release.yaml

if [[ ${PIPELINE_SKIP_TEKTON_DASHBOARD} != "true" ]]; then
  echo "#### installing tekton dashboard"
  kubectl apply --filename https://storage.googleapis.com/tekton-releases/dashboard/previous/${TEKTON_DASHBOARD_RELEASE}/release.yaml
fi

kubectl create namespace tekton-tasks

echo "waiting for tekton to be ready..."
_DEPLOYMENT_NAME="tekton-pipelines-controller"
_TIMEOUT="120s"
kubectl wait --for=condition=available -n tekton-pipelines "deployment/${_DEPLOYMENT_NAME}" --timeout=${_TIMEOUT}
if [ $? -ne 0 ]; then
  echo "Timeout: Deployment '${_DEPLOYMENT_NAME}' did not become available within ${_TIMEOUT}."
  exit 1
else
  echo "Deployment '${_DEPLOYMENT_NAME}' is now ready."
fi

# create service account for this pipeline
kubectl create -n tekton-tasks serviceaccount pipeline-cluster-admin
kubectl create clusterrolebinding pipeline-cluster-admin --clusterrole=cluster-admin --serviceaccount=tekton-tasks:pipeline-cluster-admin

export PLATFORM_PROVISIONER_PIPLINE_REPO=${PLATFORM_PROVISIONER_PIPLINE_REPO:-"https://tibcosoftware.github.io/platform-provisioner"}
export PIPLINE_NAMESPACE=${PIPLINE_NAMESPACE:-"tekton-tasks"}

# install a sample pipeline with docker image that can run locally
helm upgrade --install -n "${PIPLINE_NAMESPACE}" common-dependency common-dependency \
  --version ^1.0.0 --repo "${PLATFORM_PROVISIONER_PIPLINE_REPO}"

helm upgrade --install -n "${PIPLINE_NAMESPACE}" generic-runner generic-runner \
  --version ^1.0.0 --repo "${PLATFORM_PROVISIONER_PIPLINE_REPO}" \
  --set serviceAccount=pipeline-cluster-admin \
  --set pipelineImage="${PIPELINE_DOCKER_IMAGE}"

helm upgrade --install -n "${PIPLINE_NAMESPACE}" helm-install helm-install \
  --version ^1.0.0 --repo "${PLATFORM_PROVISIONER_PIPLINE_REPO}" \
  --set serviceAccount=pipeline-cluster-admin \
  --set pipelineImage="${PIPELINE_DOCKER_IMAGE}"

# install provisioner config
helm upgrade --install -n "${PIPLINE_NAMESPACE}" provisioner-config-local provisioner-config-local \
  --version ^1.0.0 --repo "${PLATFORM_PROVISIONER_PIPLINE_REPO}"

# create secret for pulling images from ECR
if [[ ${PIPELINE_SKIP_PROVISIONER_UI} == "true" ]]; then
  echo "### skip installing platform-provisioner GUI"
  exit 0
fi

_image_pull_secret_name="platform-provisioner-ui-image-pull"
if kubectl get secret -n "${PIPLINE_NAMESPACE}" ${_image_pull_secret_name} > /dev/null 2>&1; then
  kubectl delete secret -n "${PIPLINE_NAMESPACE}" ${_image_pull_secret_name}
fi
kubectl create secret docker-registry -n "${PIPLINE_NAMESPACE}" ${_image_pull_secret_name} \
  --docker-server="${PIPLINE_GUI_DOCKER_IMAGE_REPO}" \
  --docker-username="${PIPLINE_GUI_DOCKER_IMAGE_USERNAME}" \
  --docker-password="${PIPLINE_GUI_DOCKER_IMAGE_TOKEN}"

# install provisioner web ui
helm upgrade --install -n "${PIPLINE_NAMESPACE}" platform-provisioner-ui platform-provisioner-ui --repo "${PLATFORM_PROVISIONER_PIPLINE_REPO}" \
  --version ^1.0.0 \
  --set image.repository="${PIPLINE_GUI_DOCKER_IMAGE_REPO}"/stratosphere/cic2-provisioner-webui \
  --set image.tag=latest \
  --set "imagePullSecrets[0].name=${_image_pull_secret_name}" \
  --set guiConfig.onPremMode=true \
  --set guiConfig.pipelinesCleanUpEnabled=true \
  --set guiConfig.dataConfigMapName="provisioner-config-local-config"
