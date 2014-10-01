#!/bin/sh
###############################################################################
# Puppet Enterprise Installer Wrapper
#
# This wraps the PE installer to make for a more automated split custom split
# installation.
###############################################################################

PE_VERSION="3.3.2"
INSTALL_PATH="pe/puppet-enterprise-${PE_VERSION}-el-6-x86_64"
ANSWER_PATH="answers"

PUPPET_DB_SSLDIR="/etc/puppetlabs/puppetdb/ssl"

################################################################################
## Probably don't need to modify below this
################################################################################

if [ "$(whoami)" != "root" ]; then
  echo "You must run this as root."
  exit 1
fi

## This file includes the hostnames that we need
source answers/common.txt

echo
echo "===================================================================="
echo "Select which node to install:"
echo
echo "  [1] MoM CA/Master           ${MOM_PUPPETCA}"
echo "  [2] MoM PuppetDB/pgsql      ${MOM_PUPPETDB}"
echo "  [3] MoM Console             ${MOM_PUPPETCONSOLE}"
echo
echo "  [4] Tenant Compile Master   ${TENANT_PUPPETMASTER}"
echo "  [5] Tenant PuppetDB         ${TENANT_PUPPETDB}"
echo "  [6] Tenant Console          ${TENANT_PUPPETCONSOLE}"
echo
echo "  [7] Additional Compile-only master"
echo
read -p "Selection: " server_role

txtred="\033[0;31m" # Red
txtgrn="\033[0;32m" # Green
txtylw="\033[0;33m" # Yellow
txtblu="\033[0;34m" # Blue
txtpur="\033[0;35m" # Purple
txtcyn="\033[0;36m" # Cyan
txtwht="\033[0;37m" # White
txtrst="\033[0m"

_script_dir=$PWD

function install_pe() {
  ANSWERS="$1"

  if [ ! -d "${INSTALL_PATH}" ]; then
    echo "Failure: PE Installer not found at ${INSTALL_PATH}"
    exit 1
  fi

  if [ ! -f "${ANSWER_PATH}/${ANSWERS}.txt" ]; then
    echo "Failure: Answer file not found: ${ANSWER_PATH}/${ANSWERS}.txt"
    exit 1
  fi

  "${INSTALL_PATH}/puppet-enterprise-installer" \
    -A "${ANSWER_PATH}/${ANSWERS}.txt" \
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
  echo "==> Applying Puppet role of ${1}"
  /opt/puppet/bin/puppet apply -e "include ${1}" \
    --modulepath=${_script_dir}/../site:${_script_dir}/../modules:/opt/puppet/share/puppet/modules
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
  echo "# You now need to sign the certificate for ${1} on the CA"
  echo "    puppet cert sign --allow-dns-alt-names ${1}"
  echo
  read -p "# Press 'y' when the certificate has been signed: " sign_cert
  while [ "${sign_cert}" != "y" ]; do
    ca_sign_cert $1
  done
}

function confirm_install() {
  echo -e "** You have selected to install ${txtylw}${1}${txtrst} for node ${txtylw}$(hostname -f)${txtrst}**"
  echo
  read -p "Press 'y' to proceed: " proceed_install
  if [ "${proceed_install}" != "y" ]; then
    echo "Exiting."
    exit 0
  fi
}

