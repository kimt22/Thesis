#!/bin/bash

# Function to check if OpenStack RC file is sourced
function check_openstack_credentials {
    if [ -z "$OS_AUTH_URL" ]; then
        echo "Please source your OpenStack RC file to set environment variables."
        exit 1
    fi
}

# Function to create a keypair
function create_keypair {
    TAG=$1
    KEYPAIR_NAME="${TAG}_keypair"

    if ! openstack keypair show "$KEYPAIR_NAME" &>/dev/null; then
        openstack keypair create --private-key "${KEYPAIR_NAME}.pem" "$KEYPAIR_NAME"
        chmod 600 "${KEYPAIR_NAME}.pem"
        echo "Keypair '$KEYPAIR_NAME' created and saved to ${KEYPAIR_NAME}.pem"
    else
        echo "Keypair '$KEYPAIR_NAME' already exists."
    fi
}

# Function to create network
function create_network {
    TAG=$1
    NETWORK_NAME="${TAG}_network"
    openstack network create "$NETWORK_NAME"
    echo "Network '$NETWORK_NAME' created."
}

# Function to create subnet
function create_subnet {
    TAG=$1
    SUBNET_NAME="${TAG}_subnet"
    NETWORK_NAME="${TAG}_network"
    SUBNET_RANGE="192.168.100.0/24"  # You can change this to suit your setup
    openstack subnet create --network "$NETWORK_NAME" --subnet-range "$SUBNET_RANGE" "$SUBNET_NAME"
    echo "Subnet '$SUBNET_NAME' created with range $SUBNET_RANGE."
}

# Function to create a router
function create_router {
    TAG=$1
    ROUTER_NAME="${TAG}_router"
    openstack router create "$ROUTER_NAME"
    echo "Router '$ROUTER_NAME' created."

    # Set external gateway for the router
    EXTERNAL_NETWORK=$(openstack network list --external -c Name -f value | head -n 1)
    openstack router set --external-gateway "$EXTERNAL_NETWORK" "$ROUTER_NAME"
    echo "Router '$ROUTER_NAME' is set with external gateway: $EXTERNAL_NETWORK."

    # Add subnet to the router
    SUBNET_NAME="${TAG}_subnet"
    openstack router add subnet "$ROUTER_NAME" "$SUBNET_NAME"
    echo "Router '$ROUTER_NAME' connected to subnet '$SUBNET_NAME'."
}

# Function to allocate a floating IP
function allocate_floating_ip {
    FLOATING_IP=$(openstack floating ip create -f value -c floating_ip_address $(openstack network list --external -c Name -f value | head -n 1))
    echo "$FLOATING_IP"
}

# Function to launch a VM
function launch_instance {
    TAG=$1
    IMAGE_ID=$2
    FLAVOR_ID=$3
    KEYPAIR_NAME="${TAG}_keypair"

    NETWORK_NAME="${TAG}_network"
    INSTANCE_NAME="${TAG}_instance"

    openstack server create --image "$IMAGE_ID" --flavor "$FLAVOR_ID" --network "$NETWORK_NAME" --key-name "$KEYPAIR_NAME" "$INSTANCE_NAME"
    echo "Instance '$INSTANCE_NAME' created."

    FLOATING_IP=$(allocate_floating_ip)
    openstack server add floating ip "$INSTANCE_NAME" "$FLOATING_IP"
    echo "Floating IP '$FLOATING_IP' associated with instance '$INSTANCE_NAME'."
}

# Main script execution
function main {
    if [ $# -lt 3 ]; then
        echo "Usage: $0 <tag> <image-id> <flavor-id>"
        exit 1
    fi

    TAG=$1
    IMAGE_ID=$2
    FLAVOR_ID=$3

    check_openstack_credentials
    create_keypair "$TAG"
    create_network "$TAG"
    create_subnet "$TAG"
    create_router "$TAG"
    launch_instance "$TAG" "$IMAGE_ID" "$FLAVOR_ID"
}

# Run main function with all passed arguments
main "$@"
