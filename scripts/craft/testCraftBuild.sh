#/bin/bash

#	KDE Craft Testing Script for KStars and INDI Development
#﻿  Copyright (C) 2024 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

# This gets the directory from which this script is running so it can access files or other scripts in the repo
	DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
	

# These are the major script options.  Set these to the options you prefer by commenting them or uncommenting them with a #.
	
	# This determines the level of verbosity in Craft output.  v means verbose, q means quiet, and leaving it blank is normal.
		#VERBOSE=""
		VERBOSE="v"
		#VERBOSE="q"
		
	# This is the version to use for craft building.  master sets all packages to master, None sets them to their default stable versions, and leaving it blank uses the existing craft options.
		#VERSION=""
		VERSION="master"
		#VERSION="None"
		
	# These are the options for which packages you want craft to build.  Comment out any you don't want with a #.
		BUILD_INDI_DRIVERS="Yep"
		BUILD_STELLARSOLVER="Yep"
		BUILD_STELLARSOLVERTESTER="Yep"
		BUILD_KSTARS="Yep"
	
########################################################################################
# This is where the main part of the script starts!
#

# Prepare to run the script by setting all of the environment variables	
# If you want to customize any of those variables, you can edit this file
	source ${DIR}/../settings.sh

# Display the Welcome message.
	display "This script will test KStars, INDI, and StellarSolver Builds in Craft.  You can test the latest master or the latest stable releases of packages important to KStars/INDI development.  You can also test your own recipes in the blueprints folder and packaging with craft."

# This checks if any of the path variables are blank, since if they are blank, it could start trying to do things in the / folder, which is not good
	if [[ -z ${DIR} || -z ${CRAFT_ROOT} ]]
	then
  		display "One or more critical directory variables is blank, please edit settings.sh."
  		exit 1
	fi
	
# This checks the most important variables to see if the paths exist.  If they don't, it terminates the script with a message.
	if [ ! -d "${CRAFT_ROOT}" ]
	then
		display "Craft Does Not Exist at the directory specified, please install Craft or edit this script."
		exit 1
	fi
	
# This sets the craft environment based on the settings.
	source "${CRAFT_ROOT}/craft/craftenv.sh"

# This sets the version of all the packages as desired if using the -s or -m option.  If these are not specified, it just uses the current settings in craft
	if [ -n "${VERSION}" ]
	then
		display "Setting the versions of the astronomy packages to $VERSION."
		craft --set version="$VERSION" indi
		craft --set version="$VERSION" indi-3rdparty-libs
		craft --set version="$VERSION" indi-3rdparty
		craft --set version="$VERSION" stellarsolver
		craft --set version="$VERSION" stellarsolvertester
		craft --set version="$VERSION" kstars 
	fi
	
	if [ -n "${BUILD_INDI_DRIVERS}" ]
	then
		craft -i"$VERBOSE" indi
		craft -i"$VERBOSE" indi-3rdparty-libs
		craft -i"$VERBOSE" indi-3rdparty
	fi
	
	if [ -n "${BUILD_STELLARSOLVER}" ]
	then
		craft -i"$VERBOSE" stellarsolver
	fi
	
	if [ -n "${BUILD_STELLARSOLVERTESTER}" ]
	then
		craft -i"$VERBOSE" stellarsolvertester
	fi
	
	if [ -n "${BUILD_KSTARS}" ]
	then
		craft -i"$VERBOSE" kstars
	fi


display "Script Execution Complete"
