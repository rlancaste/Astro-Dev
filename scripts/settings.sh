#!/bin/bash

#	KStars and INDI Related Astronomy Software Development Script Settings
#﻿   Copyright (C) 2024 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

# This function will display the message so it stands out in the Terminal both in the code and at the top.
	function display
	{
		# This will display the message in line in the commands.
		echo ""
		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
		echo "~ $*"
		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
		echo ""
	}	
	
# This sets important system paths that the script will need to execute.  Please verify these paths.
		# This is the AstroRoot Root Folder that will be used as a basis for building
	export ASTRO_ROOT="${HOME}/AstroRoot"
		# This is the Craft Root Folder that will be used as a basis for building
	export CRAFT_ROOT="${ASTRO_ROOT}/CraftRoot"
		#This is the location of the craft shortcuts directory
	export SHORTCUTS_DIR="${ASTRO_ROOT}"/craft-shortcuts
	

# This sets the directory paths.  Note that these are customizable, but they do get set here automatically.
# Beware that none of them should have spaces in the file path.

		# This is the base path.  Note, you could set this to your own project folder or the top folder of this repo instead.
	export TOP_FOLDER="${ASTRO_ROOT}/Development" # This puts it in the astro root folder, which I personally prefer.
		# This is the enclosing folder for the source code of INDI, KStars, and INDI Web Manager
	export SRC_FOLDER="${TOP_FOLDER}/src"
		# This is the enclosing folder for the forked source code of INDI, KStars, and INDI Web Manager
	export FORKED_SRC_FOLDER="${TOP_FOLDER}/src-forked"
		# This is the enclosing folder for the build folders of INDI, KStars, and INDI Web Manager
	export BUILD_FOLDER="${TOP_FOLDER}/build"
		# This is the enclosing folder for the forked build folders of INDI, KStars, and INDI Web Manager
	export FORKED_BUILD_FOLDER="${TOP_FOLDER}/build-forked"
		# This is the enclosing folder for the xcode build folders of INDI, KStars, and INDI Web Manager
	export XCODE_BUILD_FOLDER="${TOP_FOLDER}/xcode-build"
		# This is the enclosing folder for the forked xcode build folders of INDI, KStars, and INDI Web Manager
	export FORKED_XCODE_BUILD_FOLDER="${TOP_FOLDER}/xcode-build-forked"
		# This is the Development Root folder where we will be "installing" built software
	export DEV_ROOT="${TOP_FOLDER}/DEV_ROOT"
	
	
#These paths should not need to be changed on most systems

	# This is a list of paths that will be used by find_package to locate libraries when building
	# These paths are root directories that contain cmake files and dynamic libraries
	export PREFIX_PATH="${CRAFT_ROOT};${DEV_ROOT};${GETTEXT_PATH}"
	export RPATHS="${DEV_ROOT}/lib;${CRAFT_ROOT}/lib"
	
	# These are settings specifically needed for MacOS
	if [[ "${OSTYPE}" == "darwin"* ]]
	then
		# This sets the path to GET TEXT which is needed for building some packages.  This assumes it is in homebrew, but if not, change it.
		export GETTEXT_PATH=$(brew --prefix gettext)
		export GSL_ROOT_DIR="${CRAFT_ROOT}"
	fi
	
	# This is a list of paths to binaries that will be needed for building and running.  They are added to the PATH variable.
	export PATH="${DEV_ROOT}/bin:${ASTRO_ROOT}/CraftRoot/bin:${ASTRO_ROOT}/CraftRoot/dev-utils/bin:${GETTEXT_PATH}/bin:$PATH"
	
	# pkgconfig is not needed, but can be found by adding it to the path.
	#PATH="$(brew --prefix pkgconfig)/bin:$PATH"

# This option sets the Git Usernames for your forks on GitHub and Gitlab.  This is critical for functions of the script.
	 export GIT_USERNAME="rlancaste" # be sure to edit this using your own github username.
	 export GITLAB_USERNAME="lancaster" # be sure to edit this using your own gitlab username.

# This sets the minimum OS X version you are compiling for
# Note that the current version of qt can no longer build for anything less than 10.12

	export QMAKE_MACOSX_DEPLOYMENT_TARGET=10.15
	export MACOSX_DEPLOYMENT_TARGET=10.15
	
# These are the Program Build options that are common to all the builds.  You can change these as you desire.  Comment out the ones you don't want, Uncomment the ones you do.
	if [[ "${OSTYPE}" == "darwin"* ]]
	then
		export GENERAL_BUILD_OPTIONS="-DCMAKE_BUILD_TYPE=Debug -DCMAKE_MACOSX_RPATH=1 -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 -DCMAKE_INSTALL_RPATH=${RPATHS} -DCMAKE_INSTALL_PREFIX=${DEV_ROOT} -DCMAKE_PREFIX_PATH=${PREFIX_PATH} -DKDE_INSTALL_BUNDLEDIR=${DEV_ROOT}"
	else
		export GENERAL_BUILD_OPTIONS="-DCMAKE_BUILD_TYPE=Debug -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 -DCMAKE_INSTALL_RPATH=${RPATHS} -DCMAKE_INSTALL_PREFIX=${DEV_ROOT} -DCMAKE_PREFIX_PATH=${PREFIX_PATH}"
	fi
	#export BUILD_XCODE="Yep"			# This option uses XCode and xcode projects for building.  It provides additional tools for testing, but lacks the QT Designer features in QT Creator.
	#export CODE_SIGN_IDENTITY="XXXXX"	# For builds with xcode this is required. A Certificate is required for an XCode Build.  Make sure to get a certificate either from the Apple Developer program or from KeyChain Access on your Mac (A Self Signed Certificate is fine as long as you don't want to distribute KStars).
	#export BUILD_OFFLINE="Yep" 		# This option allows you to run scripts and build packages if they are already downloaded.  it will not check to update them since it is offline.
	#export CLEAN_BUILD="Yep"			# This option will clean build directories out before building packages.  This will take longer to build, but may solve some problems sometimes.
	
display "Environment Variables Set."

echo "TOP_FOLDER               is [${TOP_FOLDER}]"
echo "SRC_FOLDER               is [${SRC_FOLDER}]"
echo "FORKED_SRC_FOLDER        is [${FORKED_SRC_FOLDER}]"
echo "BUILD_FOLDER             is [${BUILD_FOLDER}]"
echo "CRAFT_ROOT               is [${CRAFT_ROOT}]"
echo "DEV_ROOT                 is [${DEV_ROOT}]"
echo "GETTEXT_PATH             is [${GETTEXT_PATH}]"

echo "PREFIX_PATH              is [${PREFIX_PATH}]"
echo "PATH                     is [${PATH}]"

echo "OSX Deployment target    is [${QMAKE_MACOSX_DEPLOYMENT_TARGET}]"
echo "GENERAL_BUILD_OPTIONS    are [${GENERAL_BUILD_OPTIONS}]"
echo "BUILD_XCODE    		? [${BUILD_XCODE:-Nope}]"
echo "BUILD_OFFLINE    	? [${BUILD_OFFLINE:-Nope}]"
echo "CLEAN_BUILD    		? [${CLEAN_BUILD:-Nope}]"