#/bin/bash

#	KStars and INDI Development Setup Script
#﻿   Copyright (C) 2024 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

# This gets the directory from which this script is running so it can access any files there such as other scripts or the archive files.
# It also uses that to get the top folder file name so that it can use that in the scripts.
# Beware of changing the path to the top folder, you will have to run the script again if you do so since it will break links.
	DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
	
# This function checks to see if a connection to a website exists.
	function checkForConnection
	{
		testCommand=$(curl -Is $2 | head -n 1)
		if [[ "${testCommand}" == *"OK"* || "${testCommand}" == *"Moved"* || "${testCommand}" == *"HTTP/2 301"* || "${testCommand}" == *"HTTP/2 200"* ]]
  		then 
  			echo "$1 connection was found."
  		else
  			echo "$1, ($2), a required connection, was not found, aborting script."
  			echo "If you would like the script to run anyway, please comment out the line that tests this connection in build-kstars.sh."
  			exit
		fi
	}
	
# This function will download a git repo if needed, and will update it if not
# Note that this function should only be used on the real repo, not the forked one.  For that see the next function.

	function downloadOrUpdateRepository
	{
		if [ -n "${BUILD_OFFLINE}" ]
		then
			if [ ! -d "${SRC}" ]
			then
				display "The source code for ${PACKAGE_NAME} is not downloaded, it cannot be built offline without that, exiting now."
				exit
			fi
		else
			mkdir -p "${SRC_FOLDER}"
			if [ ! -d "${SRC}" ]
			then
				display "Downloading ${PACKAGE_NAME} GIT repository"
				cd "${SRC_FOLDER}"
				git clone "${REPO}"
			else
				display "Updating ${PACKAGE_NAME} GIT repository"
				cd "${SRC}"
				git pull
			fi
		fi
	}
	
# This function will create a Fork on Github or update an existing fork
# It will also do all the functions of the function above for a Forked Repo

	function createOrUpdateFork
	{
		if [ -n "${BUILD_OFFLINE}" ]
		then
			if [ ! -d "${SRC}" ]
			then
				display "The forked source code for ${PACKAGE_NAME} is not downloaded, it cannot be built offline without that, exiting now."
				exit
			fi
		else
			# This will download the fork if needed, or update it to the latest version if necessary
			mkdir -p "${FORKED_SRC_FOLDER}"
			if [ ! -d "${SRC}" ]
			then
				display "The Forked Repo is not downloaded, checking if a ${PACKAGE_NAME} Fork is needed."
				# This will check to see if the repo already exists
				git ls-remote ${FORKED_REPO} -q >/dev/null 2>&1
				if [ $? -eq 0 ]
				then
					echo "The Forked Repo already exists, it can just get cloned."
				else
					echo "The ${PACKAGE_NAME} Repo has not been forked yet, please go to ${REPO} and fork it first, then run the script again.  Your fork should be at: ${FORKED_REPO}"	
					exit
				fi
			
				display "Downloading ${PACKAGE_NAME} GIT repository"
				cd "${FORKED_SRC_FOLDER}"
				git clone "${FORKED_REPO}"
			fi
		
			# This will attempt to update the fork to match the upstream master
			display "Updating ${PACKAGE_NAME} GIT repository"
			cd "${SRC}"
			git remote add upstream "${REPO}"
			git fetch upstream
			git pull upstream master
			git push
		fi
	}

# This function will prepare the Source Directory for building by calling the methods above.

	function prepareSourceDirectory
	{
		if [[ "${USE_FORKED_REPO}" == "Yes" ]]
		then
			createOrUpdateFork 
		else
			downloadOrUpdateRepository
		fi
	}

