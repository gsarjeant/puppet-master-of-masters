# Shell provisioner script to install PE on a system,
# using the PE installer and an answer file

# Input variables
PE_INSTALLER_NAME=$1
ANSWER_FILE_NAME=$2

# Validation
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

PE_BASEDIR='/vagrant'

# Mocking RPM installation of PE installer and answer files
# vagrant location to pull PE tarball from (will be bundeled in RPM)
PE_INSTALLER_SRC="${PE_BASEDIR}/${PE_INSTALLER_NAME}"
# Directory to extract PE installer to (will be created by RPM)
PE_INSTALLER_ROOT='/apps/pe-installer'
# Directory to extract answer files to (will be created by RPM)
PE_INSTALLER_ANSWERS_ROOT='/apps/pe-answers'
# Directory that contains the PE installer after extraction
PE_INSTALLER_DIR="${PE_INSTALLER_ROOT}/$(echo $PE_INSTALLER_NAME | sed -e 's/.tar.gz//')"

# Create the PE installer directory and extract the installer
# NOTE: The RPM is going to handle this
mkdir -p $PE_INSTALLER_ROOT
cd $PE_INSTALLER_ROOT
tar -xvzf $PE_INSTALLER_SRC

# Create the answer file directory and copy the answer file
# NOTE: The answer file RPM will handle this
ANSWERS_SRC="${PE_BASEDIR}/bootstrap/answers/${ANSWER_FILE_NAME}.txt"
ANSWERS_DEST="${PE_INSTALLER_ANSWERS_ROOT}/${ANSWER_FILE_NAME}"
mkdir -p $PE_INSTALLER_ANSWERS_ROOT
cp $ANSWERS_SRC $ANSWERS_DEST

# Install PE with the answer file
"${PE_INSTALLER_DIR}/puppet-enterprise-installer" -a ${ANSWERS_DEST}
