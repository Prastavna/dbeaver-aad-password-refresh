#! bin/bash

# This script decrypts the dbeaver credentials file and then updates it with the new password and re-encrypts it.

path_to_dbeaver_credentials_file="$HOME/.local/share/DBeaverData/workspace6/General/.dbeaver/credentials-config.json"

if [[ $OSTYPE == "darwin"* ]]; then
    path_to_dbeaver_credentials_file="$HOME/Library/DBeaverData/workspace6/General/.dbeaver/credentials-config.json"
fi

# Variables
pass_key=babb4a9f774ab853c96c2d653dfe544a
initialization_vector=00000000000000000000000000000000

# Decrypt the file using openssl
decrypted_file=$(openssl aes-128-cbc -d -K $pass_key -iv $initialization_vector -in $path_to_dbeaver_credentials_file | dd bs=1 skip=16 2>/dev/null)

new_password=123567

# Sample output of decrypted file: {"postgres-jdbc-18a4199bb55-600e2ae54ff4ee5a":{"#connection":{"user":"postgres","password":"123567"}}}
# Update the password of connection with user as postgres

updated_file=$(echo $decrypted_file | sed -E "s/(\"postgres-jdbc-[a-z0-9]+-[a-z0-9]+\"):(\{\"#connection\":\{\"user\":\"postgres\",\"password\":\")([a-z0-9]+)(\"}}\})/\1:\2$new_password\4/g")

# Add 16 bytes of initialization vector to the updated file
_16_bytes_of_initialization_vector=$(echo -n $initialization_vector | dd bs=1 count=16 2>/dev/null)
echo $_16_bytes_of_initialization_vector
updated_file=$(echo -n $_16_bytes_of_initialization_vector$updated_file)

echo $updated_file

# Encrypt the file using with the required skip
encrypted_file=$(openssl enc -aes-128-cbc -K $pass_key -iv $initialization_vector -in <(echo -n $updated_file) -out credentials-config.json | dd bs=1 seek=16 2>/dev/null)

xxd credentials-config.json

# decrypt the local file
echo $(openssl aes-128-cbc -d -K $pass_key -iv $initialization_vector -in credentials-config.json | dd bs=1 skip=16 2>/dev/null)

# remove the unencrypted file
# rm credentials-config.json

# move the encrypted file to the required location
mv credentials-config.json $path_to_dbeaver_credentials_file






