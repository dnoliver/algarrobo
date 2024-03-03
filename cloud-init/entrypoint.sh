#!/bin/sh

# Check CLOUD_INIT_USERNAME variable
if [ -z "$CLOUD_INIT_USERNAME" ];
then
    echo "CLOUD_INIT_USERNAME is not set"
    exit 1
else
    echo "CLOUD_INIT_USERNAME is set to '$CLOUD_INIT_USERNAME'"
fi

# Check CLOUD_INIT_PASSWORD variable
if [ -z "$CLOUD_INIT_PASSWORD" ];
then
    echo "CLOUD_INIT_PASSWORD is not set"
    exit 1
else
    echo "CLOUD_INIT_PASSWORD is set to '$CLOUD_INIT_PASSWORD'"
    
    # Encrypt the password
    CLOUD_INIT_PASSWORD_ENCRYPTED=$(mkpasswd "$CLOUD_INIT_PASSWORD")

    # Export encrypted password to CLOUD_INIT_PASSWORD_ENCRYPTED environment variable
    export CLOUD_INIT_PASSWORD_ENCRYPTED
fi

# Check CLOUD_INIT_HOSTNAME variable
if [ -z "$CLOUD_INIT_HOSTNAME" ];
then
    echo "CLOUD_INIT_HOSTNAME is not set";
    exit 1
else
    echo "CLOUD_INIT_HOSTNAME is set to '$CLOUD_INIT_HOSTNAME'";
fi

# Replace variables in user-data template
envsubst  < ./template/user-data > ./www/user-data

# Replace variables in meta-data template
envsubst  < ./template/meta-data > ./www/meta-data

# Download image if it don't exists
ISO_DOWNLOAD_LOCATION="./nfs/ubuntu-22.04.4-live-server-amd64.iso"
if [ -f "$ISO_DOWNLOAD_LOCATION" ];
then
    echo "Operating system image present at '$ISO_DOWNLOAD_LOCATION'"
else
    echo "Downloading operating system image to '$ISO_DOWNLOAD_LOCATION'"
    curl \
        -o "$ISO_DOWNLOAD_LOCATION" \
        https://releases.ubuntu.com/releases/jammy/ubuntu-22.04.4-live-server-amd64.iso
fi

# Create seed from templates
OUTPUT="${SEED_LOCATION:-./nfs/seed.iso}"
if [ -f "$OUTPUT" ];
then
    echo "Operating system seed present at '$OUTPUT'"
else
    echo "Creating operating system seed at '$OUTPUT'"
    cloud-localds "$OUTPUT" ./www/user-data ./www/meta-data
fi

# Exec command
exec "$@"
