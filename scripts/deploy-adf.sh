#!/bin/bash

#!/bin/bash

# Variables (passed as environment variables)
RESOURCE_GROUP=${RESOURCE_GROUP:?RESOURCE_GROUP is not set}
ADF_NAME=${ADF_NAME:?ADF_NAME is not set}
ASSETS_DIR=${ASSETS_DIR:-"../adf"}  # Default to "../adf" if ASSETS_DIR is not set

# Azure Login using Service Principal
echo "Logging in to Azure using Service Principal..."
az login --service-principal \
    --username "$AZURE_CLIENT_ID" \
    --password "$AZURE_CLIENT_SECRET" \
    --tenant "$AZURE_TENANT_ID"

az account set --subscription "$AZURE_SUBSCRIPTION_ID"
echo "Azure CLI Login Successful!"

# Function to replace placeholders with environment variables in a file
replace_placeholders() {
    local input_file=$1
    local temp_file=$(mktemp)
    cp "$input_file" "$temp_file"

    # Find all placeholders in the file
    PLACEHOLDERS=$(grep -oP '@@\K[A-Z0-9_]+(?=@@)' "$temp_file" | sort -u)

    # Replace placeholders with corresponding environment variables
    for placeholder in $PLACEHOLDERS; do
        env_var_value="${!placeholder}"
        if [ -z "$env_var_value" ]; then
            echo "Error: Environment variable '$placeholder' is not set but required in $input_file."
            exit 1  # Exit with an error if the environment variable is not defined
        fi
        echo "Replacing @@$placeholder@@ with $env_var_value in $input_file"
        sed -i "s|@@$placeholder@@|$env_var_value|g" "$temp_file"
    done

    echo "$temp_file"  # Return the path to the temporary file
}

echo "Starting deployment of Azure Data Factory assets..."

# Deploy Linked Services
echo "Deploying Linked Services..."
for file in $ASSETS_DIR/linkedServices/*.json; do
    LINKED_SERVICE_NAME=$(basename "$file" .json)
    echo "Processing Linked Service: $LINKED_SERVICE_NAME"

    PROCESSED_FILE=$(replace_placeholders "$file")
    PROPERTIES=$(jq '.properties' "$PROCESSED_FILE")

    az datafactory linked-service create \
        --resource-group "$RESOURCE_GROUP" \
        --factory-name "$ADF_NAME" \
        --linked-service-name "$LINKED_SERVICE_NAME" \
        --properties "$PROPERTIES" \
        --only-show-errors

    rm "$PROCESSED_FILE"
done

# Deploy Datasets
echo "Deploying Datasets..."
for file in $ASSETS_DIR/datasets/*.json; do
    DATASET_NAME=$(basename "$file" .json)
    echo "Processing Dataset: $DATASET_NAME"

    PROCESSED_FILE=$(replace_placeholders "$file")
    PROPERTIES=$(jq '.properties' "$PROCESSED_FILE")

    az datafactory dataset create \
        --resource-group "$RESOURCE_GROUP" \
        --factory-name "$ADF_NAME" \
        --name "$DATASET_NAME" \
        --properties "$PROPERTIES" \
        --only-show-errors

    rm "$PROCESSED_FILE"
done

# Deploy Pipelines
echo "Deploying Pipelines..."
for file in $ASSETS_DIR/pipelines/*.json; do
    PIPELINE_NAME=$(basename "$file" .json)
    echo "Processing Pipeline: $PIPELINE_NAME"

    PROCESSED_FILE=$(replace_placeholders "$file")
    az datafactory pipeline create \
        --resource-group "$RESOURCE_GROUP" \
        --factory-name "$ADF_NAME" \
        --pipeline-name "$PIPELINE_NAME" \
        --pipeline "@$PROCESSED_FILE" \
        --only-show-errors

    rm "$PROCESSED_FILE"
done

# Deploy Triggers
echo "Deploying Triggers..."
for file in $ASSETS_DIR/triggers/*.json; do
    TRIGGER_NAME=$(basename "$file" .json)
    echo "Processing Trigger: $TRIGGER_NAME"

    PROCESSED_FILE=$(replace_placeholders "$file")
    PROPERTIES=$(jq '.properties' "$PROCESSED_FILE")

    az datafactory trigger create \
        --resource-group "$RESOURCE_GROUP" \
        --factory-name "$ADF_NAME" \
        --trigger-name "$TRIGGER_NAME" \
        --properties "$PROPERTIES" \
        --only-show-errors

    rm "$PROCESSED_FILE"
done

echo "ADF deployment complete!"