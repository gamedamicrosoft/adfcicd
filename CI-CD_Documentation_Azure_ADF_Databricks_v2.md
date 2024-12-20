
# CI/CD Pipeline Documentation for Azure Data Factory and Databricks

This document outlines the CI/CD pipeline implementation for automating deployments to Azure Data Factory (ADF) and Databricks using **Azure Pipelines** and **GitHub Actions**.

---

## Objectives

The objective of the CI/CD pipelines is to enable streamlined and automated deployment processes for Azure Data Factory assets (pipelines, datasets, linked services, and triggers) and Databricks notebooks to respective environments based on branch-based triggers.

### Key Features:
1. **Branch-Based Environment Selection**: The environment is selected dynamically based on the branch to which code is pushed (e.g., `main`, `qa`).
2. **Environment Variables and Secrets Management**:
    - Azure Pipelines: Using **Variable Groups** for securely managing environment-specific variables.
    - GitHub Actions: Utilizing **Environment Variables** and **Secrets** for secure and dynamic configurations.
3. **Placeholder Replacement**: A strategy to replace placeholders in ADF JSON files with actual environment variables before deployment.
4. **Simple and Scalable Workflow**: Enable users to draft pipelines in the ADF UI and deploy by copying the JSON to respective directories.
5. **Error Handling**: Includes checks to ensure the validity of environment variables and JSON files before deployment.

---

## Implementation Details

### Azure Pipelines

#### Pipeline Configuration

The Azure Pipelines implementation uses:
- A **trigger** to monitor branches (`main` and `qa`).
- Environment-specific configurations are managed using **Variable Groups**.
- A two-stage pipeline: 
    1. Deploy Databricks Notebooks.
    2. Deploy ADF assets.

#### YAML Configuration

```yaml
trigger:
  - main
  - qa

pool:
  vmImage: ubuntu-latest

variables:
  - ${{ if eq(variables['Build.SourceBranchName'], 'main') }}:
      - group: AZURE-CLI
  - ${{ if eq(variables['Build.SourceBranchName'], 'qa') }}:
      - group: AZURE-CLI-QA

stages:
  - stage: Deploy_Databricks_Notebooks
    ...
  - stage: Deploy_ADF
    ...
```

#### Key Highlights:
1. **Variable Groups**: `AZURE-CLI` and `AZURE-CLI-QA` define environment-specific variables.
2. **Databricks Deployment**:
    - Configure Databricks CLI using `DATABRICKS_HOST` and `DATABRICKS_TOKEN`.
    - Deploy notebooks using `databricks workspace import_dir`.
3. **ADF Deployment**:
    - Deploy JSON files for linked services, datasets, pipelines, and triggers.
    - Use the `deploy-adf.sh` script with placeholder replacement.

#### Example: Placeholder Replacement
The following script replaces placeholders (e.g., `@@RESOURCE_GROUP@@`) in ADF JSON files:

```bash
replace_placeholders() {
    local input_file=$1
    local temp_file=$(mktemp)

    cp "$input_file" "$temp_file"

    SED_COMMAND="sed -i"  # Adjust for macOS if needed

    PLACEHOLDERS=$(grep -oE '@@[A-Z0-9_]+@@' "$temp_file" | sort -u)
    for placeholder in $PLACEHOLDERS; do
        env_var_name=$(echo "$placeholder" | sed 's/^@@//; s/@@$//')
        env_var_value="${!env_var_name}"

        if [ -z "$env_var_value" ]; then
            echo "Error: Environment variable '$env_var_name' is not set!" >&2
            exit 1
        fi

        $SED_COMMAND "s|$placeholder|$env_var_value|g" "$temp_file"
    done

    echo "$temp_file"
}
```

---

### GitHub Actions

#### Workflow Configuration

The GitHub Actions workflow includes two jobs:
1. Deploy Databricks Notebooks.
2. Deploy ADF assets.

#### YAML Configuration

```yaml
name: Deploy ADF and Databricks

on:
  push:
    branches:
      - main
      - qa

jobs:
  deploy-databricks-notebooks:
    ...
  deploy-adf-assets:
    ...
```

#### Key Highlights:
1. **Branch-Based Environment Selection**: Dynamically determines the environment (e.g., `dev`, `qa`, `prod`) based on the branch.
2. **Secrets Management**: Utilizes GitHub Secrets (e.g., `DATABRICKS_TOKEN`, `AZURE_CLIENT_SECRET`) for secure configurations.

---

### ADF Deployment Workflow

