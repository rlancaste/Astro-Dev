#!/bin/bash

#	KStars and INDI Related Astronomy Software Development Setup Scripts
#﻿  Copyright (C) 2024 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

# This gets the directory from which this script is running so it can access files or other scripts in the repo
	DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# These are the options for running this script.  Uncomment any of the ones you want to set by removing the #, or comment out any you don't want by adding one.
	#REMOVE_ALL="Yep"  # This option will remove current homebrew packages and remove all the files in the Craft_Root Directory to start fresh.
	#VERBOSE="v"	   # This option will print more craft output than usual for increased debugging purposes.
	#VERBOSE="q"	   # This option will print less craft output than usual for "quiet" building.

# This function will install homebrew if it hasn't been installed yet, or reset homebrew if desired.
	function setupHomebrew
	{
		checkForConnection Homebrew "https://raw.githubusercontent.com/Homebrew/install/master/install.sh"
		
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
	}

# This function installs a program with homebrew if it is not installed, otherwise it moves on printing a message.
# It can take one package or a bunch of packages on one line separated with spaces.
	function brewInstallIfNeeded
	{
		brew ls --versions $1 > /dev/null 2>&1
		if [ $? -ne 0 ]
		then
			echo "Installing : $*"
			brew install $*
		else
			echo "brew : $* is already installed"
		fi
	}
	
# This function installs Craft on various operating systems
	function installCraft
	{
		if [[ "${OSTYPE}" == "darwin"* ]]
		then
			curl https://raw.githubusercontent.com/KDE/craft/master/setup/CraftBootstrap.py -o setup.py && $(brew --prefix)/bin/python3 setup.py --prefix "${CRAFT_ROOT}"
			
		elif [[ "$OSTYPE" == "msys" ]]
		then
			curl https://raw.githubusercontent.com/KDE/craft/master/setup/CraftBootstrap.py -o setup.py && /bin/python3 setup.py --prefix "${CRAFT_ROOT}"
		else
			python3 -c "$(wget https://raw.githubusercontent.com/KDE/craft/master/setup/CraftBootstrap.py -O -)" --prefix "${CRAFT_ROOT}"
		fi
	}



########################################################################################
# This is where the main part of the script starts!
	
# Prepare to run the script by setting all of the environment variables	
	source ${DIR}/../settings.sh
	
# Before starting, check to see if the remote servers are accessible
	display "Checking Connections"

	checkForConnection Craft "https://raw.githubusercontent.com/KDE/craft/master/setup/CraftBootstrap.py"
	
# Announce the script is starting and what will be done.
	display "Starting script to setup Craft (and Homebrew on Mac) for Astronomy Software Development related to KStars and INDI"
	
	read -p "Do you wish to continue? If so, type y. " runscript
	if [ "$runscript" != "y" ]
	then
		echo "Quitting the script as you requested."
		exit
	fi
	
# This checks if any of the path variables are blank, since if they are blank, it could start trying to do things in the / folder, which is not good
	if [[ -z ${ASTRO_ROOT} || -z ${CRAFT_ROOT} || -z ${SHORTCUTS_DIR} ]]
	then
  		display "One or more critical directory variables is blank, please edit settings.sh."
  		exit 1
	fi

# This will set up items required for MacOS

	if [[ "${OSTYPE}" == "darwin"* ]]
	then

		# This installs the xcode command line tools if not installed yet.
		# Yes these tools will be automatically installed if the user has never used git before
		# But sometimes they need to be installed again.
			
			if ! command -v xcode-select &> /dev/null
			then
				display "Installing xcode command line tools"
				xcode-select --install
			fi
			
		# This will install homebrew if it hasn't been installed yet, or reset homebrew if desired.
			setupHomebrew
		
		# This will make sure Homebrew is up to date and display the message.
			display "Upgrading Homebrew and Installing Homebrew Dependencies for Craft."
			brew upgrade
			
		# python is required for craft to work.
			brewInstallIfNeeded python
			
		# Craft does build ninja and install it to the craft directory, but QT Creator expects the homebrew version for development.
			brewInstallIfNeeded ninja
		
		# Craft does install both of these, but they are helpful to have in homebrew for development
			brewInstallIfNeeded cmake
			brewInstallIfNeeded gettext
	fi

# This will create the Astro Directory if it doesn't exist
	mkdir -p "${ASTRO_ROOT}"

# This will install craft if it is not installed yet.  It will clear the old one if the REMOVE_ALL option was selected.
	cd /tmp # Set the working directory to /tmp because otherwise setup.py for craft will be placed in the user directory and that is messy.
	if [ -d "${CRAFT_ROOT}" ]
	then
		# This will remove the current craft if desired.
		if [ -n "$REMOVE_ALL" ]
		then
			display "You have selected the REMOVE_ALL option.  Warning, this will clear the entire craft directory."
			read runscript2"?Do you really wish to proceed? (y/n) " 
			
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
			installCraft
		fi
	else
		display "Installing craft"
		mkdir -p "${CRAFT_ROOT}"
		installCraft
	fi  
		
# This sets the craft environment based on the settings.
	source "${CRAFT_ROOT}/craft/craftenv.sh"

# Note that crafting KStars builds INDI, INDI-3rd Party, StellarSolver, but the stable builds not their master versions
# you can always change that option in the craft settings or you can use one of the other scripts.
# To build the latest master, you can use the commented out code below.

	display "Setting KStars version to master and Crafting KStars and all required dependencies including StellarSolver, INDI Drivers, and many others."
	
	craft --set version=master kstars 
	craft -i"$VERBOSE" kstars
		
	display "CRAFT COMPLETE"
	
# This will create some symlinks that make it easier to find needed folders in craft to work on Astronomical Software
	display "Creating symlinks"
	
	if [ ! -d "${SHORTCUTS_DIR}" ]
	then
		mkdir -p "${SHORTCUTS_DIR}"
	else
		if [ "$(ls -A ${SHORTCUTS_DIR})" ] # shortcuts directory is not empty
		then
			rm -f ${SHORTCUTS_DIR}/*
		fi
	fi
	
	# Craft Shortcuts
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
read -p "Ending Script. Hit enter to exit." var 