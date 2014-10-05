# Constants and helper functions for master-of-masters bootstrapping

############################################################################
# CONSTANTS
############################################################################

PE_VERSION="3.3.1"
INSTALL_PATH="pe/puppet-enterprise-${PE_VERSION}-el-6-x86_64"
ANSWER_PATH="answers"
CONTROL_REPO_URL='https://github.com/gsarjeant/puppet-master-of-masters.git'

# Text colors
txtred="\033[0;31m" # Red
txtgrn="\033[0;32m" # Green
txtylw="\033[0;33m" # Yellow
txtblu="\033[0;34m" # Blue
txtpur="\033[0;35m" # Purple
txtcyn="\033[0;36m" # Cyan
txtwht="\033[0;37m" # White
txtrst="\033[0m"

############################################################################
# HELPER FUNCTIONS
############################################################################

function validate_root(){
  if [ "$(whoami)" != "root" ]; then
    echo "You must run this as root."
    exit 1
  fi
}

function prompt_for_server_role(){
  echo
  echo "===================================================================="
  echo "Select which node to install:"
  echo
  echo "  [1] MoM CA/Master"
  echo "  [2] MoM PuppetDB/pgsql"
  echo "  [3] MoM Console"
  echo
  echo "  [4] Tenant Compile Master"
  echo "  [5] Tenant PuppetDB"
  echo "  [6] Tenant Console"
  echo
  read -p "Selection: " SERVER_ROLE
}

function set_role_params(){
  case $SERVER_ROLE in
    4)
      # Tenant puppet master
      SERVER_ROLE_NAME='Tenant Puppet Master'
      PUPPET_ROLE_NAME='role::puppet::tenant::master'
      PUPPET_ROLE_ANSWERS='tenant.master'
      ;;
    5)
      # Tenant puppetdb
      SERVER_ROLE_NAME='Tenant PuppetDB'
      PUPPET_ROLE_NAME='role::puppet::tenant::puppetdb'
      PUPPET_ROLE_ANSWERS='tenant.master'
      ;;
    6)
      # Tenant console
      SERVER_ROLE_NAME='Tenant PE Console'
      PUPPET_ROLE_NAME='role::puppet::tenant::console'
      PUPPET_ROLE_ANSWERS='tenant.master'
      ;;
  esac
}

function install_pe() {
  if [ ! -d "${INSTALL_PATH}" ]; then
    echo "Failure: PE Installer not found at ${INSTALL_PATH}"
    exit 1
  fi

  if [ ! -f "${ANSWER_PATH}/${PUPPET_ROLE_ANSWERS}.txt" ]; then
    echo "Failure: Answer file not found: ${ANSWER_PATH}/${PUPPET_ROLEANSWERS}.txt"
    exit 1
  fi

  "${INSTALL_PATH}/puppet-enterprise-installer" \
    -A "${ANSWER_PATH}/${PUPPET_ROLE_ANSWERS}.txt" \
    -l "/tmp/pe_install.$(hostname -f).$(date +%Y-%m-%d_%H-%M).log"

  if [ $? -eq 0 ]; then
    echo "==> Puppet Enterprise Installer is complete"
    echo "==> Now starting the bootstrap..."
    echo
  else
    echo "==> The PE installer did not exit cleanly (0)"
    echo "==> This might be okay. Evaluate the output and make a determination."
    echo
    echo "==> The bootstrap is starting. If the PE installer genuinely failed,"
    echo "==> you should CTRL+C now, resolve the issues, uninstall PE, and"
    echo "==> re-run the bootstrap"
    echo
  fi
}

function has_pe() {
  if [ -f "/opt/puppet/bin/puppet" ]; then
    return 0
  else
    return 1
  fi
}

function apply_puppet_role() {
  echo "==> Applying Puppet role of ${PUPPET_ROLE_NAME}"
  /opt/puppet/bin/puppet apply -e "include ${PUPPET_ROLE_NAME}" \
    --modulepath=${_script_dir}/../site:${_script_dir}/../modules:/opt/puppet/share/puppet/modules
}


############################################################################
# Functions in this block configure the various PE server roles
############################################################################

function configure_puppet_server(){
  case $SERVER_ROLE in
    4)
      configure_tenant_master
      ;;
    5)
      configure_tenant_puppetdb
      ;;
    6)
      configure_tenant_console
      ;;
  esac
}

