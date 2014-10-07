# Constants and helper functions for master-of-masters bootstrapping

############################################################################
# CONSTANTS
############################################################################

PE_VERSION='3.3.1'
PE_BIN_DIR='/opt/puppet/bin'
# NOTE: This will be created by the PE installer rpm
PE_INSTALLER_PATH='/apps/pe-installer/puppet-enterprise-${PE_VERSION}-el-6-x86_64'
ANSWER_PATH='answers'
GIT_INSTALL_DIR='/usr/example/bin'
CONTROL_REPO_NAME='puppet-master-of-masters'
CONTROL_REPO_URL="https://github.com/gsarjeant/${CONTROL_REPO_NAME}.git"

INSTALL_BASE_DIR='/apps'
CONTROL_REPO_SUBDIR='control_repo'
CONTROL_REPO_ROOT="${INSTALL_BASE_DIR}/${CONTROL_REPO_SUBDIR}"
CONTROL_REPO_DIR="${CONTROL_REPO_ROOT}/${CONTROL_REPO_NAME}"

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
    1)
      # MoM puppet master
      SERVER_ROLE_NAME='MoM Puppet Master'
      PUPPET_ROLE_NAME='role::puppet::master'
      PUPPET_ROLE_ANSWERS='mom.master'
      ;;
    2)
      # MoM puppetdb
      SERVER_ROLE_NAME='MoM PuppetDB'
      PUPPET_ROLE_NAME='role::puppet::puppetdb'
      PUPPET_ROLE_ANSWERS='mom.master'
      ;;
    3)
      # MoM console
      SERVER_ROLE_NAME='MoM Puppet Console'
      PUPPET_ROLE_NAME='role::puppet::console'
      PUPPET_ROLE_ANSWERS='mom.console'
      ;;
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
    *)
      # Default: unknown role - exit
      echo "ERROR: Unknown role specified. Exiting."
      exit 1
      ;;
  esac
}

function install_pe() {
  if [ ! -d "${INSTALL_PATH}" ]; then
    echo "Failure: PE Installer not found at ${INSTALL_PATH}"
    exit 1
  fi

  if [ ! -f "${ANSWER_PATH}/${PUPPET_ROLE_ANSWERS}.txt" ]; then
    echo "Failure: Answer file not found: ${ANSWER_PATH}/${PUPPET_ROLE_ANSWERS}.txt"
    exit 1
  fi

  "${INSTALL_PATH}/puppet-enterprise-installer" \
    -a "${ANSWER_PATH}/${PUPPET_ROLE_ANSWERS}.txt" \
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

function apply_puppet_role_local() {
  echo "==> Applying Puppet role of ${PUPPET_ROLE_NAME}"

  /opt/puppet/bin/puppet apply -e "include ${PUPPET_ROLE_NAME}" \
    --modulepath=${CONTROL_REPO_DIR}/site:${CONTROL_REPO_DIR}/modules:/opt/puppet/share/puppet/modules
}

function install_git(){
  # Make sure git isn't already installed
  if [ ! -f "${GIT_INSTALL_DIR}/git" ]
  then
    echo "==> git not found: installing git"
    yum install git
  fi
}

function clone_infrastructure_control_repo(){
  echo "==> Cloning ${CONTROL_REPO_URL} into ${CONTROL_REPO_ROOT}"
  mkdir -p $CONTROL_REPO_ROOT
  cd $CONTROL_REPO_ROOT

  git clone  $CONTROL_REPO_URL
}

function install_r10k(){
  # Install the r10k gem into the PE vendored ruby's gem environment.
  # NOTE: We discourage this generally, but r10k only exists for Puppet
  #       and we don't expect to have another ruby installed on PE infra. servers

  R10K_INSTALLED=$("${PE_BIN_DIR}/gem" list r10k -i)

  if [ $R10K_INSTALLED = 'false' ]
  then
    echo "==> Installing r10k"
    "${PE_BIN_DIR}/gem" install r10k
  fi
}

function install_control_repo_dependencies(){
  ORIGINAL_DIR=$PWD
  # CD into the control repo directory and run r10k puppetfile install
  cd $CONTROL_REPO_DIR
  echo "==> Installing control repo dependencies from Puppetfile using r10k"
  "${PE_BIN_DIR}/r10k" puppetfile install -v
  cd $ORIGINAL_DIR
}

function clean_up_local_repo(){
  echo "==> Deleting local clone of infrastructure control repo"
  if [ $CONTROL_REPO_DIR == '' ] || [ $CONTROL_REPO_DIR == '/' ]
  then
    echo "Control repo dir not set - bail!"
  else 
    rm -rf $CONTROL_REPO_DIR
  fi
}

############################################################################
# Functions in this block configure the various PE server roles
############################################################################

function configure_puppet_server(){
  case $SERVER_ROLE in
    1)
      configure_mom_master
      ;;
    2)
      echo "The MoM PuppetDB does not require reconfiguration in phase 1"
      ;;
    3)
      echo "The MoM console does not require reconfiguration in phase 1"
      ;;
    4)
      configure_tenant_master
      ;;
    5)
      configure_tenant_puppetdb
      ;;
    6)
      configure_tenant_console
      ;;
    *)
      echo "Unknown role specified: ${SERVER_ROLE} - exiting"
      exit 1
      ;;
  esac
}

function configure_mom_master(){
  # Install git if necessary
#  install_git

  #Install r10k if necessary
  install_r10k

  # Pull down the control repo for initial reconfiguration
  clone_infrastructure_control_repo

  # Use r10k to install dependency modules for the control repo
  install_control_repo_dependencies

  # Run "puppet apply" to do the remaining local reconfiguration
  apply_puppet_role_local
  echo "==> Applied role ${PUPPET_ROLE_NAME}"

  # Clean up the local clone of the infrasturcture control repo.
  clean_up_local_repo

  # Run r10k on the MoM master to pull down the correct control repos
  # And configure the environment directories
  /opt/puppet/bin/r10k deploy environment -p -v

  # Restart the pe-httpd process
  echo "==> Restarting pe-httpd to read new configs and certs."
  service pe-httpd restart

  echo
  echo "==> Reconfiguration of MoM master complete"
}

function configure_tenant_master(){
  apply_puppet_role
  echo "==> Applied role ${PUPPET_ROLE_NAME}"

  # remove the tenant ssldir
  PUPPET_AGENT_SSLDIR=$(puppet config print ssldir)
  echo "==> Removing ${PUPPET_AGENT_SSLDIR}"
  if [ $PUPPET_AGENT_SSLDIR == '' ] || [ $PUPPET_AGENT_SSLDIR == '/' ]
  then
    echo "Puppet Agent SSL dir not set - bail!"
  else 
    rm -rf $PUPPET_AGENT_SSLDIR
  fi

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
  echo "==> Creating environments with r10k"
  /opt/puppet/bin/r10k deploy environment -p -v

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
