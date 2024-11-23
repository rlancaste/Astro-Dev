#!/bin/bash

#	Astro-Dev Astronomy Software Development Scripts
#	settings.sh - A Script that configures the global settings used by the other scripts
#﻿  Copyright (C) 2024 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

# This gets the directory from which this script is running so it can access files or other scripts in the repo.
	SCRIPTS_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# This sets the script with the Build environment variables.
	source ${SCRIPTS_DIR}/script-engine.sh

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
	# This option will remove current homebrew packages and remove all the files in the Craft_Root Directory to start with a fresh craft foundation.  Be careful with this one.
		#export REMOVE_ALL="Yep"
	# The default for this REPO is to build in QT6, but this option allows you to build in QT5 since many Astronomy Packages (and homebrew) have not fully moved on to QT6	
		#export USE_QT5="Yep"	
		
	# Note: there are options for building with the original source repositories or your own forks.  These options are specific to the packages and not global.  Please see each package's build script for these options.

# This sets the foundation for building everything.
# It automatically switches here based on the operating system, but you have multiple choices on each one.
# Just comment out the one(s) you don't want to use on your system and uncomment the one you do.
# On Linux, it can use the system directories or it can use Craft.
# On MacOS it can use Craft or Homebrew.
# On Windows, it can use Windows Subsystem for Linux or Craft.

	if [[ "${OSTYPE}" == "darwin"* ]]
	then
		export BUILD_FOUNDATION="CRAFT"
		#export BUILD_FOUNDATION="HOMEBREW"
	elif [[ "${OSTYPE}" == "msys" ]]
	then
		export BUILD_FOUNDATION="CRAFT"
	else
		#export BUILD_FOUNDATION="CRAFT"
		export BUILD_FOUNDATION="SYSTEM"
	fi

# These are your personalization options.  They are currently set to my account, but you will need to change them to your values.

	# Be sure to edit these using your own GITHub or GITLab username.
		export GIT_USERNAME="rlancaste"
		export GITLAB_USERNAME="lancaster"

	# For builds with xcode this is required. A Certificate is required for an XCode Build.  
	# Make sure to get a certificate either from the Apple Developer program or from KeyChain Access on your Mac (A Self Signed Certificate is fine as long as you don't want to distribute KStars).
		#export CODE_SIGN_IDENTITY="XXXXX"	
	
# This sets important system paths that the script will need to execute.  Please verify these paths.
# Note that it is not wise to have spaces in the file paths.

	# This is the Root Folder that will be used as the base folder for everything
		export ASTRO_ROOT="${HOME}/AstroRoot"
	# This is the Craft Root Folder that will be used if the build foundation is Craft.  It could be in the AstroRoot Folder or somewhere else.
		export CRAFT_ROOT="${ASTRO_ROOT}/CraftRoot"
	# This is the Homebrew Root Folder that will be used as a basis for building. I don't think this should be changed.
		export HOMEBREW_ROOT="/usr/local"

# This is a setting for MacOS.  This makes it possible to build for previous versions of the operating system.
# I would set these variables to whatever they are set to currently in Craft.  See this page: https://doc.qt.io/qt-6/macos.html
	if [[ "${OSTYPE}" == "darwin"* ]]
	then
		export QMAKE_MACOSX_DEPLOYMENT_TARGET=12
		export MACOSX_DEPLOYMENT_TARGET=12
	fi

# This function will set the other script settings needed to begin the build scripts.  Please look at script-engine.sh if you want to customize this.
# In this function you will find settings like the general build options, as well as settings for PATH, PREFIX PATHS, and RPATHS
	automaticallySetScriptSettings


######################################################################
# Printing out essential information for the user running the scripts.

display "Setting Environment Variables."

# This is not a setting but is very important since the OS determines lots of other settings automatically.
echo "OSTYPE                   is [${OSTYPE}]"

# This is how many processors will be used when building.  It is automatically set in automaticallySetScriptSettings in script-engine.sh
echo "NUM_PROCESSORS           are [${NUM_PROCESSORS}]"

# These settings are vital if you want to fork a repo and do any editing.
echo "GIT_USERNAME             is [${GIT_USERNAME}]"
echo "GITLAB_USERNAME          is [${GITLAB_USERNAME}]"

# The Foundation for the build, An Extremely important and partially automatic selection.  Set above in the options.  
echo "BUILD_FOUNDATION         is [${BUILD_FOUNDATION}]"

# Primary Global Script Options set above in the options
echo "USE_DEV_ROOT             ? [${USE_DEV_ROOT:-Nope}]"
echo "BUILD_XCODE              ? [${BUILD_XCODE:-Nope}]"
echo "BUILD_OFFLINE            ? [${BUILD_OFFLINE:-Nope}]"
echo "CLEAN_BUILD              ? [${CLEAN_BUILD:-Nope}]"
echo "REMOVE_ALL               ? [${REMOVE_ALL:-Nope}]"
echo "USE_QT5                  ? [${USE_QT5:-Nope}]"

# Key Directory paths determined above in the options
echo "SCRIPTS_DIR              is [${SCRIPTS_DIR}]"
echo "ASTRO_ROOT               is [${ASTRO_ROOT}]"
echo "DEV_ROOT                 is [${DEV_ROOT}]"
echo "CRAFT_ROOT               is [${CRAFT_ROOT}]"

# Settings automatically set in automaticallySetScriptSettings in script-engine.sh
echo "PREFIX_PATHS             are [${PREFIX_PATHS}]"
echo "RPATHS                   are [${RPATHS}]"
echo "PATH                     is [${PATH}]"
echo "GENERAL_BUILD_OPTIONS    are [${GENERAL_BUILD_OPTIONS}]"

display "Environment Variables Set."
