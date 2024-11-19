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
		# This checks if the function was actually sent the right number of parameters.
			if [[ -z $1 || -z $2 ]]
			then
				display "Error.  The CheckForConnection function requires two parameters."
				exit 1
			fi
		
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
# This sets up the structure of the source folders in the ASTRO_ROOT folder.  You could customize this here.
	function selectSourceDir
	{
		# This checks if any critical variables for this function are not set.
			if [ -z "${ASTRO_ROOT}" ]
			then
				display "Error.  The ASTRO_ROOT variable is not set before selectSourceDir."
				exit 1
			fi

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
# This sets up the structure of the build folders in the ASTRO_ROOT folder.  You could customize this here.
	function selectBuildDir
	{
		# This checks if any critical variables for this function are not set.
			if [[ -z "${ASTRO_ROOT}" || -z "${BUILD_FOUNDATION}" ]]
			then
				display "Error.  Either the ASTRO_ROOT or BUILD_FOUNDATION variable is not set before selectBuildDir."
				exit 1
			fi
			
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
		# This checks if any critical variables for this function are not set.
			if [[ -z "${ASTRO_ROOT}" || -z "${BUILD_FOUNDATION}" || -z "${CRAFT_ROOT}" ]]
			then
				display "Error.  One of the ASTRO_ROOT, BUILD_FOUNDATION, or CRAFT_ROOT variables is not set before automaticallySetScriptSettings."
				exit 1
			fi
			
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
		# This does set up the structure of the DEV ROOT folders in the ASTRO_ROOT directory.  You can customize this here.
			
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
		# This checks if any critical variables for this function are not set.
			if [[ -z "${HOMEBREW_ROOT}" || -z "${DEV_ROOT}" ]]
			then
				display "Error.  Either the HOMEBREW_ROOT or DEV_ROOT variable is not set before homebrewLink."
				exit 1
			fi
			
		# This checks if the function was actually sent a parameter.
			if [ -z $1 ]
			then
				display "Error.  The homebrew link function requires a folder or file to link."
				exit 1
			fi
			
		if [ ! -e "${DEV_ROOT}/$1" ]
		then
			ln -s ${HOMEBREW_ROOT}/$1 ${DEV_ROOT}/$1
		fi
	}
	
# This function will install homebrew if it hasn't been installed yet, or reset homebrew if desired.
	function setupHomebrew
	{
		checkForConnection Homebrew "https://raw.githubusercontent.com/Homebrew/install/master/install.sh"
		
		# This installs the xcode command line tools if not installed yet.
		# Yes these tools will be automatically installed if the user has never used git before
		# But sometimes they need to be installed again.
			if ! command -v xcode-select &> /dev/null
			then
				display "Installing xcode command line tools"
				xcode-select --install
			fi
		
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
		# This verifies HomeBrew is installed prior to installing a package.
			if [[ $(command -v brew) == "" ]]
			then
				display "Error.  Homebrew is not installed.  Please install homebrew before calling homebrew link."
			fi
		
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
		# This checks if any critical variables for this function are not set.
			if [[ -z "${PACKAGE_SHORT_NAME}" || -z "${BUILD_FOUNDATION}" || -z "${CRAFT_ROOT}" ]]
			then
				display "Error.  One of the required variables for installDependencies is not set."
				exit 1
			fi
			
		display "Installing Dependencies"
		if [[ "${BUILD_FOUNDATION}" == "CRAFT" ]]
		then
			source "${CRAFT_ROOT}/craft/craftenv.sh"
			craft --install-deps "${PACKAGE_SHORT_NAME}"
		else
			if [[ "${OSTYPE}" == "darwin"* ]]
			then
				brewInstallIfNeeded ${HOMEBREW_DEPENDENCIES} # Don't put quotes here so that it does each package separately.
			elif [[ "${OSTYPE}" == "linux-gnu" ]]
			then
				sudo apt -y install ${UBUNTU_DEPENDENCIES} # Don't put quotes here so that it does each package separately.
			fi
		fi
	}


#######################################
# FUNCTIONS RELATED TO PREPARING CRAFT

# This function links a file or folder in the dev directory to one in the craft-root directory
	function craftLink
	{
		# This checks if any critical variables for this function are not set.
			if [[ -z "${CRAFT_ROOT}" || -z "${DEV_ROOT}" ]]
			then
				display "Error.  Either the CRAFT_ROOT or DEV_ROOT variable is not set before calling craftLink."
				exit 1
			fi
			
		# This checks if the function was actually sent a parameter.
			if [ -z $1 ]
			then
				display "Error.  The craft link function requires a folder or file to link."
				exit 1
			fi
			
		if [ ! -e "${DEV_ROOT}/$1" ]
		then
			ln -s ${CRAFT_ROOT}/$1 ${DEV_ROOT}/$1
		fi
	}

# This copies a craft blueprint from the repository to the CRAFT blueprints folder.
# $1 is the source folder of the blueprint, $2 is the subfolder in the CraftRoot Blueprint Directory.
	function copyCraftBlueprint
	{
		# This checks if any critical variables for this function are not set.
			if [ -z "${CRAFT_ROOT}" ]
			then
				display "Error.  The CRAFT_ROOT variable was not set before calling copyCraftBlueprint."
				exit 1
			fi
			
		# This checks if the function was actually sent a parameter.
			if [[ -z $1 || -z $2 ]]
			then
				display "Error.  The copyCraftBlueprint function requires both a folder to copy and a destination in the blueprints directory."
				exit 1
			fi
		
		CRAFT_BLUEPRINT_FOLDER="${CRAFT_ROOT}/etc/blueprints/locations/craft-blueprints-kde"
			
		if [ ! -d "${CRAFT_BLUEPRINT_FOLDER}/$2" ]
		then
			cp -r $1 ${CRAFT_BLUEPRINT_FOLDER}/$2
			echo "$2 Blueprint Copied to Craft Blueprints folder."
		else
			echo "$2 Blueprint already present in Craft Blueprints folder."
		fi
	}

# This function installs Craft on various operating systems
	function installCraft
	{
		# This checks if any critical variables for this function are not set.
			if [ -z ${CRAFT_ROOT} ]
			then
				display "Error. The CRAFT_ROOT directory variable is blank when calling installCraft."
				exit 1
			fi

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
		# This checks if any critical variables for this function are not set.
			if [ -z ${CRAFT_ROOT} ]
			then
				display "Error. The CRAFT_ROOT directory variable is blank when calling setupCraft."
				exit 1
			fi
			
		# Before starting, check to see if craft's remote servers are accessible
			checkForConnection Craft "https://raw.githubusercontent.com/KDE/craft/master/setup/CraftBootstrap.py"
		
		# This will set up items required for MacOS
		
			if [[ "${OSTYPE}" == "darwin"* ]]
			then
					
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
		# This checks if any critical variables for this function are not set.
			if [[ -z "${SRC_DIR}" || -z "${TOP_SRC_DIR}" || -z "${PACKAGE_NAME}" ]]
			then
				display "Error.  One of the variables required by downloadOrUpdateRepository did not get set correctly."
				exit 1
			fi
			
		if [ -n "${BUILD_OFFLINE}" ]
		then
			if [ ! -d "${SRC_DIR}" ]
			then
				display "The source code for ${PACKAGE_NAME} is not downloaded, it cannot be built offline without that, exiting now."
				exit
			fi
		else
			if [ -n "${PACKAGE_ARCHIVE}" ]
			then
				mkdir -p "${TOP_SRC_DIR}"
				cd "${TOP_SRC_DIR}"
				curl -L "${PACKAGE_ARCHIVE}" | tar zxv -C "${TOP_SRC_DIR}"
			else
				# This checks if any critical variables for this function are not set.
				if [ -z "${REPO}" ]
				then
					display "Error.  One of the variables required by downloadOrUpdateRepository did not get set correctly."
					exit 1
				fi
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
		fi
	}
	
# This function will create a Fork on Github or update an existing fork.
# It will also do all the functions of the function above for a Forked Repo.
	function createOrUpdateFork
	{
		# This checks if any critical variables for this function are not set.
			if [[ -z "${SRC_DIR}" || -z "${TOP_SRC_DIR}" || -z "${REPO}" || -z "${FORKED_REPO}" || -z "${FORKED_REPO_HTML}" || -z "${PACKAGE_NAME}" ]]
			then
				display "Error.  One of the variables required by createOrUpdateFork did not get set correctly."
				exit 1
			fi
			
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
				echo "Setting the remote upstream of the local fork to ${REPO}"
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
		
		display "Setting the source directory of ${PACKAGE_NAME} to: ${SRC_DIR} and updating it."
		
		if [ -n "${USE_FORKED_REPO}" ]
		then
			createOrUpdateFork 
		else
			downloadOrUpdateRepository
		fi
	}