function configure_tenant_master(){
  apply_puppet_role
  echo "==> Applied role ${PUPPET_ROLE_NAME}"

  # remove the tenant ssldir
  PUPPET_AGENT_SSLDIR=$(puppet config print ssldir)
  echo "==> Moving ${PUPPET_AGENT_SSLDIR}"
  mv $PUPPET_AGENT_SSLDIR "${PUPPET_AGENT_SSLDIR}.orig"

  # Do a puppet agent run against the ca server to generate a CSR
  echo "==> Regenerating SSL certificates"
  puppet agent -t --noop --server $(puppet config print ca_server)

  # At this point, we have to manually sign the cert
  # This is because we can't autosign certs with alt names.
  ca_sign_cert

  # Once the client cert is re-signed, do a full agent run against the CA to get the correct mcollective certs.
  echo "==> Running puppet against the MoM CA, to ship the correct mcollective internal certs."
  export FACTER_server_role=$PUPPET_ROLE_NAME
  puppet agent -t --server $(puppet config print ca_server)

  # Run r10k on the tenant master to pull down the correct control repos
  /opt/puppet/bin/r10k deploy environment -p

  # Restart the pe-httpd process
  echo "==> Restarting pe-httpd to read new configs and certs."
  service pe-httpd restart

  echo
  echo "==> Reconfiguration of tenant master complete"
}

function configure_tenant_puppetdb(){
  # Apply the puppetdb role once to get everything pointing to the ca correctly
  apply_puppet_role

  # Remove the agent and PuppetDB SSL data
  # so we can generate a new cert from the global CA
  echo "==> Removing SSL data"
  rm -rf /etc/puppetlabs/puppet/ssl
  rm -rf /etc/puppetlabs/puppetdb/ssl

  # Regenerate CSR. Should be autosigned
  echo "==> Running Puppet agent to create CSR"
  /opt/puppet/bin/puppet agent -t --noop --server $(puppet config print ca_server)

  # Apply the puppetdb role a second time to recreate the internal certs.
  # There will be an error here when we attempt to submit the report.
  # It will go away when pe-puppetdb is restarted
  apply_puppet_role

  echo "==> Restarting the pe-puppetdb service"
  service pe-puppetdb restart

  echo
  echo "==> Reconfiguration of tenant puppetdb complete"
}

function configure_tenant_console(){
  apply_puppet_role

  echo "==> Removing SSL data"
  rm -rf /etc/puppetlabs/puppet/ssl

  echo "==> Running Puppet agent against CA to create CSR"
  echo "==> and to ship internal console certs."
  echo "==> The CSR will be autosigned by the CA."
  export FACTER_server_role=$PUPPET_ROLE_NAME
  /opt/puppet/bin/puppet agent -t --server $(puppet config print ca_server)

  # Restart pe-httpd
  echo "==> Restarting pe-httpd to read new configs and certs."
  service pe-httpd restart

  echo
  echo "==> Reconfiguration of tenant console complete"
}

############################################################################
# Functions below here won't be used in non-interactive mode
############################################################################

function confirm_install() {
  echo -e "** You have selected to install ${txtylw}${SERVER_ROLE_NAME}${txtrst} for node ${txtylw}$(hostname -f)${txtrst}**"
  echo
  read -p "Press 'y' to proceed: " proceed_install
  if [ "${proceed_install}" != "y" ]; then
    echo "Exiting."
    exit 0
  fi
}

function ca_clean_cert() {
  echo -e "${txtylw}"
  echo "#=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+="
  echo -e "${txtrst}"
  echo "# You now need to clean the certificate for ${1} on the CA"
  echo "    puppet cert clean ${1}"
  echo
  read -p "# Press 'y' when the certificate has been cleaned: " cert_clean
  while [ "${cert_clean}" != "y" ]; do
    ca_clean_cert $1
  done
}

function ca_sign_cert() {
  echo -e "${txtylw}"
  echo "#=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+="
  echo -e "${txtrst}"
  echo "# You now need to sign the certificate for $(hostname) on the CA"
  echo "    puppet cert sign --allow-dns-alt-names $(hostname)"
  echo
  read -p "# Press 'y' when the certificate has been signed: " sign_cert
  while [ "${sign_cert}" != "y" ]; do
    ca_sign_cert $1
  done
}
