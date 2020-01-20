#!/bin/bash

#	Submit Changes script
#﻿   Copyright (C) 2019 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# Prepare to run the script by setting all of the environment variables	
	source "${DIR}/build-env.sh"
	
display "This script will submit your INDI Core Changes in the forked repo.  You must have made changes in the forked-src folder for this to work."

# This checks if any of the path variables are blank, since if they are blank, it could start trying to do things in the / folder, which is not good
	if [[ -z ${DIR} || -z ${TOP_FOLDER} || -z ${SRC_FOLDER} || -z ${FORKED_SRC_FOLDER} || -z ${INDI_SRC_FOLDER} || -z ${THIRDPARTY_SRC_FOLDER} || -z ${KSTARS_SRC_FOLDER} || -z ${WEBMANAGER_SRC_FOLDER} || -z ${BUILD_FOLDER} || -z ${DEV_ROOT} || -z ${sourceKStarsApp} || -z ${sourceINDIWebManagerApp} ]]
	then
  		display "One or more critical directory variables is blank, please edit build-env.sh."
  		exit 1
	fi

# Check to see that the user has actually already make a forked source folder for INDI
if [ ! -d "${FORKED_SRC_FOLDER}/indi" ]
then
	echo "No Forked INDI git repo detected.  Please make sure to run setup.sh first and make changes to submit."
	exit
fi

# Change to the forked source directory so that the changes can be submitted.
	cd "${FORKED_SRC_FOLDER}/indi"
	
# Get the commit message, commit the changes, and make a pull request.
	read -p "Please type a message for your commit: " commitMsg
	git commit -am "${commitMsg}"
	git push
	display "Please go to https://github.com/${FORKED_INDI_REPO} and click the submit pull request button if you are ready to make your pull request, or make other changes and other commits first."



		