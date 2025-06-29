#!/bin/bash
#This script is meant to check the current status of your Development Environment including branches, git status, and differences from master

#	KStars and INDI Related Astronomy Software Development Build Scripts
#﻿   Copyright (C) 2024 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

# This gets the directory from which this script is running so it can access files or other scripts in the repo
	DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Prepare to run the script by setting all of the environment variables	
# If you want to customize any of those variables, you can edit this file
	source ${DIR}/settings.sh

# This function checks the status of a git source directory.
	function srcStatus
	{
		# This checks if the function was actually sent a name and source directory
			if [[ -z $1 || -z $2 ]]
			then
				display "Error.  The srcStatus function requires a name and source directory."
				exit 1
			fi
		
		export NAME=$1
		export SRC_DIR=$2
		
		if [ -e ${SRC_DIR} ]
		then
			display "Checking ${NAME} Source directory: ${SRC_DIR}"
			cd ${SRC_DIR}
			git status
		fi
	}


# This function checks the status of the source folder of a package.  It handles both the forked and standard versions, whichever it finds.
	function packageStatus
	{
		# This checks if the function was actually sent a package name
			if [[ -z $1 ]]
			then
				display "Error.  The packageStatus function requires a package name."
				exit 1
			fi
		
		srcStatus "$1" "${ASTRO_ROOT}/src/$1"
		srcStatus "Forked $1" "${ASTRO_ROOT}/src-forked/$1"
	}
	
#########################################################################
#This is where the main part of the script starts!!
#

	# This should stop the script so that it doesn't run if these paths are blank.
	# That way it doesn't try to edit /Applications instead of ${CRAFT_ROOT}/Applications for example
		if [ -z "${DIR}" ] || [ -z  "${CRAFT_ROOT}" ] || [ -z  "${ASTRO_ROOT}" ]
		then
			echo "directory error! aborting Status Scropt"
			exit 9
		fi
	
	# This checks the Astro-Dev Repo
		srcStatus "Astro-Dev, THIS repo" "${DIR}/.."
	
	# This checks Craft Core Repo in the Craft Directories
		srcStatus "CRAFT x86 QT6 Craft Directory" "${ASTRO_ROOT}/CraftRoot/Craft"
		srcStatus "CRAFT ARM QT6 Craft Directory" "${ASTRO_ROOT}/CraftRoot-ARM/Craft"
		srcStatus "CRAFT x86 QT5 Craft Directory" "${ASTRO_ROOT}/CraftRoot-QT5/Craft"
		srcStatus "CRAFT ARM QT5 Craft Directory" "${ASTRO_ROOT}/CraftRoot-QT5-ARM/Craft"
		
	# This checks Craft blueprints in Craft
		srcStatus "CRAFT x86 QT6 Blueprints" "${ASTRO_ROOT}/CraftRoot/etc/blueprints/locations/craft-blueprints-kde"
		srcStatus "CRAFT ARM QT6 Blueprints" "${ASTRO_ROOT}/CraftRoot-ARM/etc/blueprints/locations/craft-blueprints-kde"
		srcStatus "CRAFT x86 QT5 Blueprints" "${ASTRO_ROOT}/CraftRoot-QT5/etc/blueprints/locations/craft-blueprints-kde"
		srcStatus "CRAFT ARM QT5 Blueprints" "${ASTRO_ROOT}/CraftRoot-QT5-ARM/etc/blueprints/locations/craft-blueprints-kde"

	# These are the packages it checks
		packageStatus indi
		packageStatus indi-3rdparty
		packageStatus stellarsolver
		packageStatus gsc
		packageStatus kstars
		packageStatus indiwebmanagerapp
		packageStatus phd2
		packageStatus craft-blueprints-kde
	
	
	


