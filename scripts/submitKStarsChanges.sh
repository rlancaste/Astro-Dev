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
	
display "This script will submit your KStars Changes via Phabricator.  It will download Phabricator and arcanist if needed, and either submit changes to an existing diff or make a new one if desired."

# This checks if any of the path variables are blank, since if they are blank, it could start trying to do things in the / folder, which is not good
	if [[ -z ${DIR} || -z ${TOP_FOLDER} || -z ${SRC_FOLDER} || -z ${FORKED_SRC_FOLDER} || -z ${INDI_SRC_FOLDER} || -z ${THIRDPARTY_SRC_FOLDER} || -z ${KSTARS_SRC_FOLDER} || -z ${WEBMANAGER_SRC_FOLDER} || -z ${BUILD_FOLDER} || -z ${DEV_ROOT} || -z ${sourceKStarsApp} || -z ${KStarsApp} || -z ${sourceINDIWebManagerApp} || -z ${INDIWebManagerApp} ]]
	then
  		display "One or more critical directory variables is blank, please edit build-env.sh."
  		exit 1
	fi

# Download Arcanist and Phabricator if they don't exist yet.
if [ ! -d "${TOP_FOLDER}"/arc ]
then
	display "Downloading Arcanist and Phabricator for use with KStars."
	mkdir -p "${TOP_FOLDER}"/arc
	cd "${TOP_FOLDER}"/arc
	git clone https://github.com/phacility/libphutil.git
	git clone https://github.com/phacility/arcanist.git
fi

# Check to see that the user has actually already downloaded and built KStars, Craft, etc.
if [ ! -d "${KSTARS_SRC_FOLDER}" ]
then
	echo "No KStars git repo detected.  Please make sure to run setup.sh first and make changes to submit."
	exit
fi

# Export the Arcanist path so that it can be run.
	export PATH="${TOP_FOLDER}"/arc/arcanist/bin:$PATH
# Change to the kstars source directory so that the changes can be submitted.
	cd "${KSTARS_SRC_FOLDER}"
# Check with the user to see if they want to create a new diff or change the current one.
	read -p "Do you either want to create a new arcanist diff (1) or update an existing one (2)? " arcDiffOpts

	if [ "$arcDiffOpts" == "1" ]
	then
		echo "Creating a new diff."
		arc diff --create
	elif [ "$arcDiffOpts" == "2" ]
	then
		echo "Updating the existing diff (if one exists already)."
		arc diff
	else
		echo "That was an invalid option, please select either 1 or 2 when you run the script."
	fi



		