#!/bin/bash

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

# Set the required environment variables
export KEYVAULT_BASEURL="https://gameda-kv1.vault.azure.net/"

# Call the function with the input file
PROCESSED_FILE=$(replace_placeholders ../adf/linkedServices/0_AzureKeyVault1.json)

# Extract the properties field
PROPERTIES=$(jq '.properties' "$PROCESSED_FILE")
echo "PROPERTIES = $PROPERTIES"