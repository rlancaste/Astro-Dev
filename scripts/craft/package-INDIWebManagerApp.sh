#!/bin/bash

#	Astro-Dev Astronomy Software Development Craft Packaging Scripts
# 	package-INDIWebManagerApp.sh - This script uses craft to rebuild and package INDI Web Manager App
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
	
########################################################################################
# This is where the main part of the script starts!
#

# Prepare to run the script by setting all of the environment variables	
# If you want to customize any of those variables, you can edit this file
	source ${DIR}/../settings.sh

# Display the Welcome message.
	display "This script will package indiwebmanagerapp for Distribution using the requested options."

# This checks if any of the path variables are blank, since if they are blank, it could start trying to do things in the / folder, which is not good
	if [ -z ${CRAFT_ROOT} ]
	then
  		display "The Craft Root Directory is blank, please edit settings.sh."
  		exit 1
	fi
	
# This checks the most important variables to see if the paths exist.  If they don't, it terminates the script with a message.
	if [ ! -d "${CRAFT_ROOT}" ]
	then
		display "Craft Does Not Exist at the directory specified, please install Craft or edit this script."
		exit 1
	fi

# StellarBatchSolver does not have a blueprint in the Craft Repository. This copies in a blueprint.
	if [[ "${BUILD_FOUNDATION}" == "CRAFT" ]]
	then
		display "Copying Craft Blueprints for indiwebmanagerapp if needed."
		if [ -n "${USE_QT5}" ]
		then
		 	copyCraftBlueprint ${SCRIPTS_DIR}/craft/extra-blueprints/QT5/indiwebmanagerapp libs/indiwebmanagerapp
		else
		 	copyCraftBlueprint ${SCRIPTS_DIR}/craft/extra-blueprints/QT6/indiwebmanagerapp libs/indiwebmanagerapp
		fi
	fi
	
# This sets the craft environment based on the settings.
	source "${CRAFT_ROOT}/craft/craftenv.sh"

# This sets the version of all the packages as desired if using the -s or -m option.  If these are not specified, it just uses the current settings in craft
	if [ -n "${VERSION}" ]
	then
		display "Setting the version of the indiwebmanagerapp package to $VERSION."

		craft --set version="$VERSION" indiwebmanagerapp
	fi
	
	craft -i"$VERBOSE" indiwebmanagerapp
	craft --package indiwebmanagerapp

display "Script Execution Complete"
