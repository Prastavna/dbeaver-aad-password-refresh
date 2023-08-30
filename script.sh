#! bin/bash

# Install azure cli for any OS if not installed
if [[ $(az --version) == "" ]]; then
  echo "Installing azure cli"
  if [[ $OSTYPE == "darwin"* ]]; then
    if [[ $(brew --version) == "" ]]; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew update && brew install azure-cli
  else
      curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
  fi
fi

# Login to azure only if not logged in
if [[ $(az account show) == "" ]]; then
    az login --allow-no-subscriptions
fi

# Get access token for oss-rdbms and extract the access token without jq
access_token=$(az account get-access-token --resource-type oss-rdbms | grep accessToken | cut -d '"' -f 4)

# ------------------------------------------------------------------------------------------------------------

path_to_dbeaver_credentials_file="$HOME/.local/share/DBeaverData/workspace6/General/.dbeaver/credentials-config.json"

if [[ $OSTYPE == "darwin"* ]]; then
    path_to_dbeaver_credentials_file="$HOME/Library/DBeaverData/workspace6/General/.dbeaver/credentials-config.json"
fi

# Variables
pass_key=babb4a9f774ab853c96c2d653dfe544a
initialization_vector=00000000000000000000000000000000

# Decrypt the file using openssl
decrypted_file=$(openssl aes-128-cbc -d -K $pass_key -iv $initialization_vector -in $path_to_dbeaver_credentials_file | dd bs=1 skip=16 2>/dev/null)

# Username for which the password needs to be updated comes from the command line
username=$1
new_password=$access_token

# Update the password of connection with username
updated_file=$(echo $decrypted_file | sed -E "s/(\"postgres-jdbc-[a-z0-9]+-[a-z0-9]+\"):(\{\"#connection\":\{\"user\":\"$username\",\"password\":\").*(\"})/\1:\2$new_password\3/g")

# Add 16 bytes of initialization vector to the updated file
_16_bytes_of_initialization_vector=$(echo -n $initialization_vector | dd bs=1 count=16 2>/dev/null)
updated_file=$(echo -n $_16_bytes_of_initialization_vector$updated_file)

# Encrypt the file using with the required skip
encrypted_file=$(openssl enc -aes-128-cbc -K $pass_key -iv $initialization_vector -in <(echo -n $updated_file) -out temp-credentials-config.json | dd bs=1 seek=16 2>/dev/null)

# move the encrypted file to the required location
mv temp-credentials-config.json $path_to_dbeaver_credentials_file