case $server_role in
  #############################################################################
  ## Master-of-masters CA
  #############################################################################
  1|$MOM_PUPPETCA)
    ## Primary CA
    ANSWERS="puppetca01"
    ROLE="role::puppet::ca"

    confirm_install "${MOM_PUPPETCA}"

    if ! has_pe; then
      install_pe $ANSWERS
    fi

    ## Install some needed software
    echo "==> Installing git..."
    /opt/puppet/bin/puppet resource package git ensure=present || \
      (echo "git failed to install; exiting." && exit 1)

    echo "==> Installing r10k..."
    /opt/puppet/bin/gem install r10k || \
      (echo "r10k failed to install; exiting" && exit 1)

    ## Use r10k to fetch all the modules needed
    cd "../"
    echo "Running r10k against Puppetfile..."
    /opt/puppet/bin/r10k puppetfile install -v || \
      (echo "r10k didn't exit cleanly; exiting" && exit 1)

    apply_puppet_role "${ROLE}"

    echo
    echo "********************************************************************"
    echo "r10k needs to be run to create the environments and install modules."
    echo
    echo "This is required to bootstrap the other servers!"
    echo "You can do this by executing:"
    echo "   r10k deploy environment -pv"
    echo "..or just let us do it now."
    echo
    read -p "=> Should we run r10k now? [y/n] " run_r10k
    if [ "${run_r10k}" == "y" ]; then
      echo "==> Running r10k deploy environment -pv"
      echo "==> This might take a few minutes..."
      /opt/puppet/bin/r10k deploy environment -pv
    fi
    echo
    echo "==> ${MOM_PUPPETCA} complete"
  ;;
  #############################################################################
  ## MoM PuppetDB
  #############################################################################
  2|$MOM_PUPPETDB)
    ## Primary PuppetDB server
    ANSWERS="puppetdb01"
    NAME="${MOM_PUPPETDB}"
  ;;
  #############################################################################
  ## MoM Console
  #############################################################################
  3|$MOM_PUPPETCONSOLE)
    ANSWERS="puppetconsole01"
    ROLE="role::puppet::console"
    ALT_NAMES="${MOM_PUPPETCONSOLE},${PUPPETCONSOLE}.${DOMAIN},${PUPPETCONSOLE},${PUPPETCONSOLEPG}.${DOMAIN},${PUPPETCONSOLEPG}"

    confirm_install "${MOM_PUPPETCONSOLE}"

    if ! has_pe; then
      install_pe $ANSWERS
    fi

    echo "==> Setting certificate alternate names"
    /opt/puppet/bin/augtool set '/files//puppet.conf/main/dns_alt_names' "${ALT_NAMES}"


    echo "==> Removing SSL data"
    rm -rf /etc/puppetlabs/puppet/ssl
    rm -f /opt/puppet/share/puppet-dashboard/certs/*

    echo "==> Running Puppet agent to create CSR"
    echo "==> You will see an error here indicating that the certificate"
    echo "==> contains alternate names and cannot be automatically signed."
    echo "==> That's okay."
    /opt/puppet/bin/puppet agent -t

    ca_sign_cert "${MOM_PUPPETCONSOLE}.${DOMAIN}"

    ca_clean_cert "pe-internal-dashboard"

    echo "==> Running Puppet agent to retrieve signed certificate"
    echo "    You will see some errors here, but that should be okay."
    /opt/puppet/bin/puppet agent -t

    apply_puppet_role "${ROLE}"
    echo
    echo "==> ${MOM_PUPPETCONSOLE} complete"

  ;;
  #############################################################################
  ## Tenant Compile master
  #############################################################################
  4|$TENANT_PUPPETMASTER)
    ## apply the tenant master role
    ANSWERS="tenant.master"
    ROLE="role::puppet::tenant::master"

    confirm_install "${TENANT_PUPPETMASTER}"

    if ! has_pe; then
      install_pe $ANSWERS
    fi

    apply_puppet_role "${ROLE}"
    echo "==> ${TENANT_PUPPETMASTER} complete"

    # remove the tenant ssldir
    PUPPET_AGENT_SSLDIR=$(puppet config print ssldir)
    echo "==> Moving ${PUPPET_AGENT_SSLDIR}"
    mv $PUPPET_AGENT_SSLDIR "${PUPPET_AGENT_SSLDIR}.orig"

    # Do a puppet agent run against the ca server to generate a CSR
    # (this can be signed automatically if autosigning is enabled)
    echo "==> Regenerating SSL certificates"
    puppet agent -t --server $(puppet config print ca_server)

    echo "Please sign the certificate on the MoM and restart pe-httpd"
    # At this point, we have to manually sign the cert and restart pe-httpd.
    # This is because we can't autosign certs with alt names.
  ;;
  #############################################################################
  ## Primary and Secondary PuppetDB
  #############################################################################
  5|$TENANT_PUPPETDB)
    ANSWERS="tenant.puppetdb"
    NAME="${TENANT_PUPPETDB}"

    #ALT_NAMES="${NAME},${PUPPETDB}.${DOMAIN},${PUPPETDB},${PUPPETDBPG}.${DOMAIN},${PUPPETDBPG}"
    ROLE="role::puppet::tenant::puppetdb"

    confirm_install "${NAME}"

    if ! has_pe; then
      install_pe $ANSWERS
    fi

    #echo "==> Setting certificate alternate names"
    #/opt/puppet/bin/augtool set '/files//puppet.conf/main/dns_alt_names' "${ALT_NAMES}"

    # Apply the puppetdb role once to get everything pointing to the ca correctly
    apply_puppet_role "${ROLE}"

    # Remove the SSL data so we can generate a new cert from the global CA
    echo "==> Removing SSL data"
    rm -rf /etc/puppetlabs/puppet/ssl
    rm -rf /etc/puppetlabs/puppetdb/ssl

    # Regenerate CSR. Should be autosigned
    echo "==> Running Puppet agent to create CSR"
    /opt/puppet/bin/puppet agent -t

    # Apply the puppetdb role a second time to recreate the internal certs.
    # There will be an error here when we attempt to submit the report.
    # It will go away when pe-puppetdb is restarted
    apply_puppet_role "${ROLE}"

    echo "==> Restarting the pe-puppetdb service"
    service pe-puppetdb restart

    echo
    echo "==> ${NAME} complete"
  ;;
  #############################################################################
  ## Tenant Console
  #############################################################################
  6|$TENANT_PUPPETCONSOLE)
    ANSWERS="tenant.console"
    ROLE="role::puppet::tenant::console"
    #ALT_NAMES="${TENANT_PUPPETCONSOLE},${PUPPETCONSOLE}.${DOMAIN},${PUPPETCONSOLE},${PUPPETCONSOLEPG}.${DOMAIN},${PUPPETCONSOLEPG}"

    confirm_install "${TENANT_PUPPETCONSOLE}"

    if [ ! -d "/opt/puppet/share/puppet-dashboard/certs" ]; then
      echo "#######################################################################"
      echo "# You must copy the /opt/puppet/share/puppet-dashboard/certs"
      echo "# directory from ${MOM_PUPPETCONSOLE}.${DOMAIN} to the same location on"
      echo "# this node.  Ensure that permissions and ownership are preserved"
      echo "#"
      echo "# Example:"
      echo "#   On this node:"
      echo "     mkdir -p /opt/puppet/share/puppet-dashboard"
      echo "     chown uid:gid /opt/puppet/share/puppet-dashboard"
      echo "       (where 'uid/gid' is the uid/gid of puppet-dashboard on ${MOM_PUPPETCONSOLE})"
      echo
      echo "     rsync -avzp -e 'ssh' \\"
      echo "        ${MOM_PUPPETCONSOLE}:/opt/puppet/share/puppet-dashboard/certs/ \\"
      echo "        /opt/puppet/share/puppet-dashboard/certs/"
      echo "#######################################################################"
      exit 1
    fi

    if ! has_pe; then
      install_pe $ANSWERS
    fi

    apply_puppet_role "${ROLE}"
    #echo "==> Setting certificate alternate names"
    #/opt/puppet/bin/augtool set '/files//puppet.conf/main/dns_alt_names' "${ALT_NAMES}"

    echo "==> Removing SSL data"
    rm -rf /etc/puppetlabs/puppet/ssl

    echo "==> Running Puppet agent against CA to create CSR"
    echo "==> You will see an error here indicating that the certificate"
    echo "==> contains alternate names and cannot be automatically signed."
    echo "==> That's okay."
    /opt/puppet/bin/puppet agent -t --server $(puppet config print ca_server)

    #ca_sign_cert "${TENANT_PUPPETCONSOLE}.${DOMAIN}"

    #echo "==> Running Puppet agent to retrieve signed certificate"
    #echo "    You will see some errors here, but that should be okay."
    #/opt/puppet/bin/puppet agent -t

    #apply_puppet_role "${ROLE}"

    echo "==> ${TENANT_PUPPETCONSOLE} complete"
  ;;
  #############################################################################
  ## Additional masters
  #############################################################################
  7)
    ANSWERS="master"
    ROLE="role::puppet::master"

    confirm_install "additional master ($(hostname -f))"

    if ! has_pe; then
      install_pe $ANSWERS
    fi

    apply_puppet_role "${ROLE}"

    echo "==> Removing SSL data"
    rm -rf /etc/puppetlabs/puppet/ssl

    echo "==> Running Puppet agent against the CA to create CSR"
    echo "==> You will see an error here indicating that the certificate"
    echo "==> contains alternate names and cannot be automatically signed."
    echo "==> That's okay."
    /opt/puppet/bin/puppet agent -t --server ${MOM_PUPPETCA}.${DOMAIN}

    ca_sign_cert "$(hostname -f)"

    echo "==> Removing stale ActiveMQ broker keystores"
    rm -f /etc/puppetlabs/activemq/broker.ks
    rm -f /etc/puppetlabs/activemq/broker.ts

    echo "==> Running Puppet agent against the primary CA to retrieve signed certificate"
    echo "    You will see some errors here, but that should be okay."
    /opt/puppet/bin/puppet agent -t --server ${MOM_PUPPETCA}.${DOMAIN}

    echo "==> Restarting pe-httpd restart..."
    service pe-httpd restart

    echo "==> Running puppet agent against myself"
    /opt/puppet/bin/puppet agent -t

    echo "********************************************************************"
    echo "You'll need to add this master's certname to the list of PuppetDB and"
    echo "Console authorizations.  Refer to the documentation for steps on this."
    echo "Hint: This should be added to the profile module's params class."
    echo
    echo "r10k needs to be ran to create the environments and install modules."
    echo "You can do this by executing:"
    echo "   r10k deploy environment -pv"
    echo
    read -p "=> Should we run r10k now? [y/n] " run_r10k
    if [ "${run_r10k}" == "y" ]; then
      /opt/puppet/bin/r10k deploy environment -pv
    fi
    echo "==> $(hostname -f) complete"
  ;;
  *)
    echo "Unknown selection: ${server_role}"
    exit 1
  ;;
esac


