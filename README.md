# Helm Charts for TIBCO® Platform Provisioner
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

Helm Charts for TIBCO® Platform Provisioner contains a list of helm charts for TIBCO Platform Provisioner components.

## Introduction
TIBCO Platform Provisioner provides a system that can provision a platform on any cloud provider (AWS, Azure) or on-prem. It consists of the following components:
* A runtime Docker image: The docker image that contains all the supporting tools to run a pipeline with given recipe.
* Pipelines: The script that can run inside the docker image to parse and run the recipe. Normally, the pipelines encapsulate as a helm chart.
* Recipes: contains all the information to provision a platform.
* Platform Provisioner GUI: The GUI that is used to manage the recipes, pipelines, and runtime backend system. (docker for on-prem, tekton for Kubernetes)
