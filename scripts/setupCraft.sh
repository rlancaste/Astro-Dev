#!/bin/zsh

#	Homebrew and Craft Setup Script for KStars and INDI Development
#﻿  Copyright (C) 2024 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

DIR=$(dirname "$0")

REMOVE_ALL=""
VERBOSE=""

# This will print out how to use the script
function usage
{

cat <<EOF
	options:
	    -h Display the options for the script
	    -r Remove everything and do a fresh install
	    -v Print out verbose output while building
	    -q Craft is in quiet mode while building
EOF
}

# This function prints the usage information if the user enters an invalid option or no option at all and quits the program 
	function dieUsage
	{
		echo ""
		echo $*
		echo ""
		usage
		exit 9
	}

# This function processes the user's options for running the script
	function processOptions
	{
		while getopts "hrvq" option
		do
			case $option in
				h)
					usage
					exit
					;;
				r)
					REMOVE_ALL="Yep"
					;;
				v)
					VERBOSE="v"
					;;
				q)
					VERBOSE="q"
					;;
				*)
					dieUsage "Unsupported option $option"
					;;
			esac
		done
		shift $((${OPTIND} - 1))

		echo ""
		echo "REMOVE_ALL         = ${REMOVE_ALL:-Nope}"
		echo "VERBOSE            = ${VERBOSE:-Nope}"
	}

# This function checks to see if a connection to a website exists.
#
	function checkForConnection
	{
		testCommand=$(curl -Is $2 | head -n 1)
		if [[ "${testCommand}" == *"OK"* || "${testCommand}" == *"Moved"* || "${testCommand}" == *"HTTP/2 301"* || "${testCommand}" == *"HTTP/2 200"* ]]
  		then 
  			echo "$1 connection was found."
  		else
  			echo "$1, ($2), a required connection, was not found, aborting script."
  			echo "If you would like the script to run anyway, please comment out the line that tests this connection in build-kstars.sh."
  			exit
		fi
	}


########################################################################################
# This is where the main part of the script starts!

# Process the command line options to determine what to do.
	processOptions $@
	
# Prepare to run the script by setting all of the environment variables	
	source ${DIR}/build-env.sh
	
# Set the working directory to /tmp because otherwise setup.py for craft will be placed in the user directory and that is messy.
	cd /tmp
	
# Before starting, check to see if the remote servers are accessible
	display "Checking Connections"
	checkForConnection Homebrew "https://raw.githubusercontent.com/Homebrew/install/master/install.sh"
	checkForConnection Craft "https://raw.githubusercontent.com/KDE/craft/master/setup/CraftBootstrap.py"
	
# Announce the script is starting and what will be done.
	display "Starting script to setup homebrew, craft, and the environment for KStars and INDI Development on Macs"
	
# This installs the xcode command line tools if not installed yet.
# Yes these tools will be automatically installed if the user has never used git before
# But sometimes they need to be installed again.
	
	if ! command -v xcode-select &> /dev/null
	then
		display "Installing xcode command line tools"
		xcode-select --install
	fi
	
# This will install homebrew if it hasn't been installed yet, or reset homebrew if desired.
	if [[ $(command -v brew) == "" ]]
	then
		display "Installing Homebrew."
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	else
		#This will remove all the homebrew packages if desired.
		if [ -n "$REMOVE_ALL" ]
		then
			display "You have selected the REMOVE_ALL option.  Warning, this will clear all currently installed homebrew packages."
			read runscript"?Do you really wish to proceed? (y/n)"
			if [ "$runscript" != "y" ]
			then
				echo "Quitting the script as you requested."
				exit
			fi
			brew remove --force $(brew list) --ignore-dependencies
		fi  
	fi

# This will install KStars dependencies from Homebrew.
	display "Upgrading Homebrew and Installing Homebrew Dependencies for Craft."
	brew upgrade
	
	# python is required for craft to work.
	brew install python
	
	# Craft does build ninja and install it to the craft directory, but QT Creator expects the homebrew version.
	brew install ninja

# This will create the Astro Directory if it doesn't exist
	mkdir -p "${ASTRO_ROOT}"

# This will install craft if it is not installed yet.  It will clear the old one if the REMOVE_ALL option was selected.
	if [ -d "${CRAFT_ROOT}" ]
	then
		# This will remove the current craft if desired.
		if [ -n "$REMOVE_ALL" ]
		then
			display "You have selected the REMOVE_ALL option.  Warning, this will clear the entire craft directory."
			read runscript2"?Do you really wish to proceed? (y/n)" 
			if [ "$runscript2" != "y" ]
			then
				echo "Quitting the script as you requested."
				exit
			fi
			if [ -d "${CRAFT_ROOT}" ]
			then
				rm -rf "${CRAFT_ROOT}"
			fi
			mkdir -p "${CRAFT_ROOT}"
			curl https://raw.githubusercontent.com/KDE/craft/master/setup/CraftBootstrap.py -o setup.py && $(brew --prefix)/bin/python3 setup.py --prefix "${CRAFT_ROOT}"
		fi
	else
		display "Installing craft"
		mkdir -p "${CRAFT_ROOT}"
		curl https://raw.githubusercontent.com/KDE/craft/master/setup/CraftBootstrap.py -o setup.py && $(brew --prefix)/bin/python3 setup.py --prefix "${CRAFT_ROOT}"
	fi  
	
