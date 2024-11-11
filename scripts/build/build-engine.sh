#/bin/bash

#	KStars and INDI Related Astronomy Software Development Build Scripts
#﻿   Copyright (C) 2024 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

# This gets the directory from which this script is running so it can access files or other scripts in the repo.
	DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )


# This function links a file or folder in the dev directory to one in the craft-root directory
	function craftLink
	{
		ln -s ${CRAFT_ROOT}/$1 ${DEV_ROOT}/$1
	}
	
# This function links a file or folder in the dev directory to one in the Homebrew-root directory
	function homebrewLink
	{
		ln -s ${HOMEBREW_ROOT}/$1 ${DEV_ROOT}/$1
	}

# This function will download a git repo if needed, and will update it if not.
# Note that this function should only be used on the primary repo, not the forked one.  For that see the next function.

	function downloadOrUpdateRepository
	{
		if [ -n "${BUILD_OFFLINE}" ]
		then
			if [ ! -d "${SRC_DIR}" ]
			then
				display "The source code for ${PACKAGE_NAME} is not downloaded, it cannot be built offline without that, exiting now."
				exit
			fi
		else
			checkForConnection "${PACKAGE_NAME}" "${REPO}"
			mkdir -p "${TOP_SRC_DIR}"
			if [ ! -d "${SRC_DIR}" ]
			then
				display "Downloading ${PACKAGE_NAME} GIT repository"
				cd "${TOP_SRC_DIR}"
				git clone "${REPO}"
			else
				display "Updating ${PACKAGE_NAME} GIT repository"
				cd "${SRC_DIR}"
				git pull
			fi
		fi
	}
	
# This function will create a Fork on Github or update an existing fork.
# It will also do all the functions of the function above for a Forked Repo.

	function createOrUpdateFork
	{
		if [ -n "${BUILD_OFFLINE}" ]
		then
			if [ ! -d "${SRC_DIR}" ]
			then
				display "The forked source code for ${PACKAGE_NAME} is not downloaded, it cannot be built offline without that, exiting now."
				exit
			fi
		else
			checkForConnection "${PACKAGE_NAME}" "${FORKED_REPO_HTML}"
			# This will download the fork if needed, or update it to the latest version if necessary
			mkdir -p "${TOP_SRC_DIR}"
			if [ ! -d "${SRC_DIR}" ]
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
				cd "${TOP_SRC_DIR}"
				git clone "${FORKED_REPO}"
			fi
		
			# This will attempt to update the fork to match the upstream master
			display "Updating ${PACKAGE_NAME} GIT repository"
			cd "${SRC_DIR}"
			git remote add upstream "${REPO}"
			git fetch upstream
			git pull upstream master
			git push
		fi
	}

