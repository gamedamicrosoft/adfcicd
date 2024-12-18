#!/bin/bash

replace_placeholders() {
    local input_file=$1
    local temp_file=$(mktemp)

    # Copy the input file to a temporary file
    cp "$input_file" "$temp_file"

    # Debug: Check file contents before replacement
    echo "Debug: Input JSON file before placeholder replacement:" >&2
    cat "$temp_file" >&2

    # Find and replace placeholders
    PLACEHOLDERS=$(grep -oE '@@[A-Z0-9_]+@@' "$temp_file" | sort -u)
    for placeholder in $PLACEHOLDERS; do
        # Extract the variable name without @@
        env_var_name=$(echo "$placeholder" | sed 's/^@@//; s/@@$//')

        # Fetch the environment variable value
        env_var_value="${!env_var_name}"

        # Check if the environment variable exists
        if [ -z "$env_var_value" ]; then
            echo "Error: Environment variable '$env_var_name' is not set!"
            exit 1
        fi

        # Debug: Show what is being replaced
        echo "Replacing $placeholder with $env_var_value" >&2

        # Replace placeholder with the environment variable value in the file
        sed -i '' "s|$placeholder|$env_var_value|g" "$temp_file"
    done

    # Validate JSON structure
    echo "Debug: JSON after replacement:">&2
    cat "$temp_file">&2

    if ! jq empty "$temp_file" > /dev/null 2>&1; then
        echo "Error: $temp_file is not valid JSON!"
        #cat "$temp_file"
        exit 1
    fi

    echo "$temp_file"
}

# Set the required environment variables
export KEYVAULT_BASEURL="https://gameda-kv1.vault.azure.net/"

# Call the function with the input file
PROCESSED_FILE=$(replace_placeholders ../adf/linkedServices/0_AzureKeyVault1.json)

# Extract the properties field
PROPERTIES=$(jq '.properties' "$PROCESSED_FILE")
echo "PROPERTIES = $PROPERTIES"