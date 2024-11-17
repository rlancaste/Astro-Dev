#!/bin/bash

#	KStars and INDI Related Astronomy Software Development Build Scripts
#﻿   Copyright (C) 2024 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

# This script is a script of functions that are used by the other scripts.  If you run this script by itself, nothing should happen.

#########################################################################
# FUNDAMENTAL FUNCTIONS OF ALL SCRIPTS

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
# $1 is the name of the connection, $2 is web address to check
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


#########################################################################
# FUNCTIONS RELATED TO CONFIGURING THE STRUCTURE OF THE ASTRO_ROOT FOLDER
	
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
		# This sets the number of processors to use when building
			if [[ "${OSTYPE}" == "darwin"* ]]
			then
				export NUM_PROCESSORS=$(expr $(sysctl -n hw.ncpu) + 2)
			else
				export NUM_PROCESSORS=$(expr $(nproc) + 2)
			fi
			
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
	

#########################################
# FUNCTIONS RELATED TO PREPARING HOMEBREW

# This function links a file or folder in the dev directory to one in the Homebrew-root directory
	function homebrewLink
	{
		if [ ! -e "${DEV_ROOT}/$1" ]
		then
			ln -s ${HOMEBREW_ROOT}/$1 ${DEV_ROOT}/$1
		fi
	}
	
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
			if [ -n "${REMOVE_ALL}" ]
			then
				display "You have selected the REMOVE_ALL option.  Warning, this will clear all currently installed homebrew packages."
				read -p "Do you really wish to proceed? (type y/n) " runscript
				if [ "$runscript" != "y" ]
				then
					echo "Quitting the script as you requested."
					exit
				fi
				brew remove --force $(brew list) --ignore-dependencies
			fi  
		fi
	}


##############################################
# FUNCTIONS RELATED TO DEPENDENCIES OF A BUILD

# This function installs a program with homebrew if it is not installed, otherwise it moves on.
# It accepts a list of packages or single packages separated by spaces.
# Note that we could also just say brew packagename, but that takes longer than this method.
	function brewInstallIfNeeded
	{
		for package in "$@"
		do
			brew ls --versions $package > /dev/null 2>&1
			if [ $? -ne 0 ]
			then
				echo "Installing : $package"
				brew install $package
			else
				echo "brew : $package is already installed"
			fi
		done
	}

# This function will install dependencies required for the build.
	function installDependencies
	{
		display "Installing Dependencies"
		if [[ "${BUILD_FOUNDATION}" == "CRAFT" ]]
		then
			source "${CRAFT_ROOT}/craft/craftenv.sh"
			craft --install-deps "${PACKAGE_SHORT_NAME}"
		else
			if [[ "${OSTYPE}" == "darwin"* ]]
			then
				brewInstallIfNeeded ${HOMEBREW_DEPENDENCIES} # Don't put quotes here so that it does each package separately.
			fi
		fi
	}


#######################################
# FUNCTIONS RELATED TO PREPARING CRAFT

