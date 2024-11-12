#!/bin/bash

#	KStars and INDI Related Astronomy Software Development Script Settings
#﻿   Copyright (C) 2024 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

# These are the primary global script options.  You may turn these on by removing the # from the front, or turn them off by putting a # in front.

	# This is an option to use a Development root folder for "installing" software so that you can see all the files you are working on and where they install to.
	# If you turn this option off, it will install the software it builds back in the Build Foundation Root Folder. 
		export USE_DEV_ROOT="Yep"
	# This option uses XCode and xcode projects for building on MacOS.  It provides additional tools for testing, but lacks the QT Designer features in QT Creator.
		#export BUILD_XCODE="Yep"			
	# This option allows you to run scripts and build packages if they are already downloaded.  it will not check to update them since it is offline.
		#export BUILD_OFFLINE="Yep" 
	# This option will clean build directories out before building packages.  This will take longer to build, but may solve some problems sometimes.		
		#export CLEAN_BUILD="Yep"	
		
	# Note: there are options for building with the original source repositories or your own forks.  These options are specific to the packages and not global.  Please see each package's build script for these options.

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
	
# This script sets it up so that you can build from the original repo source folder or from your own fork.
# It separates the two so that you can switch back and forth if desired.  You can do parallel builds.
	function selectSourceDir
	{
		if [ -n "${USE_FORKED_REPO}" ]
		then
			export TOP_SRC_DIR="${ASTRO_ROOT}/src-forked"
		else
			export TOP_SRC_DIR="${ASTRO_ROOT}/src"
		fi
		
		export SRC_DIR="${TOP_SRC_DIR}/${SRC_SUBDIR}"
	}
	
# This script supports building with different build systems.  While the source folders should work for all systems, the build folders will not.
# This function will set the build folder based on selected options. This way you can build in parallel with different systems to compare.
	function selectBuildDir
	{
		export BUILD_DIR="${ASTRO_ROOT}/build"
		
		if [[ "${BUILD_FOUNDATION}" == "CRAFT" ]]
		then
			export BUILD_DIR="${BUILD_DIR}/craft-base"
			
		elif [[ "${BUILD_FOUNDATION}" == "HOMEBREW" ]]
		then
			export BUILD_DIR="${BUILD_DIR}/brew-base"
		fi
		
		export BUILD_DIR="${BUILD_DIR}/${BUILD_SUBDIR}"
		
		if [ -n "${BUILD_XCODE}" ]
		then
			export BUILD_DIR="${BUILD_DIR}-xcode"
		fi
		
		if [ -n "${USE_FORKED_REPO}" ]
		then
			export BUILD_DIR="${BUILD_DIR}-forked"
		fi
	
	} 
	
# This sets important system paths that the script will need to execute.  Please verify these paths.
# Note that it is not wise to have spaces in the file paths.

	# This is the Root Folder that will be used as the base folder for everything
		export ASTRO_ROOT="${HOME}/AstroRoot"
	# This is the Craft Root Folder that will be used if the build foundation is Craft.  It could be in the AstroRoot Folder or somewhere else.
		export CRAFT_ROOT="${ASTRO_ROOT}/CraftRoot"
	# This is the Homebrew Root Folder that will be used as a basis for building
		export HOMEBREW_ROOT="/usr/local"
	# This is the location of the craft shortcuts directory
		export SHORTCUTS_DIR="${ASTRO_ROOT}/craft-shortcuts"

# Based on whether you choose to use the DEV_ROOT folder option, this will set up the DEV_ROOT based on the foundation for the build, since the "installed" files have different linkings.

	
	if [[ "${BUILD_FOUNDATION}" == "CRAFT" ]]
	then
		if [ -n "${USE_DEV_ROOT}" ]
		then
			export DEV_ROOT="${ASTRO_ROOT}/DEV_CRAFT"
		else
			export DEV_ROOT="${CRAFT_ROOT}"
		fi
	elif [[ "${BUILD_FOUNDATION}" == "HOMEBREW" ]]
	then
		if [ -n "${USE_DEV_ROOT}" ]
		then
			export DEV_ROOT="${ASTRO_ROOT}/DEV_BREW"
		else
			export DEV_ROOT="${HOMEBREW_ROOT}"
		fi
	else
		if [ -n "${USE_DEV_ROOT}" ]
		then
			export DEV_ROOT="${ASTRO_ROOT}/DEV_ROOT"
		else
			export DEV_ROOT="/usr/local"
		fi
	fi
	
