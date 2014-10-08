#!/bin/bash

source './answers/common.txt'
PE_INSTALLER_ANSWERS_ROOT='/apps/pe-answers'
PE_INSTALLER_ROOT='/apps/pe-installer/puppet-enterprise-3.3.1-el-6-x86_64'

case $(hostname) in
  $MOM_MASTER)
    ANSWER_FILE_NAME='mom.master.txt'
    ;;
  $MOM_PUPPETDB)
    ANSWER_FILE_NAME='mom.puppetdb.txt'
    ;;
  $MOM_CONSOLE)
    ANSWER_FILE_NAME='mom.console.txt'
    ;;
  $TENANT_MASTER)
    ANSWER_FILE_NAME='tenant.master.txt'
    ;;
  $TENANT_PUPPETDB)
    ANSWER_FILE_NAME='tenant.puppetdb.txt'
    ;;
  $TENANT_CONSOLE)
    ANSWER_FILE_NAME='tenant.console.txt'
    ;;
esac

PE_INSTALLER_FILE="${PE_INSTALLER_ROOT}/puppet-enterprise-installer"
PE_INSTALLER_ANSWER_FILE="${PE_INSTALLER_ANSWERS_ROOT}/${ANSWER_FILE_NAME}"

echo "===> Installing puppet with command ${PE_INSTALLER_FILE} -a ${PE_INSTALLER_ANSWER_FILE}"
${PE_INSTALLER_FILE} -a ${PE_INSTALLER_ANSWER_FILE}
