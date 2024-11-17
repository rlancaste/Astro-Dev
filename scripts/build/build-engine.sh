#!/bin/bash

#	KStars and INDI Related Astronomy Software Development Build Scripts
#﻿   Copyright (C) 2024 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

# This gets the directory from which this script is running so it can access files or other scripts in the repo.
	DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )


########################################
# FUNCTIONS RELATED TO BUILDING PACKAGES

# This function shortens the amount of code needed to clean the build directories if desired, make them if needed, and enter them
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
			xcodebuild -project "${PACKAGE_SHORT_NAME}".xcodeproj -alltargets -configuration Debug CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" OTHER_CODE_SIGN_FLAGS="--deep"
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
	
###################################################
# This is where the main part of the script starts!

# Prepare to run the script by setting all of the environment variables	
# If you want to customize any of those variables, you can edit this file
	source ${DIR}/../settings.sh
	
# This resets the package specific build options before getting and updated setting from the build script.
	export USE_FORKED_REPO=""

# This checks if any of the path variables are blank, since if they are blank, it could start trying to do things in the / folder, which is not good
	if [[ -z ${DIR} || -z ${DEV_ROOT} ]]
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
	
# This will create the Astro Root Directory if it doesn't exist
	mkdir -p "${ASTRO_ROOT}"
	
# This sets up the development root directory for "installation"
	if [ -n "${USE_DEV_ROOT}" ]
	then
		mkdir -p "${DEV_ROOT}"
	fi
	
# If using Craft as a building foundation, this checks if craft exists.  If it doesn't, it terminates the script with a message.
	if [[ "${BUILD_FOUNDATION}" == "CRAFT" ]]
	then
		if [[ ! -d "${CRAFT_ROOT}" ||  -n "${REMOVE_ALL}" ]]
		then
			setupCraft
		fi
		
		# These links are needed on MacOS to successfully build outside of the main craft directories.
		# We should look into why they are needed.
			if [[ "${OSTYPE}" == "darwin"* ]]
			then
				if [ -n "${USE_DEV_ROOT}" ]
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
				fi
				
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


