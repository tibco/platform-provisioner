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