#### Steps for Users
1. Design pipelines in the ADF UI.
2. Export JSON for pipelines, datasets, linked services, and triggers.
3. Copy the JSON files to the appropriate folders (`adf/pipelines`, `adf/datasets`, etc.).
4. Trigger the CI/CD pipeline for deployment.

#### Deploy Script: `deploy-adf.sh`
The `deploy-adf.sh` script automates the deployment of ADF assets by:
1. Authenticating to Azure using a Service Principal.
2. Replacing placeholders in JSON files.
3. Deploying linked services, datasets, pipelines, and triggers using the Azure CLI.

Example Command:
```bash
az datafactory pipeline create     --resource-group "$RESOURCE_GROUP"     --factory-name "$ADF_NAME"     --pipeline-name "$PIPELINE_NAME"     --pipeline "@$PROCESSED_FILE"
```

---

## Example Scenarios

### Deploy Notebooks to Databricks
1. A user pushes changes to the `main` branch.
2. The pipeline triggers the `Deploy Databricks Notebooks` stage.
3. The notebooks from `databricks/notebooks` are deployed to the specified Databricks workspace.

### Deploy ADF Assets
1. JSON files are added to the `adf` directory.
2. The `deploy-adf.sh` script is executed, which:
    - Replaces placeholders with environment variables.
    - Validates JSON files.
    - Deploys assets to ADF.

---

## Error Handling and Validation

1. **Environment Variables Validation**:
    - Ensures all required variables are set.
    - Provides detailed error messages if variables are missing.

2. **JSON Validation**:
    - Validates JSON structure using the `jq` tool before deployment.

3. **Deployment Logs**:
    - Outputs detailed logs for each deployment step.
    - Highlights errors and warnings.

---

## Environment Variables

The table below summarizes all the environment variables used in the pipelines, their descriptions, sources, and usage.

---
<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">
  <thead>
    <tr>
      <th>Category</th>
      <th>Environment Variable</th>
      <th>Description</th>
      <th>Value Source</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td rowspan="4">AZURE CLI related variables which will be used ADF deployment <code>az datafactory</code> commands</td>
      <td>AZURE_CLIENT_ID</td>
      <td>Client ID of the Azure Service Principal.</td>
      <td rowspan="4"><code>az ad sp create-for-rbac --name "devops-adf-deployment" --role "Contributor" --scopes "/subscriptions/$subscription-id</code></td>
    </tr>
    <tr>
      <td>AZURE_CLIENT_SECRET</td>
      <td>Secret of the Azure Service Principal.</td>
    </tr>
    <tr>
      <td>AZURE_TENANT_ID</td>
      <td>Azure Active Directory tenant ID.</td>
    </tr>
    <tr>
      <td>AZURE_SUBSCRIPTION_ID</td>
      <td>Azure subscription ID for deployment.</td>
    </tr>
    <tr>
      <td rowspan="3">Databricks Deployment Related</td>
      <td>DATABRICKS_TOKEN</td>
      <td>Personal access token for Databricks.</td>
      <td>Generate from Databricks UI under User Settings > Access Tokens.</td>
    </tr>
    <tr>
      <td>DATABRICKS_URL</td>
      <td>Host URL of the Databricks workspace. (without https://)</td>
      <td>Use the Databricks workspace URL (e.g.,<code>adb-XXXXXX.X.azuredatabricks.net</code>).</td>
    </tr>
    <tr>
      <td>DATABRICKS_CLUSTER_ID</td>
      <td>ID of the Databricks cluster used for execution.</td>
      <td>Fetched from the Databricks UI under <code>Clusters > Cluster Details</code>.</td>
    </tr>
    <tr>
      <td rowspan="4">ADF deployment related</td>
      <td>RESOURCE_GROUP</td>
      <td>Azure Resource Group</td>
    </tr>
    <tr>
      <td>ADF_NAME</td>
      <td>Azure Data Factory Name</td>
    </tr>
    <tr>
      <td>ASSETS_DIR</td>
      <td>Directory for ADF JSON Files</td>
      <td>Pipeline Default</td>
    </tr>
    <tr>
      <td>KEYVAULT_BASEURL</td>
      <td>URL of the Azure Key Vault used for secrets management. eg. <code>https://XXXXXX.vault.azure.net/</code></td>
      <td>Defined as a variable or fetched from Azure Key Vault during the pipeline execution.</td>
    </tr>
  </tbody>
</table>

## Conclusion

This CI/CD process ensures consistent and secure deployments to Azure Data Factory and Databricks across environments. It leverages Azure Pipelines and GitHub Actions for automation, making the process robust and scalable.

For further questions or enhancements, contact the DevOps team.
