#!/bin/bash

#	KStars and INDI Related Astronomy Software Development Script Settings
#﻿   Copyright (C) 2024 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

# These are the primary global script options.  You may turn these on by removing the # from the front, or turn them off by putting a # in front.

	# This option uses XCode and xcode projects for building on MacOS.  It provides additional tools for testing, but lacks the QT Designer features in QT Creator.
		#export BUILD_XCODE="Yep"			
	# This option allows you to run scripts and build packages if they are already downloaded.  it will not check to update them since it is offline.
		#export BUILD_OFFLINE="Yep" 
	# This option will clean build directories out before building packages.  This will take longer to build, but may solve some problems sometimes.		
		#export CLEAN_BUILD="Yep"	

# This sets the foundation for building everything.  
# On Linux, it can use the system directories or it can use Craft.
# On MacOS it can use Craft or Homebrew.
# On Windows, it can use Windows Subsystem for Linux or Craft.

	if [[ "${OSTYPE}" == "darwin"* ]]
	then
		export BUILD_FOUNDATION="CRAFT"
		#export BUILD_FOUNDATION="HOMEBREW"
	else
		export BUILD_FOUNDATION="SYSTEM"
	fi

# These are your personalization options.  They are currently set to my account, but you will need to change them to your values.

	# Be sure to edit these using your own GITHub or GITLab username.
		export GIT_USERNAME="rlancaste"
		export GITLAB_USERNAME="lancaster"

	# For builds with xcode this is required. A Certificate is required for an XCode Build.  
	# Make sure to get a certificate either from the Apple Developer program or from KeyChain Access on your Mac (A Self Signed Certificate is fine as long as you don't want to distribute KStars).
		#export CODE_SIGN_IDENTITY="XXXXX"	
	
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

# This function checks to see if a connection to a website exists.
	function checkForConnection
	{
		testCommand=$(curl -Is $2 | head -n 1)
		if [[ "${testCommand}" == *"OK"* || "${testCommand}" == *"Moved"* || "${testCommand}" == *"HTTP/2 301"* || "${testCommand}" == *"HTTP/2 302"* || "${testCommand}" == *"HTTP/2 200"* ]]
  		then 
  			echo "$1 connection was found."
  		else
  			echo "$1, ($2), a required connection, was not found, aborting script."
  			echo "If you would like the script to run anyway, please comment out the line that tests this connection in the appropriate script."
  			exit
		fi
	}
	
# This sets important system paths that the script will need to execute.  Please verify these paths.

	# This is the AstroRoot Root Folder that will be used as a basis for building
		export ASTRO_ROOT="${HOME}/AstroRoot"
	# This is the Craft Root Folder that will be used as a basis for building
		export CRAFT_ROOT="${ASTRO_ROOT}/CraftRoot"
	# This is the Homebrew Root Folder that will be used as a basis for building
		export HOMEBREW_ROOT="/usr/local"
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
	
	
# These commands add paths to the PATH and Prefixes for building.
# These settings are crucial for finding programs, libraries, and other items for building.
	
	# This adds the path to GETTEXT to the path variables which is needed for building some packages on MacOS.  This assumes it is in homebrew, but if not, change it.
		if [[ "${OSTYPE}" == "darwin"* ]]
		then
			export GETTEXT_PATH=$(brew --prefix gettext)
			export PATH="${GETTEXT_PATH}/bin:${PATH}"
			export PREFIX_PATH="${GETTEXT_PATH}/bin;${PREFIX_PATH}"
		fi
		
	# The folders you are using for your build foundation need to be added to the path variables.
		if [[ "${BUILD_FOUNDATION}" == "CRAFT" ]]
		then
				export PATH="${CRAFT_ROOT}/bin:${CRAFT_ROOT}/dev-utils/bin:${PATH}"
				export PREFIX_PATH="${CRAFT_ROOT};${PREFIX_PATH}"
				export RPATHS="${CRAFT_ROOT}/lib;${RPATHS}"
				
		elif [[ "${BUILD_FOUNDATION}" == "HOMEBREW" ]]
		then
				export PATH="${HOMEBREW_ROOT}/bin:${CRAFT_ROOT}/dev-utils/bin:${PATH}"
				export PREFIX_PATH="${HOMEBREW_ROOT};${PREFIX_PATH}"
				export RPATHS="${HOMEBREW_ROOT}/lib;${RPATHS}"
		fi
	
	# pkgconfig is not needed on MacOS, but can be found by adding it to the path.
		#PATH="$(brew --prefix pkgconfig)/bin:$PATH"
	
	# The DEV_ROOT is the most important item to add to the path variables, the folder we will be using to "install" the programs.  Make sure it is added last so it appears first in the PATH.
		export PATH="${DEV_ROOT}/bin:${PATH}"
		export PREFIX_PATH="${DEV_ROOT};${PREFIX_PATH}"
		export RPATHS="${DEV_ROOT}/lib;${RPATHS}"

# This is a setting for MacOS.  This makes it possible to build for previous versions of the operating system.
# I would set these variables to whatever they are set to currently in Craft.
	if [[ "${OSTYPE}" == "darwin"* ]]
	then
		export QMAKE_MACOSX_DEPLOYMENT_TARGET=10.15
		export MACOSX_DEPLOYMENT_TARGET=10.15
	fi
	
# These are the Program Build options that are common to all the builds. The variables above are heavily used to set this up.
	if [[ "${OSTYPE}" == "darwin"* ]]
	then
		export GENERAL_BUILD_OPTIONS="-DCMAKE_BUILD_TYPE=Debug -DCMAKE_MACOSX_RPATH=1 -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 -DCMAKE_INSTALL_RPATH=${RPATHS} -DCMAKE_INSTALL_PREFIX=${DEV_ROOT} -DCMAKE_PREFIX_PATH=${PREFIX_PATH} -DKDE_INSTALL_BUNDLEDIR=${DEV_ROOT}"
	else
		export GENERAL_BUILD_OPTIONS="-DCMAKE_BUILD_TYPE=Debug -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 -DCMAKE_INSTALL_RPATH=${RPATHS} -DCMAKE_INSTALL_PREFIX=${DEV_ROOT} -DCMAKE_PREFIX_PATH=${PREFIX_PATH}"
	fi
		
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

echo "BUILD_FOUNDATION         is [${BUILD_FOUNDATION}]"

echo "BUILD_XCODE              ? [${BUILD_XCODE:-Nope}]"
echo "BUILD_OFFLINE            ? [${BUILD_OFFLINE:-Nope}]"
echo "CLEAN_BUILD              ? [${CLEAN_BUILD:-Nope}]"

echo "GENERAL_BUILD_OPTIONS    are [${GENERAL_BUILD_OPTIONS}]"