# This copies all the required craft settings
	display "Copying Craft Settings and Blueprint settings specific to building on macs."
		
# This sets the craft environment based on the settings.
	source "${CRAFT_ROOT}/craft/craftenv.sh"

# This will build indi, including the 3rd Party drivers.
# Note that crafting KStars builds all the other ones below, but the stable builds not their master versions
# To build the latest master, you can use the commented out code below.

	display "Crafting KStars and all required dependencies including StellarSolver, INDI Drivers, and many others."
	
	#craft -i"$VERBOSE" --target master indi
	
	#craft -i"$VERBOSE" --target master indi-3rdparty-libs
	
	#craft -i"$VERBOSE" --target master indi-3rdparty
	
	craft -i"$VERBOSE" --target master kstars
		
	display "CRAFT COMPLETE"
	
# This will create some symlinks that make it easier to edit INDI and KStars
	display "Creating symlinks"
	
	if [ ! -d ${SHORTCUTS_DIR} ]
	then
		mkdir -p ${SHORTCUTS_DIR}
	else
		if [ "$(ls -A ${SHORTCUTS_DIR})" ] # shortcuts directory is not empty
		then
			rm -f ${SHORTCUTS_DIR}/*
		fi
	fi
	
	# Craft Shortcuts
	ln -sf ${CRAFT_ROOT}/bin ${SHORTCUTS_DIR}
	ln -sf ${CRAFT_ROOT}/build ${SHORTCUTS_DIR}
	ln -sf ${CRAFT_ROOT}/lib ${SHORTCUTS_DIR}
	ln -sf ${CRAFT_ROOT}/include ${SHORTCUTS_DIR}
	ln -sf ${CRAFT_ROOT}/share ${SHORTCUTS_DIR}
	ln -sf ${CRAFT_ROOT}/etc/blueprints/locations/craft-blueprints-kde ${SHORTCUTS_DIR}
	
	
	# INDI Master Source Folders
	if [ -d ${CRAFT_ROOT}/download/git/libs/indilib ]
	then
		ln -sf ${CRAFT_ROOT}/download/git/libs/indilib ${SHORTCUTS_DIR}
		mv ${SHORTCUTS_DIR}/indilib ${SHORTCUTS_DIR}/indi-source-folders
	fi
	
	# INDI Archived Source Folders
	if [ -d ${CRAFT_ROOT}/download/archives/libs/indilib ]
	then
		ln -sf ${CRAFT_ROOT}/download/archives/libs/indilib ${SHORTCUTS_DIR}
		mv ${SHORTCUTS_DIR}/indilib ${SHORTCUTS_DIR}/indi-archive-folders
	fi
	
	# INDI Build Folder
	ln -sf ${CRAFT_ROOT}/build/libs/indilib/indi/work/build ${SHORTCUTS_DIR}
	mv ${SHORTCUTS_DIR}/build ${SHORTCUTS_DIR}/indi-build
	
	# INDI 3rdParty Libs Build Folder
	ln -sf ${CRAFT_ROOT}/build/libs/indilib/indi-3rdparty-libs/work/build ${SHORTCUTS_DIR}
	mv ${SHORTCUTS_DIR}/build ${SHORTCUTS_DIR}/indi-3rdparty-libs-build
	
	# INDI 3rdParty Build Folder
	ln -sf ${CRAFT_ROOT}/build/libs/indilib/indi-3rdparty/work/build ${SHORTCUTS_DIR}
	mv ${SHORTCUTS_DIR}/build ${SHORTCUTS_DIR}/indi-3rdparty-build
	
	# KStars
	if [ -d ${CRAFT_ROOT}/download/git/kde/applications/kstars ]
	then
		ln -sf ${CRAFT_ROOT}/download/git/kde/applications/kstars ${SHORTCUTS_DIR}
		mv ${SHORTCUTS_DIR}/kstars ${SHORTCUTS_DIR}/kstars-source
		ln -sf ${CRAFT_ROOT}/build/kde/applications/kstars/work/build ${SHORTCUTS_DIR}
		mv ${SHORTCUTS_DIR}/build ${SHORTCUTS_DIR}/kstars-build
	fi


display "Script execution complete"
