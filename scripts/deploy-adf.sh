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

    # Copy the input file to a temporary file
    cp "$input_file" "$temp_file"

    # OS-specific sed command
    if [[ "$OSTYPE" == "darwin"* ]]; then
        SED_COMMAND="sed -i ''"
    else
        SED_COMMAND="sed -i"
    fi

    # Find and replace placeholders
    PLACEHOLDERS=$(grep -oE '@@[A-Z0-9_]+@@' "$temp_file" | sort -u)
    for placeholder in $PLACEHOLDERS; do
        # Extract the variable name without @@
        env_var_name=$(echo "$placeholder" | sed 's/^@@//; s/@@$//')

        # Fetch the environment variable value
        env_var_value="${!env_var_name}"

        # Check if the environment variable exists
        if [ -z "$env_var_value" ]; then
            echo "Error: Environment variable '$env_var_name' is not set!" >&2
            exit 1
        fi

        # Replace placeholder with environment variable
        $SED_COMMAND "s|$placeholder|$env_var_value|g" "$temp_file"
    done

    # Validate JSON structure
    if ! jq empty "$temp_file" > /dev/null 2>&1; then
        echo "Error: $temp_file is not valid JSON!" >&2
        exit 1
    fi

    # Return the temp file path
    echo "$temp_file"
}






echo "Starting deployment of Azure Data Factory assets..."

# Deploy Linked Services
echo "Deploying Linked Services..."
for file in $ASSETS_DIR/linkedServices/*.json; do
    LINKED_SERVICE_NAME=$(basename "$file" .json)
    echo "Processing Linked Service: $LINKED_SERVICE_NAME"
    if [ ! -f "$file" ]; then
        echo "Error: File $file not found!"
        exit 1
    fi

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