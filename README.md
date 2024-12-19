# Directory Structure
```shell
/
├── adf/                        # Azure Data Factory Assets
│   ├── datasets/               # Datasets used in ADF
│   │   ├── dataset1.json
│   │   ├── dataset2.json
│   ├── linkedServices/         # Linked services for connecting to sources
│   │   ├── linkedService1.json
│   │   ├── linkedService2.json
│   ├── pipelines/              # ADF pipelines (separated for modularity)
│   │   ├── ingestionPipeline.json
│   │   ├── transformationPipeline.json
│   │   ├── loadPipeline.json
│   ├── triggers/               # Triggers for pipeline scheduling
│   │   ├── trigger1.json
│   │   ├── trigger2.json
│   ├── globalParameters.json   # Optional: Global parameters shared across pipelines
│   ├── arm-template/           # ARM templates for deployment
│       ├── arm-template.json
│       ├── arm-template-parameters.json
├── databricks/                 # Databricks Notebooks and Libraries
│   ├── notebooks/              # Notebooks for different tasks
│   │   ├── 01-ingestion.py
│   │   ├── 02-transformation.py
│   │   ├── 03-load.py
│   │   ├── utils/              # Utility notebooks
│   │       ├── helper_functions.py
│   ├── libraries/              # Python libraries (shared reusable code)
│   │   ├── data_validation.py
│   │   ├── transformation_utils.py
│   ├── jobs/                   # Databricks job definitions
│   │   ├── job1.json
│   │   ├── job2.json
├── infrastructure/             # Infrastructure-as-code (IaC)
│   ├── bicep/                  # Optional: Azure Bicep templates
│   │   ├── adf.bicep
│   │   ├── databricks.bicep
│   ├── terraform/              # Optional: Terraform templates
│       ├── main.tf
│       ├── variables.tf
├── scripts/                    # Helper scripts (CI/CD, deployment, testing)
│   ├── deploy-adf.sh           # Script for deploying ADF pipelines
│   ├── deploy-databricks.sh    # Script for deploying Databricks notebooks
│   ├── ci_cd_pipeline.yml      # CI/CD pipeline (e.g., GitHub Actions or Azure DevOps)
├── .gitignore                  # Ignore unnecessary files (e.g., logs, checkpoints)
├── README.md                   # Documentation for the repository
```

# Key Components
## 1. `adf/` folder
 Contains all Azure Data Factory assets, exported as JSON files:
- `datasets/`: Definitions of datasets (e.g., Blob storage, SQL tables).
- `linkedServices/`: Definitions of connections (e.g., Azure Blob, Azure SQL).
- `pipelines/`: Modular ADF pipelines (ingestion, transformation, etc.).
- `triggers/`: Triggers for scheduling pipelines.
- `arm-template/`: Templates for deploying ADF resources via ARM.

## 2. `databricks/` folder
Contains all Databricks-related assets:
- `notebooks/`: Python scripts or notebooks for ingestion, transformation, and loading data.
- `libraries/`: Shared reusable Python code (e.g., validation, transformations).
- `jobs/`: Databricks job definitions (JSON files with job configurations).

## 3. `infrastructure/` folder
Optional folder for managing infrastructure with IaC tools:
- Azure Bicep or Terraform templates for creating Azure resources like:
- ADF instance
- Databricks workspace
- Storage accounts
- Key Vault

## 4. `scripts/` folder
Contains helper scripts for automation:
- Deployment scripts: Automate the deployment of ADF pipelines and Databricks notebooks.
- CI/CD pipelines: Define workflows for GitHub Actions or Azure DevOps.

```shell
az ad sp create-for-rbac --name "devops-adf-deployment" --role "Contributor" --scopes "/subscriptions/f4230a8b-54a3-4f2b-bf91-9e4e6ba3320b
```

```shell
"storage_account_key": "@Microsoft.KeyVault(SecretUri=https://<key-vault-name>.vault.azure.net/secrets/<secret-name>/)"
```