# These commands add paths to the PATH and Prefixes for building.
# These settings are crucial for finding programs, libraries, and other items for building.
	
	export PREFIX_PATHS=""
	export RPATHS=""
	
	# This adds the path to GETTEXT to the path variables which is needed for building some packages on MacOS.  This assumes it is in homebrew, but if not, change it.
		if [[ "${OSTYPE}" == "darwin"* ]]
		then
			export GETTEXT_PATH=$(brew --prefix gettext)
			export PATH="${GETTEXT_PATH}/bin:${PATH}"
			export PREFIX_PATHS="${GETTEXT_PATH}/bin"
		fi
		
	# The folders you are using for your build foundation need to be added to the path variables.
		if [[ "${BUILD_FOUNDATION}" == "CRAFT" ]]
		then
			export PATH="${CRAFT_ROOT}/bin:${CRAFT_ROOT}/dev-utils/bin:${PATH}"
			export PREFIX_PATHS="${CRAFT_ROOT};${PREFIX_PATHS}"
			export RPATHS="${CRAFT_ROOT}/lib;${RPATHS}"
				
		elif [[ "${BUILD_FOUNDATION}" == "HOMEBREW" ]]
		then
			export PATH="${HOMEBREW_ROOT}/bin:${CRAFT_ROOT}/dev-utils/bin:${PATH}"
			export PREFIX_PATHS="${HOMEBREW_ROOT};${PREFIX_PATHS}"
			export RPATHS="${HOMEBREW_ROOT}/lib;${RPATHS}"
		else
			export PREFIX_PATHS="/usr;/usr/local"
			export RPATHS="/usr/lib;/usr/local/lib"
		fi
	
	# pkgconfig is not needed on MacOS, but can be found by adding it to the path.
		#PATH="$(brew --prefix pkgconfig)/bin:$PATH"
	
	# The DEV_ROOT is the most important item to add to the path variables, the folder we will be using to "install" the programs.  Make sure it is added last so it appears first in the PATH.
		if [ -n "${USE_DEV_ROOT}" ]
		then
			export PATH="${DEV_ROOT}/bin:${PATH}"
			export PREFIX_PATHS="${DEV_ROOT};${PREFIX_PATHS}"
			export RPATHS="${DEV_ROOT}/lib;${RPATHS}"
		fi

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
		export GENERAL_BUILD_OPTIONS="-DCMAKE_BUILD_TYPE=Debug -DCMAKE_MACOSX_RPATH=1 -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 -DCMAKE_INSTALL_RPATH=${RPATHS} -DCMAKE_INSTALL_PREFIX=${DEV_ROOT} -DCMAKE_PREFIX_PATH=${PREFIX_PATHS} -DKDE_INSTALL_BUNDLEDIR=${DEV_ROOT}"
	else
		if [[ "${BUILD_FOUNDATION}" == "CRAFT" ]]
		then
			export GENERAL_BUILD_OPTIONS="-DCMAKE_BUILD_TYPE=Debug -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 -DCMAKE_INSTALL_RPATH=${RPATHS} -DCMAKE_INSTALL_PREFIX=${DEV_ROOT} -DCMAKE_PREFIX_PATH=${PREFIX_PATHS}"
		else
			export GENERAL_BUILD_OPTIONS="-DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=${DEV_ROOT}"
		fi
	fi
		
display "Setting Environment Variables."

echo "OSTYPE                   is [${OSTYPE}]"
echo "BUILD_FOUNDATION         is [${BUILD_FOUNDATION}]"
echo "BUILD_XCODE              ? [${BUILD_XCODE:-Nope}]"
echo "BUILD_OFFLINE            ? [${BUILD_OFFLINE:-Nope}]"
echo "CLEAN_BUILD              ? [${CLEAN_BUILD:-Nope}]"

echo "ASTRO_ROOT               is [${ASTRO_ROOT}]"
echo "DEV_ROOT                 is [${DEV_ROOT}]"
echo "CRAFT_ROOT               is [${CRAFT_ROOT}]"

echo "PREFIX_PATHS             are [${PREFIX_PATHS}]"
echo "RPATHS                   are [${RPATHS}]"
echo "PATH                     is [${PATH}]"
echo "GENERAL_BUILD_OPTIONS    are [${GENERAL_BUILD_OPTIONS}]"

display "Environment Variables Set."
