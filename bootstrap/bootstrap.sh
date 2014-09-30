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
echo "  [1] Primary CA/Master         ${PUPPETCA01}"
echo "  [2] Primary PuppetDB/pgsql    ${PUPPETDB01}"
echo "  [3] Primary Console/pgsql     ${PUPPETCONSOLE01}"
echo
echo "  [4] Secondary CA/Master       ${PUPPETCA02}"
echo "  [5] Secondary PuppetDB        ${PUPPETDB02}"
echo "  [6] Secondary Console         ${PUPPETCONSOLE02}"
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
  ## Primary CA
  #############################################################################
  1|$PUPPETCA01)
    ## Primary CA
    ANSWERS="puppetca01"
    ROLE="role::puppet::ca"

    confirm_install "${PUPPETCA01}"

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
    echo "r10k needs to be ran to create the environments and install modules."
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
    echo "==> ${PUPPETCA01} complete"
  ;;
  #############################################################################
  ## Secondary CA
  #############################################################################
  4|$PUPPETCA02)
    ## Secondary CA
    ANSWERS="puppetca02"
    ROLE="role::puppet::ca"

    confirm_install "${PUPPETCA02}"

    if ! has_pe; then
      install_pe $ANSWERS
    fi

    apply_puppet_role "${ROLE}"
    echo "==> ${PUPPETCA02} complete"

    echo -e "${txtylw}"
    echo "#######################################################################"
    echo -e "${txtrst}"
    echo "# You will need to copy the /etc/puppetlabs/puppet/ssl directory from"
    echo "# ${PUPPETCA01}.${DOMAIN} to the same location on this node."
    echo "# Ensure that permissions and ownership are preserved"
    echo "#"
    echo "# You should do this after every other node is spun up."
    echo "# After copied, run the following on this node:"
    echo "#    service pe-httpd restart"
    echo "#    rm -f /etc/puppetlabs/activemq/broker.*"
    echo "#    puppet agent -t --server ${PUPPETCA01}.${DOMAIN}"
    echo "#    r10k deploy environment -pv"
    echo "#"
    echo "# Note that this CA needs to be classified with 'role::puppet::ca'"
    echo "# prior to doing the agent run."
    echo -e "${txtylw}"
    echo "#######################################################################"
    echo -e "${txtrst}"
  ;;
  #############################################################################
  ## Primary and Secondary PuppetDB
  #############################################################################
  2|5|$PUPPETDB01|$PUPPETDB02)
    case $server_role in
      2|$PUPPETDB01)
        ## Primary PuppetDB server
        ANSWERS="puppetdb01"
        NAME="${PUPPETDB01}"
      ;;
      5|$PUPPETDB02)
        ANSWERS="puppetdb02"
        NAME="${PUPPETDB02}"
      ;;
    esac
    ALT_NAMES="${NAME},${PUPPETDB}.${DOMAIN},${PUPPETDB},${PUPPETDBPG}.${DOMAIN},${PUPPETDBPG}"
    ROLE="role::puppet::puppetdb"

    confirm_install "${NAME}"

    if ! has_pe; then
      install_pe $ANSWERS
    fi

    echo "==> Setting certificate alternate names"
    /opt/puppet/bin/augtool set '/files//puppet.conf/main/dns_alt_names' "${ALT_NAMES}"

    echo "==> Removing SSL data"
    rm -rf /etc/puppetlabs/puppet/ssl
    rm -rf /etc/puppetlabs/puppetdb/ssl

    ca_clean_cert "${NAME}.${DOMAIN}"

    echo "==> Running Puppet agent to create CSR"
    echo "==> You will see an error here indicating that the certificate"
    echo "==> contains alternate names and cannot be automatically signed."
    echo "==> That's okay."
    /opt/puppet/bin/puppet agent -t

    ca_sign_cert "${NAME}.${DOMAIN}"

    echo "==> Running Puppet agent to retrieve signed certificate"
    echo "    You will see some errors here, but that should be okay."
    /opt/puppet/bin/puppet agent -t

    apply_puppet_role "${ROLE}"

    echo "==> Restarting the pe-puppetdb service"
    service pe-puppetdb restart

    echo
    echo "==> ${NAME} complete"
  ;;
  #############################################################################
  ## Primary Console
  #############################################################################
  3|$PUPPETCONSOLE01)
    ANSWERS="puppetconsole01"
    ROLE="role::puppet::console"
    ALT_NAMES="${PUPPETCONSOLE01},${PUPPETCONSOLE}.${DOMAIN},${PUPPETCONSOLE},${PUPPETCONSOLEPG}.${DOMAIN},${PUPPETCONSOLEPG}"

    confirm_install "${PUPPETCONSOLE01}"

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

    ca_sign_cert "${PUPPETCONSOLE01}.${DOMAIN}"

    ca_clean_cert "pe-internal-dashboard"

    echo "==> Running Puppet agent to retrieve signed certificate"
    echo "    You will see some errors here, but that should be okay."
    /opt/puppet/bin/puppet agent -t

    apply_puppet_role "${ROLE}"
    echo
    echo "==> ${PUPPETCONSOLE01} complete"

  ;;
  #############################################################################
  ## Secondary Console
  #############################################################################
  6|$PUPPETCONSOLE02)
    ANSWERS="puppetconsole02"
    ROLE="role::puppet::console"
    ALT_NAMES="${PUPPETCONSOLE02},${PUPPETCONSOLE}.${DOMAIN},${PUPPETCONSOLE},${PUPPETCONSOLEPG}.${DOMAIN},${PUPPETCONSOLEPG}"

    confirm_install "${PUPPETCONSOLE02}"

    if [ ! -d "/opt/puppet/share/puppet-dashboard/certs" ]; then
      echo "#######################################################################"
      echo "# You must copy the /opt/puppet/share/puppet-dashboard/certs"
      echo "# directory from ${PUPPETCONSOLE01}.${DOMAIN} to the same location on"
      echo "# this node.  Ensure that permissions and ownership are preserved"
      echo "#"
      echo "# Example:"
      echo "#   On this node:"
      echo "     mkdir -p /opt/puppet/share/puppet-dashboard"
      echo "     chown uid:gid /opt/puppet/share/puppet-dashboard"
      echo "       (where 'uid/gid' is the uid/gid of puppet-dashboard on ${PUPPETCONSOLE01})"
      echo
      echo "     rsync -avzp -e 'ssh' \\"
      echo "        ${PUPPETCONSOLE01}:/opt/puppet/share/puppet-dashboard/certs/ \\"
      echo "        /opt/puppet/share/puppet-dashboard/certs/"
      echo "#######################################################################"
      exit 1
    fi

    if ! has_pe; then
      install_pe $ANSWERS
    fi

    echo "==> Setting certificate alternate names"
    /opt/puppet/bin/augtool set '/files//puppet.conf/main/dns_alt_names' "${ALT_NAMES}"

    echo "==> Removing SSL data"
    rm -rf /etc/puppetlabs/puppet/ssl

    echo "==> Running Puppet agent to create CSR"
    echo "==> You will see an error here indicating that the certificate"
    echo "==> contains alternate names and cannot be automatically signed."
    echo "==> That's okay."
    /opt/puppet/bin/puppet agent -t

    ca_sign_cert "${PUPPETCONSOLE02}.${DOMAIN}"

    echo "==> Running Puppet agent to retrieve signed certificate"
    echo "    You will see some errors here, but that should be okay."
    /opt/puppet/bin/puppet agent -t

    apply_puppet_role "${ROLE}"

    echo "==> ${PUPPETCONSOLE02} complete"
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
    /opt/puppet/bin/puppet agent -t --server ${PUPPETCA01}.${DOMAIN}

    ca_sign_cert "$(hostname -f)"

    echo "==> Removing stale ActiveMQ broker keystores"
    rm -f /etc/puppetlabs/activemq/broker.ks
    rm -f /etc/puppetlabs/activemq/broker.ts

    echo "==> Running Puppet agent against the primary CA to retrieve signed certificate"
    echo "    You will see some errors here, but that should be okay."
    /opt/puppet/bin/puppet agent -t --server ${PUPPETCA01}.${DOMAIN}

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


