#!/bin/sh
###############################################################################
# Puppet Enterprise Installer Wrapper
#
# This wraps the PE installer to make for a more automated custom split
# installation.
###############################################################################

# lib/bootstrap-functions.sh defines all of the functions invoked below,
# and any other functions upon which they rely.
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
# TODO: Allow the user to specify the role on the command line.
prompt_for_server_role
echo "You selected role ${SERVER_ROLE}"

# Set the role name and answer file for the selected role
set_role_params
echo "Role name: ${PUPPET_ROLE_NAME}"
echo "Role answers: ${PUPPET_ROLE_ANSWERS}"

# Confirm the selected role
# TODO: Only confirm if run interactively
confirm_install

# Install PE if necessary
if ! has_pe; then
  echo "PE not found. Installing"
  install_pe
  echo "PE has been installed. Please rerun the bootstrap after PE is installed on the other components to proceed with reconfiguration."
else
  echo "PE is installed. Proceeding with reconfiguration."
  # Configure the selected role appropriately
  #   - Reconfigure tenants to use MoM CA as CA
  #   - Remove tenant SSL dirs
  #   - Regenerate tenant SSL certs
  configure_puppet_server
fi

