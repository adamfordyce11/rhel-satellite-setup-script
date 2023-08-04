#!/bin/bash

# Get the config file from the command line
if [ -z "$1" ]
then
    echo "Usage: $0 <config_file>"
    exit 1
fi

# Variables
CONFIG_FILE="$1"

# If the config file is invalid then exit with an error
if [ ! -f "$CONFIG_FILE" ]
then
    echo "Config file not found: $CONFIG_FILE"
    exit 1
fi

# Load Config file
ORGANISATION=$(cat $CONFIG_FILE | grep organisation | cut -d' ' -f2)
RHSM_USER=$(cat $CONFIG_FILE | grep rhsm_user | cut -d' ' -f2)
RHSM_PASSWORD=$(cat $CONFIG_FILE | grep rhsm_password | cut -d' ' -f2)
RHSM_POOLID=$(cat $CONFIG_FILE | grep rhsm_poolid | cut -d' ' -f2)
SATELLITE_USER=$(cat $CONFIG_FILE | grep satellite_user | cut -d' ' -f2)
SATELLITE_PASSWORD=$(cat $CONFIG_FILE | grep satellite_password | cut -d' ' -f2)
RHEL_VERSION=$(cat $CONFIG_FILE | grep rhel_version | cut -d' ' -f2)

# Install Satellite Server
echo "Installing Satellite Server"
subscription-manager register --username $RHSM_USER --password $RHSM_PASSWORD
subscription-manager attach --pool=$RHSM_POOLID

# Enable repositories based on RHEL version
if [ $RHEL_VERSION -eq 8 ]
then
    subscription-manager repos --enable=rhel-8-for-x86_64-appstream-rpms --enable=rhel-8-for-x86_64-baseos-rpms --enable=satellite-6.7-for-rhel-8-x86_64-rpms
elif [ $RHEL_VERSION -eq 9 ]
then
    subscription-manager repos --enable=rhel-9-for-x86_64-appstream-rpms --enable=rhel-9-for-x86_64-baseos-rpms --enable=satellite-6.7-for-rhel-9-x86_64-rpms
fi

yum clean all
yum -y install satellite

# Configure Satellite Server
echo "Configuring Satellite Server"
satellite-installer --scenario satellite --foreman-initial-organization "$ORGANISATION" --foreman-initial-location "Default Location" --foreman-admin-username $SATELLITE_USER --foreman-admin-password $SATELLITE_PASSWORD

# Create Content Views and Add Repositories
echo "Creating Content Views and Adding Repositories"
# Reading the content views
CONTENT_VIEWS=$(cat $CONFIG_FILE | grep -A2 content_views | tail -n +2)
for cv in $CONTENT_VIEWS; do
    # Extract the name and repos
    CV_NAME=$(echo $cv | cut -d':' -f1)
    CV_REPOS=$(echo $cv | cut -d'[' -f2 | cut -d']' -f1)

    # Create the content view
    hammer content-view create --name "$CV_NAME" --organization "$ORGANISATION"

    # Add the repositories
    for repo in $CV_REPOS; do
        hammer content-view add-repository --name "$CV_NAME" --organization "$ORGANISATION" --repository "$repo"
    done
done

# Sync Repositories
echo "Syncing Repositories"
REPOS=$(hammer --output json repository list | jq -r '.[].Id')
for repo in $REPOS; do
    hammer repository synchronize --id $repo
done

# Output Command to run on target instance
echo "Command to run on target instance:"
echo "subscription-manager register --org=\"$ORGANISATION\" --activationkey=\"<activation-key>\""
