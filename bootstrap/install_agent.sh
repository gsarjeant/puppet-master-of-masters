#! /bin/bash

# Installs a Puppet agent on a tenant system and
# reconfigures it as needed.

# TODO: This function will have to query eman to get two pieces of information:
#       1. The PUPPET_OWNER_NAME for the server that the script is run from.
#       2. The FQDN of this owner's compile master. 
#          This is determined by searching EMAN for a host that matches
#          - PUPPET_OWNER_NAME   = <PUPPET_OWNER_NAME> from step 1.
#          - PUPPET_SERVICE_ROLE = 'role::puppet::tenant::master'
#
# For now, this is a stub
function get_tenant_compile_master {
  # TODO: Query EMAN to get my PUPPET_OWNER_NAME
  # TODO: Query EMAN to find the compile master for my PUPPET_OWNER_NAME

  TENANT_COMPILE_MASTER_FQDN='master.tenant.example.vm'
}

# TODO: This function will have to query eman to get one piece of information:
#       1. The FQDN of the MoM CA.
#
# For now, this is a stub
function get_tenant_compile_master {
  # TODO: Query EMAN to get my PUPPET_OWNER_NAME

  MOM_CA_FQDN='master.example.vm'
}

function install_puppet_agent {
  AGENT_INSTALL_CMD="curl -k http://${TENANT_COMPILE_MASTER_FQDN}:8140/packages/current/install.bash | bash"

  $AGENT_INSTALL_CMD
}

function set_external_facts {
  ./get_node_facts
}

function reconfigure_agent {
  export FACTER_server_role='role::puppet::agent::reconfigure'
  puppet agent -t --server $MOM_CA_FQDN
}

# Script execution
get_mom_ca_server
get_tenant_compile_master
install_puppet_agent
set_external_facts
reconfigure_agent
