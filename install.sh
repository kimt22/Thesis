#!/bin/bash

# File containing package names in the specified order
ORDER_FILE="topo_order.txt"

# Metadata file containing package information
METADATA_FILE="Packages"

# Base path for the mounted APT mirror
MOUNT_DIR="/mnt/mirror/archive.ubuntu.com/ubuntu"

# Check if the order file exists
if [[ ! -f $ORDER_FILE ]]; then
    echo "Order file not found: $ORDER_FILE"
    exit 1
fi

# Check if the metadata file exists
if [[ ! -f $METADATA_FILE ]]; then
    echo "Metadata file not found: $METADATA_FILE"
    exit 1
fi

# Read the package names from the order file and process each package
while IFS= read -r package; do
    if [[ ! -z "$package" ]]; then  # Check if the line is not empty
        echo "Processing package: $package"

        # Extract the filename information from the metadata file, ensuring an exact match of the package name
        FILENAME=$(awk -v pkg="$package" '/^Package: /{p=0} /^Package: '"$package"'$/{p=1} p && /^Filename: /{print $2; exit}' "$METADATA_FILE")

        if [[ ! -z "$FILENAME" ]]; then
            # Construct the full path to the .deb file using the extracted filename
            DEB_PATH="$MOUNT_DIR/$FILENAME"

            # Check if the .deb file exists at the constructed path
            if [[ -f "$DEB_PATH" ]]; then
                echo "Installing package from: $DEB_PATH"
                sudo dpkg -i "$DEB_PATH"
            else
                echo "The .deb file not found at: $DEB_PATH"
            fi
        else
            echo "Filename not found in metadata for: $package"
        fi
    fi
done < "$ORDER_FILE"
