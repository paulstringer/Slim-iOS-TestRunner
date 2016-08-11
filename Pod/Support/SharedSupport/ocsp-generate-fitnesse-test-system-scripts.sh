#!/bin/sh
TEST_SYSTEM_DIR=$1
SHARED_SUPPORT_FILE_PATH=$(dirname $0)
SUPPORT_FILE_PLATFORM_PATH=$SHARED_SUPPORT_FILE_PATH/..

# Validate Project Build Settings

function validateEnvironment {
	if [ -z "${TEST_SYSTEM_DIR}" ]; then
		mkdir -p "${TEST_SYSTEM_DIR}"
	fi
}

# Export Build Environment to Bundles own Location

function exportTestSystemBuildSettings {
	ENV_TARGET=${TEST_SYSTEM_DIR}/env.sh
	echo "[OCSP] Exporting Test System Executable Environment -> $ENV_TARGET"
    mkdir -p "$(dirname "$ENV_TARGET")" && touch "$ENV_TARGET"
    export | egrep '(INSTALL_DIR)|(PRODUCT_NAME)|(TARGET_BUILD_DIR)|(EXECUTABLE_FOLDER_PATH)|(DEPLOYMENT_TARGET_SUGGESTED_VALUES)|(EXECUTABLE_PATH)' > $ENV_TARGET
}

# Write Test System Script To The Project's Root Directory
	
function writeTestSystemRunScript {
	
	local OCSP_PLATFORM="${PLATFORM_NAME}"

	if [ "${PLATFORM_NAME}" == "macosx" ]; then
		OCSP_PLATFORM="OSX"
	elif [[ "${PLATFORM_NAME}" =~ .*iphone* ]]; then
		OCSP_PLATFORM="iOS"
	fi

	TESTRUNNER_SCRIPT_NAME=OCSlimProjectTestRunner
	TESTRUNNER_SOURCE=$SUPPORT_FILE_PLATFORM_PATH/${OCSP_PLATFORM}/RunTestsTargetWithSlimPort
	TESTRUNNER_TARGET=${PROJECT_DIR}/$TESTRUNNER_SCRIPT_NAME.sh
	TESTRUNNER_ERRORLOG=$TESTRUNNER_SCRIPT_NAME-Error.log
	echo "[OCSP] Selected Test System Platform -> $OCSP_PLATFORM"
	echo "[OCSP] Selected Test System Run Script -> $TESTRUNNER_SOURCE"	
	echo "[OCSP] Writing Test System Script -> $TESTRUNNER_TARGET  (This must match the defined TEST_RUNNER value set in 'FitnesseRoot/content.txt')"

    if [ -f "$TESTRUNNER_TARGET" ]; then
        rm $TESTRUNNER_TARGET
    fi
    
    echo '#!/bin/bash' > $TESTRUNNER_TARGET
    echo SLIM_PORT='$1' >> $TESTRUNNER_TARGET
	echo ENV_FILE_PATH=$ENV_TARGET >> $TESTRUNNER_TARGET 
    echo $TESTRUNNER_SOURCE '$ENV_FILE_PATH' '$SLIM_PORT' 2> >(tee $TESTRUNNER_ERRORLOG >&2) >> $TESTRUNNER_TARGET 
    echo  "if [ -z $(cat $TESTRUNNER_ERRORLOG) ] ; then rm $TESTRUNNER_ERRORLOG ; fi" >> $TESTRUNNER_TARGET
    chmod +x $TESTRUNNER_TARGET
    
}

# Symbolic Link Control Script for Launching Fitnesse convieniently to Project Root

function linkCtlScriptToProjectRoot {
    
    local CTL_SCRIPTNAME="LaunchFitnesse"
	local CTL_SOURCE=$SHARED_SUPPORT_FILE_PATH/$CTL_SCRIPTNAME
	local CTL_TARGET=${PROJECT_DIR}/$CTL_SCRIPTNAME

	echo "[OCSP] Control Script Resource Path -> $CTL_SOURCE"	
	echo "[OCSP] Linking Control Script $ ./$CTL_SCRIPTNAME -> $CTL_TARGET"	
	
    if [ -L $CTL_TARGET ]; then
        unlink $CTL_TARGET
    fi
    
    ln -s $CTL_SOURCE $(dirname "$CTL_TARGET")
}

function main {
	validateEnvironment
	exportTestSystemBuildSettings
	writeTestSystemRunScript
	linkCtlScriptToProjectRoot
}

main