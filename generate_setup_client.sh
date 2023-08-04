#!/bin/bash

# Read the config file
if [ -z "$1" ]
then
    echo "Usage: $0 <config_file> <content-view>"
    exit 1
fi

# Variables
CONFIG_FILE="$1"
ORGANISATION=$(yq r $CONFIG_FILE organisation)
CONTENT_VIEW=$(yq r $CONFIG_FILE content_views.$2.name)
LIFECYCLE_ENVIRONMENT=$(yq r $CONFIG_FILE content_views.$2.lifecycle_environment)
ACTIVATION_KEYS=$(yq r $CONFIG_FILE content_views.$2.activation_key_name)

# Check if the activation key already exists
ACTIVATION_KEY_EXISTS=$(hammer --csv activation-key list --organization "$ORGANISATION" | grep "$ACTIVATION_KEY")

if [ -z "$ACTIVATION_KEY_EXISTS" ]
then
    # Create the activation key
    hammer activation-key create --name "$ACTIVATION_KEY" --organization "$ORGANISATION" --content-view "$CONTENT_VIEW" --lifecycle-environment "$LIFECYCLE_ENVIRONMENT"
fi

# Get the URL of the Satellite server
SATELLITE_URL=$(hammer --csv settings list | grep ^foreman_url | cut -d',' -f2)
SATELLITE_IP=$(getent hosts $SATELLITE_URL | awk '{ print $1 }')

# Output the client setup script
cat << EOF > setup_client.sh
#!/bin/bash

# Variables
ORG="$ORGANISATION"
KEY="$ACTIVATION_KEY"
SATELLITE_URL="$SATELLITE_URL"
SATELLITE_IP="$SATELLITE_IP"

# Deregister and clean up existing yum data
subscription-manager unregister
yum clean all
rm -rf /var/cache/yum

# Add the Satellite server's IP to /etc/hosts if it's not reachable
ping -c 1 \$SATELLITE_URL &> /dev/null
if [ \$? -ne 0 ]
then
    echo "\$SATELLITE_IP \$SATELLITE_URL" >> /etc/hosts
fi

# Register with the Satellite server
subscription-manager register --org="\$ORG" --activationkey="\$KEY" --serverurl=https://\$SATELLITE_URL:443/rhsm --baseurl=https://\$SATELLITE_URL/pulp/repos

EOF

# Make the client setup script executable
chmod +x setup_client.sh

echo "Client setup script created: setup_client.sh"
echo "Run this script on the target instance to register it with the Satellite server"