# This function links a file or folder in the dev directory to one in the craft-root directory
	function craftLink
	{
		if [ ! -e "${DEV_ROOT}/$1" ]
		then
			ln -s ${CRAFT_ROOT}/$1 ${DEV_ROOT}/$1
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

# This function will setup Craft with the requested options.
	function setupCraft
	{
		# Before starting, check to see if craft's remote servers are accessible
			checkForConnection Craft "https://raw.githubusercontent.com/KDE/craft/master/setup/CraftBootstrap.py"
			
		# This checks if any of the path variables are blank, since if they are blank, it could start trying to do things in the / folder, which is not good
			if [[ -z ${ASTRO_ROOT} || -z ${CRAFT_ROOT} ]]
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
					
				# python is the only one required for craft, but the others are needed by the other scripts in this Repo or QT Creator
					brewInstallIfNeeded cmake python ninja gettext
			fi
		
		# This will install craft if it is not installed yet.  It will clear the old one if the REMOVE_ALL option was selected.
			cd /tmp # Set the working directory to /tmp because otherwise setup.py for craft will be placed in the user directory and that is messy.
			if [ -d "${CRAFT_ROOT}" ]
			then
				# This will remove the current craft if desired.
				if [ -n "$REMOVE_ALL" ]
				then
					display "You have selected the REMOVE_ALL option.  Warning, this will clear the entire craft directory."
					read -p "?Do you really wish to proceed? (type y/n) " runscript2
					
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
	}


#####################################################
# FUNCTIONS RELATED TO THE SOURCE DIRECTORY AND FORKS

# This function will download a git repo if needed, and will update it if not.
# Note that this function should only be used on the primary repo, not the forked one.  For that see the next function.
	function downloadOrUpdateRepository
	{
		if [ -n "${BUILD_OFFLINE}" ]
		then
			if [ ! -d "${SRC_DIR}" ]
			then
				display "The source code for ${PACKAGE_NAME} is not downloaded, it cannot be built offline without that, exiting now."
				exit
			fi
		else
			checkForConnection "${PACKAGE_NAME}" "${REPO}"
			mkdir -p "${TOP_SRC_DIR}"
			if [ ! -d "${SRC_DIR}" ]
			then
				display "Downloading ${PACKAGE_NAME} GIT repository"
				cd "${TOP_SRC_DIR}"
				git clone "${REPO}"
			else
				display "Updating ${PACKAGE_NAME} GIT repository"
				cd "${SRC_DIR}"
				git pull
			fi
		fi
	}
	
# This function will create a Fork on Github or update an existing fork.
# It will also do all the functions of the function above for a Forked Repo.
	function createOrUpdateFork
	{
		if [ -n "${BUILD_OFFLINE}" ]
		then
			if [ ! -d "${SRC_DIR}" ]
			then
				display "The forked source code for ${PACKAGE_NAME} is not downloaded, it cannot be built offline without that, exiting now."
				exit
			fi
		else
			checkForConnection "${PACKAGE_NAME}" "${FORKED_REPO_HTML}"
			# This will download the fork if needed, or update it to the latest version if necessary
			mkdir -p "${TOP_SRC_DIR}"
			if [ ! -d "${SRC_DIR}" ]
			then
				display "The Forked Repo is not downloaded, checking if a ${PACKAGE_NAME} Fork is needed."
				# This will check to see if the repo already exists
				git ls-remote ${FORKED_REPO} -q >/dev/null 2>&1
				if [ $? -eq 0 ]
				then
					echo "The Forked Repo already exists, it can just get cloned."
				else
					echo "The ${PACKAGE_NAME} Repo has not been forked yet, please go to ${REPO} and fork it first, then run the script again.  Your fork should be at: ${FORKED_REPO}"	
					exit
				fi
			
				display "Downloading ${PACKAGE_NAME} GIT repository"
				cd "${TOP_SRC_DIR}"
				git clone "${FORKED_REPO}"
			fi
		
			# This will attempt to update the fork to match the upstream master
			display "Updating ${PACKAGE_NAME} GIT repository"
			cd "${SRC_DIR}"
			git remote show upstream >/dev/null 2>&1
			if [ $? -eq 0 ]
			then
				echo "The Local Forked Repo already has an upstream set."
			else
				 "Setting the remote upstream of the local fork to ${REPO}"
				git remote add upstream "${REPO}"
			fi
			git fetch upstream
			git pull upstream master
			git push
			echo "Your fork should be updated."
		fi
	}

# This function will prepare the Source Directory for building by calling the methods above.
	function prepareSourceDirectory
	{
		selectSourceDir
		
		# This checks if the Source Directories were set in the method above.
			if [[ -z ${SRC_DIR} || -z ${TOP_SRC_DIR} ]]
			then
				display "The Source Directories did not get set right, please edit settings.sh."
				exit 1
			fi
		
		display "Setting the source directory of ${PACKAGE_NAME} to: ${SRC_DIR} and updating it."
		
		if [ -n "${USE_FORKED_REPO}" ]
		then
			createOrUpdateFork 
		else
			downloadOrUpdateRepository
		fi
	}

