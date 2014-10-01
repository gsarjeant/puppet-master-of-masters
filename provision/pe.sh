# Shell provisioner script to install PE on a system,
# using the PE installer and an answer file

PE_INSTALLER_NAME=$1
ANSWER_FILE_NAME=$2

if [ "${PE_INSTALLER_NAME}x" == "x" ]
then
  echo "Please specify the PE installer filename"
  exit 1
fi

if [ "${ANSWER_FILE_NAME}x" == "x" ]
then
  echo "Please specify the answer file name"
  exit 1
fi

#ANSWERS_SRC="/vagrant/answers/${ANSWER_FILE_NAME}"
ANSWERS_SRC="/vagrant/bootstrap/answers/${ANSWER_FILE_NAME}.txt"
ANSWERS_DEST="/root/${ANSWER_FILE_NAME}"

cp $ANSWERS_SRC $ANSWERS_DEST

# Extract the PE installer
PE_INSTALLER_SRC="/vagrant/${PE_INSTALLER_NAME}"
PE_INSTALLER_DIR="/root/$(echo $PE_INSTALLER_NAME | sed -e 's/.tar.gz//')"

# Install PE with the answer file
cd /root
tar -xvzf $PE_INSTALLER_SRC
"${PE_INSTALLER_DIR}/puppet-enterprise-installer" -a ${ANSWERS_DEST}