# This function will prepare the Source Directory for building by calling the methods above.

	function prepareSourceDirectory
	{
		selectSourceDir
		
		# This checks if the Source Directories were set in the method above.
			if [[ -z ${SRC_DIR} || -z ${TOP_SRC_DIR} ]]
			then
				display "The Source Directories did not get set right, please edit settings.sh."
				exit 1
			fi
		
		display "Setting the source directory of ${PACKAGE_NAME} to: ${SRC_DIR} and updating it."
		
		if [ -n "${USE_FORKED_REPO}" ]
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
		selectBuildDir
		
		# This checks to make sure the BUILD_DIR variable has been set before continuing.
			if [ -z ${BUILD_DIR} ]
			then
				display "There is an error, the BUILD_DIR variable has not been set."
				exit 1
			fi
		
		display "Setting up and entering ${PACKAGE_NAME} build directory: ${BUILD_DIR}"
		if [ -d "${BUILD_DIR}" ]
		then
			if [ -n "${CLEAN_BUILD}" ]
			then
				rm -r "${BUILD_DIR}"/*
			fi
		else
			mkdir -p "${BUILD_DIR}"
		fi
		cd "${BUILD_DIR}"
	}
	
# This function will build the package in the build directory

	function buildPackage
	{
		setupAndEnterBuildDir
		
		# This checks if the SourceDirectory was properly set before building.
			if [ -z ${SRC_DIR} ]
			then
				display "The Source Directory did not get set right, please edit settings.sh."
				exit 1
			fi
		
		# This checks if the root install directory exists.  If it doesn't, it terminates the script with a message.
			if [ ! -d "${DEV_ROOT}" ]
			then
				display "The Development Root Directory Does Not Exist at the directory specified, please run setup.sh."
				exit 1
			fi
		
		if [ -n "${BUILD_XCODE}" ]
		then
			display "Building ${PACKAGE_NAME} using XCode"
			cmake -G Xcode ${GENERAL_BUILD_OPTIONS} ${PACKAGE_BUILD_OPTIONS} "${SRC_DIR}"
			xcodebuild -project "${XCODE_PROJECT_NAME}".xcodeproj -alltargets -configuration Debug CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" OTHER_CODE_SIGN_FLAGS="--deep"
		else
			display "Building ${PACKAGE_NAME} with the following options: ${GENERAL_BUILD_OPTIONS} ${PACKAGE_BUILD_OPTIONS}"
			cmake ${GENERAL_BUILD_OPTIONS} ${PACKAGE_BUILD_OPTIONS} "${SRC_DIR}"
			make -j $(expr $(sysctl -n hw.ncpu) + 2)
			if [[ "${BUILD_FOUNDATION}" == "SYSTEM" ]]
			then
				sudo make install
			else
				make install
			fi
		fi
	}
	
########################################################################################
# This is where the main part of the script starts!
#

# Prepare to run the script by setting all of the environment variables	
# If you want to customize any of those variables, you can edit this file
	source ${DIR}/../settings.sh
	
# This resets the package specific build options before getting and updated setting from the build script.
	export USE_FORKED_REPO=""

# This checks if any of the path variables are blank, since if they are blank, it could start trying to do things in the / folder, which is not good
	if [[ -z ${DIR} || -z ${TOP_FOLDER} || -z ${DEV_ROOT} ]]
	then
  		display "One or more critical directory variables is blank, please edit settings.sh."
  		exit 1
	fi

# This sets up the build for an XCode Build. It makes sure that if the build XCODE option is selected, the user has specified a CODE_SIGN_IDENTITY because if not, it won't work properly.
# Then it updates the build folders to reflect that the xcode build is the one being used.
	if [ -n "${BUILD_XCODE}" ]
	then
		if [ -n "${CODE_SIGN_IDENTITY}" ]
		then
			display "Building for XCode and code signing with the identity ${CODE_SIGN_IDENTITY}."
		else
			display "You have not specified a CODE_SIGN_IDENTITY, but you requested an XCode Build.  A Certificate is required for an XCode Build.  Make sure to get a certificate either from the Apple Developer program or from KeyChain Access on your Mac (A Self Signed Certificate is fine as long as you don't want to distribute KStars).  Be sure to edit settings.sh to include both XCode options."
			exit 1
		fi
	fi
	
# This sets up the development root directory for "installation"
	mkdir -p "${DEV_ROOT}"
	
# If using Craft as a building foundation, this checks if craft exists.  If it doesn't, it terminates the script with a message.
	if [[ "${BUILD_FOUNDATION}" == "CRAFT" ]]
	then
		if [ ! -d "${CRAFT_ROOT}" ]
		then
			display "Craft Does Not Exist at the directory specified, please install Craft, run craftSetup.sh, or edit settings.sh."
			exit 1
		fi
		
		# These links are needed on MacOS to successfully build outside of the main craft directories.
		# We should look into why they are needed.
			if [[ "${OSTYPE}" == "darwin"* ]]
			then
		
				mkdir -p "${DEV_ROOT}/include"
				mkdir -p "${DEV_ROOT}/lib"
			
				# This one is for several packages that can't seem to find GSL
				craftLink include/gsl
				# These are several libraries that were actually found by KStars, but then did not link properly without being in DEV Root.
				craftLink lib/libcfitsio.dylib
				craftLink lib/libgsl.dylib
				craftLink lib/libgslcblas.dylib
				craftLink lib/libwcslib.a
				
				# This provides a link for kdoctools to be found on MacOS.
				ln -s "${CRAFT_ROOT}/share/kf6" "${HOME}/Library/Application Support/kf6"
			
			fi
			
	elif [[ "${BUILD_FOUNDATION}" == "HOMEBREW" ]]
	then
		if [ ! -d "${HOMEBREW_ROOT}" ]
		then
			display "Homebrew Does Not Exist at the directory specified, please install Homebrew or edit settings.sh."
			exit 1
		fi
	fi


