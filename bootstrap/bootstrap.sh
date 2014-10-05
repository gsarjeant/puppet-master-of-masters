#!/bin/sh
###############################################################################
# Puppet Enterprise Installer Wrapper
#
# This wraps the PE installer to make for a more automated split custom split
# installation.
###############################################################################

source lib/bootstrap-functions.sh
## This file includes the hostnames that we need.
## Probably won't use this in my config, but leaving the line here for a bit.
#source answers/common.txt

_script_dir=$PWD

################################################################################
## Probably don't need to modify below this
################################################################################

# Make sure we are running as root before proceeding
validate_root

# Ask the user for the server role if it wasn't specified on the command line
prompt_for_server_role
echo "You selected role ${SERVER_ROLE}"

# Set the role name and answer file for the selected role
set_role_params
echo "Role name: ${ROLE_NAME}"
echo "Role answers: ${ROLE_ANSWERS}"

# Confirm the selected role
confirm_install

# Install PE if necessary
if ! has_pe; then
  echo "PE not found. Installing"
  install_pe
else
  echo "PE is installed. Proceeding with reconfiguration."
fi

# Configure the selected role appropriately
#   - Reconfigure tenants to use MoM CA as CA
#   - Remove tenant SSL dirs
#   - Regenerate tenant SSL certs
configure_puppet_server
