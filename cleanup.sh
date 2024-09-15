#!/bin/bash

# Function to check if OpenStack RC file is sourced
function check_openstack_credentials {
    if [ -z "$OS_AUTH_URL" ]; then
        echo "Please source your OpenStack RC file to set environment variables."
        exit 1
    fi
}

# Function to delete the instance
function delete_instance {
    TAG=$1
    INSTANCE_NAME="${TAG}_instance"

    if openstack server show "$INSTANCE_NAME" &>/dev/null; then
        openstack server delete "$INSTANCE_NAME"
        echo "Instance '$INSTANCE_NAME' deleted."
    else
        echo "Instance '$INSTANCE_NAME' does not exist."
    fi
}

# Function to release the floating IP
function release_floating_ip {
    TAG=$1
    INSTANCE_NAME="${TAG}_instance"

    FLOATING_IP=$(openstack server show "$INSTANCE_NAME" -f value -c addresses | awk -F'=' '{print $2}')

    if [ -n "$FLOATING_IP" ]; then
        FLOATING_IP_ID=$(openstack floating ip list --floating-ip-address "$FLOATING_IP" -f value -c ID)

        if [ -n "$FLOATING_IP_ID" ]; then
            openstack floating ip delete "$FLOATING_IP_ID"
            echo "Floating IP '$FLOATING_IP' released."
        fi
    else
        echo "No floating IP found for instance '$INSTANCE_NAME'."
    fi
}

# Function to delete all ports in the subnet
function delete_ports_in_subnet {
    SUBNET_NAME=$1
    SUBNET_ID=$(openstack subnet show "$SUBNET_NAME" -f value -c id)

    # List all ports associated with the subnet and delete them
    PORTS=$(openstack port list --fixed-ip subnet_id=$SUBNET_ID -f value -c ID)
    for PORT in $PORTS; do
        openstack port delete "$PORT"
        echo "Port '$PORT' deleted from subnet '$SUBNET_NAME'."
    done
}

# Function to delete the router
function delete_router {
    TAG=$1
    ROUTER_NAME="${TAG}_router"
    SUBNET_NAME="${TAG}_subnet"

    if openstack router show "$ROUTER_NAME" &>/dev/null; then
        # Remove subnet from router
        openstack router remove subnet "$ROUTER_NAME" "$SUBNET_NAME"
        echo "Subnet '$SUBNET_NAME' removed from router '$ROUTER_NAME'."

        # Unset external gateway and delete router
        openstack router unset --external-gateway "$ROUTER_NAME"
        openstack router delete "$ROUTER_NAME"
        echo "Router '$ROUTER_NAME' deleted."
    else
        echo "Router '$ROUTER_NAME' does not exist."
    fi
}

# Function to delete the subnet
function delete_subnet {
    TAG=$1
    SUBNET_NAME="${TAG}_subnet"

    if openstack subnet show "$SUBNET_NAME" &>/dev/null; then
        # Delete all ports before deleting the subnet
        delete_ports_in_subnet "$SUBNET_NAME"
        openstack subnet delete "$SUBNET_NAME"
        echo "Subnet '$SUBNET_NAME' deleted."
    else
        echo "Subnet '$SUBNET_NAME' does not exist."
    fi
}

# Function to delete the network
function delete_network {
    TAG=$1
    NETWORK_NAME="${TAG}_network"

    if openstack network show "$NETWORK_NAME" &>/dev/null; then
        openstack network delete "$NETWORK_NAME"
        echo "Network '$NETWORK_NAME' deleted."
    else
        echo "Network '$NETWORK_NAME' does not exist."
    fi
}

# Function to delete the keypair
function delete_keypair {
    TAG=$1
    KEYPAIR_NAME="${TAG}_keypair"

    if openstack keypair show "$KEYPAIR_NAME" &>/dev/null; then
        openstack keypair delete "$KEYPAIR_NAME"
        rm -f "${KEYPAIR_NAME}.pem"
        echo "Keypair '$KEYPAIR_NAME' and associated private key deleted."
    else
        echo "Keypair '$KEYPAIR_NAME' does not exist."
    fi
}

# Main cleanup script execution
function main {
    if [ $# -lt 1 ]; then
        echo "Usage: $0 <tag>"
        exit 1
    fi

    TAG=$1

    check_openstack_credentials
    delete_instance "$TAG"
    release_floating_ip "$TAG"
    delete_router "$TAG"
    delete_subnet "$TAG"
    delete_network "$TAG"
    delete_keypair "$TAG"
}

# Run main function with all passed arguments
main "$@"