# This function shortens the amount of code needed to clean the build directories if desired, make them if needed, and enter them
# $1 is the path to the build directory, $2 is the name of the package to be built
	function setupAndEnterBuildDir
	{
		display "Setting up and entering ${PACKAGE_NAME} build directory: ${BUILD}"
		if [ -d "${BUILD}" ]
		then
			if [ -n "$REMOVE_ALL" ]
			then
				rm -r "${BUILD}"/*
			fi
		else
			mkdir -p "${BUILD}"
		fi
		cd "${BUILD}"
	}
	
# This function will build the package in the build directory

	function buildPackage
	{
		setupAndEnterBuildDir
		
		if [ -n "${BUILD_XCODE}" ]
		then
			display "Building ${PACKAGE_NAME} using XCode"
			cmake -G Xcode ${GENERAL_BUILD_OPTIONS} ${PACKAGE_BUILD_OPTIONS} "${SRC}"
			xcodebuild -project "${XCODE_PROJECT_NAME}".xcodeproj -alltargets -configuration Debug CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" OTHER_CODE_SIGN_FLAGS="--deep"
		else
			display "Building ${PACKAGE_NAME} with the following options: ${GENERAL_BUILD_OPTIONS} ${PACKAGE_BUILD_OPTIONS}"
			cmake ${GENERAL_BUILD_OPTIONS} ${PACKAGE_BUILD_OPTIONS} "${SRC}"
			make -j $(expr $(sysctl -n hw.ncpu) + 2)
			make install
		fi
	}
	
########################################################################################
# This is where the main part of the script starts!
#

# Prepare to run the script by setting all of the environment variables	
# If you want to customize any of those variables, you can edit this file
	source ${DIR}/build-env.sh

# Before starting, check to see if the remote servers are accessible
	if [ -n "${BUILD_OFFLINE}" ]
	then
		display "Not checking connections because build-offline was selected.  All repos must already be downloaded to the source folders."
	else
		display "Checking Connections"
	
		#checkForConnection "INDI Repository" "${INDI_REPO}"
		#checkForConnection "INDI 3rd Party Repository" "${THIRDPARTY_REPO}"
		#checkForConnection "KStars Repository" "${KSTARS_REPO}"
		#checkForConnection "INDI Web Manager Repository" "${WEBMANAGER_REPO}"
	fi

## This makes sure that if the build XCODE option is selected, the user has specified a CODE_SIGN_IDENTITY because if not, it won't work properly
	if [ -n "${BUILD_XCODE}" ]
	then
		if [ -n "${CODE_SIGN_IDENTITY}" ]
		then
			display "Building for XCode and code signing with the identity ${CODE_SIGN_IDENTITY}."
		else
			display "You have not specified a CODE_SIGN_IDENTITY, but you requested an XCode Build.  A Certificate is required for an XCode Build.  Make sure to get a certificate either from the Apple Developer program or from KeyChain Access on your Mac (A Self Signed Certificate is fine as long as you don't want to distribute KStars).  Before you run this script, execute the command: export CODE_SIGN_IDENTITY=XXXXXXX"
			exit 1
		fi
	fi

# The following if statements set up each of the source and build folders for each build based upon the options you selected in build-env.
# This includes whether you want to use Xcode or not for the whole build and whether you want to use your own fork or not for each build

if [ -n "${BUILD_XCODE}" ]
then
	export BUILD_FOLDER="${XCODE_BUILD_FOLDER}"
	export FORKED_BUILD_FOLDER="${FORKED_XCODE_BUILD_FOLDER}"
fi

# This checks if any of the path variables are blank, since if they are blank, it could start trying to do things in the / folder, which is not good
	if [[ -z ${DIR} || -z ${TOP_FOLDER} || -z ${SRC_FOLDER} || -z ${FORKED_SRC_FOLDER} || -z ${BUILD_FOLDER} || -z ${DEV_ROOT} ]]
	then
  		display "One or more critical directory variables is blank, please edit build-env.sh."
  		exit 1
	fi
	
# This checks the most important variables to see if the paths exist.  If they don't, it terminates the script with a message.
	if [ ! -d "${CRAFT_ROOT}" ]
	then
		display "Craft Does Not Exist at the directory specified, please install Craft or edit this script."
		exit 1
	fi
	
# This sets the top build and source folders based on the options for this particular package
	if [[ "${USE_FORKED_REPO}" == "Yes" ]]
	then
		export TOP_SRC_FOLDER="${FORKED_SRC_FOLDER}"
		export TOP_BUILD_FOLDER="${FORKED_BUILD_FOLDER}"
	else
		export TOP_SRC_FOLDER="${SRC_FOLDER}"
		export TOP_BUILD_FOLDER="${BUILD_FOLDER}"
	fi

