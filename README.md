# Red Hat Unattended Satellite Server Setup

This repository provides scripts to automate the setup of a Red Hat Satellite server and client systems. It is designed to streamline the process of installing and configuring a Satellite server and registering client systems with it.

The scripts use a YAML configuration file, allowing for easy customization of the Satellite server and client setup. The configuration file includes information such as the organization name, Red Hat Subscription Manager credentials, Satellite server admin credentials, and details about content views and repositories.

## Overview

The setup process involves two main scripts:

- `satellite_setup.sh`: This script installs and configures the Satellite server based on the parameters provided in the configuration file. It registers the server with the Red Hat Subscription Manager, installs the necessary software, and creates content views with the specified repositories.

- `generate_setup_client.sh`: This script generates a client setup script (`setup_client.sh`) that can be run on each client system to register it with the Satellite server and subscribe it to the required update streams.

## Prerequisites

The scripts require the `jq` package to parse JSON data and the `yq` command-line utility to parse YAML data. You can install these tools with `yum`:

```bash
yum install jq
pip install yq
```

## Configure

| Parameter                 | Sub Parameter |Description                                                                                               |
|---------------------------|---|-----------------------------------------------------------------------------------------------------------|
| `organisation`          |  | The name of the organization for the Satellite server.                                                    |
| `rhel_version`           | | The version of RHEL for the Satellite server (8 or 9).                                                   |
| `rhsm_user`             |  | The username for the Red Hat Subscription Manager.                                                       |
| `rhsm_password`         |  | The password for the Red Hat Subscription Manager.                                                       |
| `rhsm_poolid`          |   | The pool ID for the Red Hat Subscription Manager.                                                        |
| `satellite_user`        |  | The admin username for the Satellite server.                                                             |
| `satellite_password`    |  | The admin password for the Satellite server.                                                             |
| `content_views`       |    | A list of content views. Each content view has the following properties:                                 |
| | `name`                    | The name of the content view.                                                                            |
| | `repos`                   | An array of repositories to add to the content view.                                                     |
| | `lifecycle_environment`   | The lifecycle environment to use for the content view.                                                   |
| | `activation_key_name`     | The name of the activation key to use for the content view. This key is used to register client systems. |


### Example configuration file

Here is an example configuration file:


```
---
organisation: "Company"
rhel_version: 8
rhsm_user: "user.name@domain.com"
rhsm_password: changeme
rhsm_poolid: abcd12345
satellite_user: admin
satellite_password: changeme
content_views:
- name: rhel8-sap
  repos: [ "rhel-sap-baseOS", "rhel-sap1", "rhel-ha-sap" ]
  lifecycle_environment: SAP
  activation_key_name: rhel8-sap
- name: rhel8
  repos: [ "rhel-8-for-x86_64-baseos-rpms", "rhel-8-for-x86_64-appstream-rpms" ]
  lifecycle_environment: Library
  satellite_activation_key_name: rhel8
```

> Note: It is not a good idea to store passwords in plaintext, this is a poc mechanism, secrets should be retrieved using an appropriate secure method

## Setup

To set up the Satellite server, run the satellite_setup.sh script with the path to your configuration file as an argument:

```bash
./satellite_setup.sh /path/to/config.yaml
```

This will set up the Satellite server according to the parameters in the configuration file. If the script runs successfully, it will output a message indicating that the setup is complete.

Next, run the generate_setup_client.sh script with the path to your configuration file as an argument:

```bash
./generate_setup_client.sh /path/to/config.yaml content_view_name
```

This will generate a setup_client.sh script that can be run on each client system to register it with the Satellite server and subscribe it to the required update streams. The setup_client.sh script includes commands to deregister the system from the subscription-manager, clean up existing yum data, and add the Satellite server's URL to the /etc/hosts file if it's not reachable.

Once the setup_client.sh script has been generated, you can distribute it to your client systems and run it on each one to complete the client setup.

## Conclusion

This repository provides a convenient and automated way to set up a Red Hat Satellite server and register client systems with it. It allows for easy customization of the setup process through a YAML configuration file. Please note that this is a basic setup and might need to be customized to fit your exact needs. Always ensure to secure your sensitive information appropriately.

Please replace the placeholders with your actual data, and feel free to adjust the text as needed to fit your specific use case and environment.
