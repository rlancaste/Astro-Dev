#!/bin/bash

#	KStars and INDI Related Astronomy Software Development Build Scripts
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
		
		export SRC_DIR="${TOP_SRC_DIR}/${PACKAGE_SHORT_NAME}"
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
		
		if [ -n "${USE_QT5}" ]
		then
			export BUILD_DIR="${BUILD_DIR}-QT5"
		fi
		
		if [ -n "${USE_FORKED_REPO}" ]
		then
			export BUILD_DIR="${BUILD_DIR}-forked"
		fi
	
	}
	
# This automatically Sets the other options from what was requested in settings.sh
	function automaticallySetScriptSettings
	{
		# This is set up so that you can build in QT5 separate from QT6
			if [ -n "${USE_QT5}" ]
			then
				export CRAFT_ROOT="${CRAFT_ROOT}-QT5"
			fi
		
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
			
			if [[ -n "${USE_QT5}" && -n "${USE_DEV_ROOT}" ]]
			then
				export DEV_ROOT="${DEV_ROOT}-QT5"
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
	}