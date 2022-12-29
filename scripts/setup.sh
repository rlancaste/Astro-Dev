#/bin/bash

#	KStars and INDI Development Setup Script
#﻿   Copyright (C) 2019 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

# This gets the directory from which this script is running so it can access any files there such as other scripts or the archive files.
# It also uses that to get the top folder file name so that it can use that in the scripts.
# Beware of changing the path to the top folder, you will have to run the script again if you do so since it will break links.
	DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
	
# This enables the script to search more than one line in functions, it is needed for the function removeRPathsFromFile
shopt -s extglob

# This resets the script options to default values.
	REMOVE_ALL=""
	BUILD_XCODE=""
	BUILD_OFFLINE=""
	BUILD_TRANSLATIONS=""
	
	
# This function checks to see if a connection to a website exists.
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
	
#This function installs a program with homebrew if it is not installed, otherwise it moves on.
	function brewInstallIfNeeded
	{
		brew ls $1 > /dev/null 2>&1
		if [ $? -ne 0 ]
		then
			if [ -n "${BUILD_OFFLINE}" ]
			then
				display "brew : $* is not installed, You are using the build offline option, exiting now."
				exit
			else
				echo "Installing : $*"
				brew install $*
			fi
		else
			echo "brew : $* is already installed"
		fi
	}
	
#This function links a file or folder in the dev directory to one in the craft-root directory
	function craftLink
	{
		ln -s ${CRAFT_ROOT}/$1 ${DEV_ROOT}/$1
	}
	
# This function will download a git repo if needed, and will update it if not
# Note that this function should only be used on the real repo, not the forked one.  For that see the next function.
# $1 is the path of the Source folder that will be created when the clone is done
# $2 is the pretty name of the repository
# $3 is the git repository to be cloned
	function downloadOrUpdateRepository
	{
		if [ -n "${BUILD_OFFLINE}" ]
		then
			if [ ! -d "$1" ]
			then
				display "The source code for $2 is not downloaded, it cannot be built offline without that, exiting now."
				exit
			fi
		else
			mkdir -p "${SRC_FOLDER}"
			if [ ! -d "$1" ]
			then
				display "Downloading $2 GIT repository"
				cd "${SRC_FOLDER}"
				git clone "$3"
			else
				display "Updating $2 GIT repository"
				cd "$1"
				git pull
			fi
		fi
	}
	
# This function will create a Fork on Github or update an existing fork
# It will also do all the functions of the function above for a Forked Repo
# $1 is the path of the Source folder that will be created when the clone is done
# $2 is the pretty name of the repository
# $3 is the git repository to be forked to $4
# $4 is the git repository to be cloned

	function createOrUpdateFork
	{
		if [ -n "${BUILD_OFFLINE}" ]
		then
			if [ ! -d "$1" ]
			then
				display "The forked source code for $2 is not downloaded, it cannot be built offline without that, exiting now."
				exit
			fi
		else
			# This will download the fork if needed, or update it to the latest version if necessary
			mkdir -p "${FORKED_SRC_FOLDER}"
			if [ ! -d "$1" ]
			then
				display "The Forked Repo is not downloaded, checking if a $2 Fork is needed."
				# This will check to see if the repo already exists
				git ls-remote "$4" -q >/dev/null 2>&1
				if [ $? -eq 0 ]
				then
					echo "The Forked Repo already exists, it can just get cloned."
				else
					echo "The $2 Repo has not been forked yet, please go to the website and fork it first, then run the script again."	
					exit
				fi
			
				display "Downloading $2 GIT repository"
				cd "${FORKED_SRC_FOLDER}"
				git clone "$4"
			fi
		
			# This will attempt to update the fork to match the upstream master
			display "Updating $2 GIT repository"
			cd "$1"
			git remote add upstream "$3"
			git fetch upstream
			git pull upstream master
			git push
		fi
	}

# This function shortens the amount of code needed to clean the build directories if desired, make them if needed, and enter them
# $1 is the path to the build directory, $2 is the name of the package to be built
	function setupAndEnterBuildDir
	{
		display "Setting up and entering $2 build directory: $1"
		if [ -d "$1" ]
		then
			if [ -n "$REMOVE_ALL" ]
			then
				rm -r "$1"/*
			fi
		else
			mkdir -p "$1"
		fi
		cd "$1"
	}
	
# This function will remove and rewrite the qt.conf file so that KStars and INDI Web Manager can find required Resources
# It used to be in the function above, but I found that if the QT version gets changed, this file needs to be recreated, so I separated it.
function writeQTConf
	{
		App="$1"
		
		rm "${App}/Contents/Resources/qt.conf"
		
		##################
		cat > "${App}/Contents/Resources/qt.conf" <<- EOF
		[Paths]
		Prefix = ${DEV_ROOT}
		Plugins = plugIns
		Imports = qml
		Qml2Imports = qml
		EOF
		##################
		
	}

#This will print out how to use the script
	function displayUsageAndExit
	{
		cat  <<- EOF
			script options:
				-h Display the help information
				-r Remove everything from the build directories and start fresh
				-o Build the packages offline (Note: This requires that the source code was downloaded already)
				-x build an x-code project from the source files instead of the cmake build.
		EOF
		exit
	}

#This function processes the user's options for running the script
	function processOptions
	{
		while getopts "rhoxt" option
		do
			case $option in
				r)
					REMOVE_ALL="Yep"
					;;
				h)
					displayUsageAndExit
					;;
				o)
					BUILD_OFFLINE="Yep"
					;;
				x)
					BUILD_XCODE="Yep"
					;;
				t)
					BUILD_TRANSLATIONS="Yep"
					;;
				*)
					display "Unsupported option $option"
					displayUsageAndExit
					exit
					;;
			esac
		done
		shift $((${OPTIND} - 1))

		echo ""
		echo "REMOVE_ALL         = ${REMOVE_ALL:-Nope}"
		echo "BUILD_XCODE        = ${BUILD_XCODE:-Nope}"
		echo "BUILD_OFFLINE      = ${BUILD_OFFLINE:-Nope}"
		echo "BUILD_TRANSLATIONS = ${BUILD_TRANSLATIONS:-Nope}"
	}

# This Function processes a given file using otool to see what files it is currently linked to.
# It adds RPATHS for the QT lib folder and the dev lib folder so that the files can be found when the local Frameworks folder and QT is deleted.
# If the file it is linking to is a Qt folder, it makes sure the link becomes an rpath so it can be found using the rpath.
# it uses install_name_tool to update those files
	function processTarget
	{
		target=$1
		
		# This determines if it is a Mach-O file that can be processed
		if [[ "$(/usr/bin/file "${target}")" =~ ^${target}:\ *Mach-O\ .*$ ]]
    	then
			
			removeRPathsFromFile "${target}"
			#These are needed to add the new rpaths to the libraries associated with this build.
			install_name_tool -add_rpath "${DEV_ROOT}/lib" $target >/dev/null 2>&1
			
			IGNORED_OTOOL_OUTPUT="/usr/lib/|/System/"
			entries=$(otool -L $target | sed '1d' | awk '{print $1}' | egrep -v "$IGNORED_OTOOL_OUTPUT")
			#echo "Processing $target"
			
			#This section had to be added since I had to add some dylibs that were still linked to my craft root.
			if [[ "${target}" == *.dylib ]]
			then
				newname="@rpath/$(basename $target)"	
			
				install_name_tool -id \
				$newname \
				$target
				
				for entry in $entries
				do
					if [[ "${entry}" != @rpath* ]]
					then
						baseEntry=$(basename $entry)
						newname=""
						newname="@rpath/${baseEntry}"
						#echo "    change reference $entry -> $newname" 

						install_name_tool -change \
						$entry \
						$newname \
						$target
					fi
				done
			fi
			
			#This section converts any things packaged by Craft
			for entry in $entries
			do
				baseEntry=$(echo ${entry} | sed 's/^.*Frameworks//' | sed 's/^.*@loader_path//')
			
				if [[ $baseEntry == /Qt* ]]
				then
			
					newname=""
					newname="@rpath${baseEntry}"
					echo "    change reference $entry -> $newname" 

					install_name_tool -change \
					$entry \
					$newname \
					$target
				fi
			
			done
			#echo ""
			#echo "   otool for $target after"
			#otool -L $target | awk '{printf("\t%s\n", $0)}'
		fi
	
	}

#This function will recursively process all the files in a directory and will use the processTarget function on them
	function processDirectory
	{
		directory=$1
		echo "Processing all of the files in $directory"
		for file in ${directory}/*
		do
        	if [ -d "${file}" ]
        	then
        		base=$(basename ${file})
        		if [[ ${base} != *.dSYM ]]
				then
        			processDirectory "${file}"
        		fi
        	else
        		base=$(basename ${file})
        		#echo "Processing file ${base}"
        		processTarget ${file}
        	fi
		done
	}

# This function will remote all rpaths currently in a file
# Thank you to this forum: https://stackoverflow.com/questions/12521802/print-rpath-of-an-executable-on-macos/12522096
	function removeRPathsFromFile
	{
		file=$1
		
		IFS=$'\n'
		_next_path_is_rpath=""
		
		/usr/bin/otool -l "${file}" | grep RPATH -A2 |
		while read line
		do
			case "${line}" in
				*(\ )cmd\ LC_RPATH)
					_next_path_is_rpath="yes"
					;;
				*(\ )path\ *\ \(offset\ +([0-9])\))
					if [ -z "${_next_path_is_rpath}" ]
					then
						continue
					fi
					line="${line#* path }"
					line="${line% (offset *}"
					if [ ${#} -gt 1 ]
					then
						line=$'\t'"${line}"
					fi
					install_name_tool -delete_rpath "${line}" "${file}"
					#echo "Deleting rpath ${line} from ${file}"
					_next_path_is_rpath=""
					;;
			esac
		done
	}
	
	
########################################################################################
# This is where the main part of the script starts!
#

# Prepare to run the script by setting all of the environment variables	
# If you want to customize any of those variables, you can edit this file
	source ${DIR}/build-env.sh

#Process the command line options to determine what to do.
	processOptions $@

# Display the Welcome message.
	display "This will setup a Development Environment for KStars and INDI on your Mac.  It is based on Craft. It will place the development directory at the location specified.  It will use QT Located in your home directory.  Edit this script if that is incorrect."

# Before starting, check to see if the remote servers are accessible
	if [ -n "${BUILD_OFFLINE}" ]
	then
		display "Not checking connections because build-offline was selected.  All repos must already be downloaded to the source folders."
	else
		display "Checking Connections"
	
		checkForConnection "INDI Repository" "${INDI_REPO}"
		checkForConnection "INDI 3rd Party Repository" "${THIRDPARTY_REPO}"
		#checkForConnection "KStars Repository" "${KSTARS_REPO}"
		checkForConnection "INDI Web Manager Repository" "${WEBMANAGER_REPO}"
	fi

## This makes sure that if the build XCODE option is selected, the user has specified a CODE_SIGN_IDENTITY because if not, it won't work properly
	if [ -n "${BUILD_XCODE}" ]
	then
		if [ -n "${CODE_SIGN_IDENTITY}" ]
		then
			display "Building for XCode and code signing with the identity ${CODE_SIGN_IDENTITY}."
		else
			display "You have not specified a CODE_SIGN_IDENTITY, but you requested an XCode Build.  A Certificate is required for an XCode Build.  Make sure to get a certificate either from the Apple Developer program or from KeyChain Access on your Mac (A Self Signed Certificate is fine as long as you don't want to distribute KStars).  Before you run this script, execute the command: export CODE_SIGN_IDENTITY=XXXXXXX"
			exit 1
		fi
	fi

# The following if statements set up each of the source and build folders for each build based upon the options you selected in build-env.
# This includes whether you want to use Xcode or not for the whole build and whether you want to use your own fork or not for each build

if [ -n "${BUILD_XCODE}" ]
then
	export BUILD_FOLDER="${XCODE_BUILD_FOLDER}"
	export FORKED_BUILD_FOLDER="${FORKED_XCODE_BUILD_FOLDER}"
fi

if [ -n "${FORKED_INDI_REPO}" ]
then
	echo "Using forked INDI Repo: ${FORKED_INDI_REPO}" 
	export INDI_SRC_FOLDER="${FORKED_SRC_FOLDER}/indi"
	export INDI_BUILD_FOLDER="${FORKED_BUILD_FOLDER}/indi-build/indi-core"
else
	echo "Using INDI Repo: ${INDI_REPO}"
	export INDI_SRC_FOLDER="${SRC_FOLDER}/indi"
	export INDI_BUILD_FOLDER="${BUILD_FOLDER}/indi-build/indi-core"
fi

if [ -n "${FORKED_THIRDPARTY_REPO}" ]
then
	echo "Using forked 3rd Party Repo: ${FORKED_THIRDPARTY_REPO}" 
	export THIRDPARTY_SRC_FOLDER="${FORKED_SRC_FOLDER}/indi-3rdParty"
	export THIRDPARTY_LIBRARIES_BUILD_FOLDER="${FORKED_BUILD_FOLDER}/indi-build/ThirdParty-Libraries"
	export THIRDPARTY_DRIVERS_BUILD_FOLDER="${FORKED_BUILD_FOLDER}/indi-build/ThirdParty-Drivers"
else
	echo "Using 3rd Party Repo: ${THIRDPARTY_REPO}"
	export THIRDPARTY_SRC_FOLDER="${SRC_FOLDER}/indi-3rdParty"
	export THIRDPARTY_LIBRARIES_BUILD_FOLDER="${BUILD_FOLDER}/indi-build/ThirdParty-Libraries"
	export THIRDPARTY_DRIVERS_BUILD_FOLDER="${BUILD_FOLDER}/indi-build/ThirdParty-Drivers"
fi

if [ -n "${FORKED_STELLARSOLVER_REPO}" ]
then
	echo "Using forked StellarSolver Repo: ${FORKED_STELLARSOLVER_REPO}" 
	export STELLAR_SRC_FOLDER="${FORKED_SRC_FOLDER}/stellarsolver"
	export STELLAR_BUILD_FOLDER="${FORKED_BUILD_FOLDER}/stellar-build"
else
	echo "Using StellarSolver Repo: ${STELLARSOLVER_REPO}"
	export STELLAR_SRC_FOLDER="${SRC_FOLDER}/stellarsolver"
	export STELLAR_BUILD_FOLDER="${BUILD_FOLDER}/stellar-build"
fi

if [ -n "${FORKED_KSTARS_REPO}" ]
then
	echo "Using forked KStars Repo: ${FORKED_KSTARS_REPO}" 
	export KSTARS_SRC_FOLDER="${FORKED_SRC_FOLDER}/kstars"
	export KSTARS_BUILD_FOLDER="${FORKED_BUILD_FOLDER}/kstars-build"
else
	echo "Using KStars Repo: ${KSTARS_REPO}"
	export KSTARS_SRC_FOLDER="${SRC_FOLDER}/kstars"
	export KSTARS_BUILD_FOLDER="${BUILD_FOLDER}/kstars-build"
fi

if [ -n "${FORKED_WEBMANAGER_REPO}" ]
then
	echo "Using forked Web Manaager Repo: ${FORKED_WEBMANAGER_REPO}" 
	export WEBMANAGER_SRC_FOLDER="${FORKED_SRC_FOLDER}/INDIWebManagerApp"
	export WEBMANAGER_BUILD_FOLDER="${FORKED_BUILD_FOLDER}/webmanager-build"
else
	echo "Using Web Manager Repo: ${WEBMANAGER_REPO}"
	export WEBMANAGER_SRC_FOLDER="${SRC_FOLDER}/INDIWebManagerApp"
	export WEBMANAGER_BUILD_FOLDER="${BUILD_FOLDER}/webmanager-build"
fi

# This checks if any of the path variables are blank, since if they are blank, it could start trying to do things in the / folder, which is not good
	if [[ -z ${DIR} || -z ${TOP_FOLDER} || -z ${SRC_FOLDER} || -z ${FORKED_SRC_FOLDER} || -z ${INDI_SRC_FOLDER} || -z ${THIRDPARTY_SRC_FOLDER} || -z ${KSTARS_SRC_FOLDER} || -z ${WEBMANAGER_SRC_FOLDER} || -z ${BUILD_FOLDER} || -z ${DEV_ROOT} ]]
	then
  		display "One or more critical directory variables is blank, please edit build-env.sh."
  		exit 1
	fi
	
# This checks the most important variables to see if the paths exist.  If they don't, it terminates the script with a message.
	if [ ! -d "${CRAFT_ROOT}" ]
	then
		display "Craft Does Not Exist at the directory specified, please install Craft or edit this script."
		exit 1
	fi
	
#This will install homebrew if it hasn't been installed yet, or reset homebrew if desired.
# If you do not want to use homebrew, then you need to remove or edit this section of the script.
	if [ -d "/usr/local/Homebrew" ]
	then
		#This will remove all the homebrew packages if desired.
		if [ -n "$REMOVE_ALL" ]
		then
			display "You have selected the REMOVE_ALL option."
			read -p "Do you also want to remove Homebrew packages and reinstall them? (y/n)" reinstallHomebrew
			if [ "$reinstallHomebrew" == "y" ]
			then
				brew remove --force $(brew list) --ignore-dependencies
			fi
		fi  
	else
		if [ -n "${BUILD_OFFLINE}" ]
		then
			display "Homebrew was not found on your system and you selected the BUILD OFFLINE option. Please install Homebrew next time you have an internet connection, exiting now."
			exit
		else
			display "Installing Homebrew."
			/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
		fi
	fi

# This will install KStars and INDI dependencies from Homebrew.
# These items are needed from Homebrew.  If you don't want homebrew, then you need to install them another way and get them in your PATH
	display "Checking/Installing Homebrew Dependencies."
	brew upgrade
	 
	brewInstallIfNeeded cmake
	brewInstallIfNeeded gettext
	
	# It would be good to sort this out.  gpg2 should be built in craft.  This is needed for translations to work.
	brewInstallIfNeeded gpg
	brewInstallIfNeeded svn
	
	# This is because gpg is not called gpg2 and translations call on gpg2.  Fix this??
	ln -sf $(brew --prefix)/bin/gpg $(brew --prefix)/bin/gpg2
	
# This sets up the development root directory for "installation"
	mkdir -p "${DEV_ROOT}/bin"
	export PATH="${DEV_ROOT}/bin:${CRAFT_ROOT}/bin:${CRAFT_ROOT}/dev-utils/bin:${PATH}"
	craftLink bin/meinproc5
	craftLink bin/desktoptojson
	craftLink bin/checkXML5
	craftLink bin/qmake
	craftLink bin/moc
	craftLink bin/rcc
	craftLink bin/uic
	craftLink bin/qdbuscpp2xml
	craftLink bin/qdbusxml2cpp
	
	mkdir -p "${DEV_ROOT}/include"
	ln -s ${CRAFT_ROOT}/include/* ${DEV_ROOT}/include/
	
	mkdir -p "${DEV_ROOT}/lib"
	ln -s ${CRAFT_ROOT}/lib/* ${DEV_ROOT}/lib/
	
	mkdir -p "${DEV_ROOT}/share"
	craftLink share/kf5
	
	craftLink plugins
	craftLink .//mkspecs
	craftLink qml
	

# This is the start of the build section of the Script.

# This section will build INDI CORE
	if [ -n "${BUILD_INDI}" ]
	then
		if [ -n "${FORKED_INDI_REPO}" ]
		then
			createOrUpdateFork "${INDI_SRC_FOLDER}" "INDI Core" "${INDI_REPO}" "${FORKED_INDI_REPO}"
		else
			downloadOrUpdateRepository "${INDI_SRC_FOLDER}" "INDI Core" "${INDI_REPO}"
		fi
		
		setupAndEnterBuildDir "${INDI_BUILD_FOLDER}" "INDI Core"
		
		if [ -n "${BUILD_XCODE}" ]
		then
			display "Building INDI Core Drivers using XCode"
			cmake -G Xcode -DCMAKE_BUILD_TYPE=Debug -DCMAKE_MACOSX_RPATH=1 -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 -DCMAKE_INSTALL_RPATH="${DEV_ROOT}/lib" -DCMAKE_INSTALL_PREFIX="${DEV_ROOT}" -DCMAKE_PREFIX_PATH="${PREFIX_PATH}" "${INDI_SRC_FOLDER}"
			xcodebuild -project libindi.xcodeproj -alltargets -configuration Debug CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" OTHER_CODE_SIGN_FLAGS="--deep"
		else
			display "Building INDI Core Drivers"
			cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_MACOSX_RPATH=1 -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 -DCMAKE_INSTALL_RPATH="${DEV_ROOT}/lib" -DCMAKE_INSTALL_PREFIX="${DEV_ROOT}" -DCMAKE_PREFIX_PATH="${PREFIX_PATH}" "${INDI_SRC_FOLDER}"
			make -j $(expr $(sysctl -n hw.ncpu) + 2)
			make install
		fi
	fi

# This section will build INDI 3rd Party libraries and drivers.

	if [ -n "${BUILD_THIRDPARTY}" ]
	then
		if [ -n "${FORKED_THIRDPARTY_REPO}" ]
		then
			createOrUpdateFork "${THIRDPARTY_SRC_FOLDER}" "INDI 3rd Party" "${THIRDPARTY_REPO}" "${FORKED_THIRDPARTY_REPO}"
		else
			downloadOrUpdateRepository "${THIRDPARTY_SRC_FOLDER}" "INDI 3rd Party" "${THIRDPARTY_REPO}"
		fi
		
		setupAndEnterBuildDir "${THIRDPARTY_LIBRARIES_BUILD_FOLDER}" "ThirdParty Libraries"
		
		if [ -n "${BUILD_XCODE}" ]
		then
			display "Building INDI 3rd Party Libraries using XCode"
			cmake -G Xcode -DCMAKE_BUILD_TYPE=Debug -DCMAKE_MACOSX_RPATH=1 -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 -DCMAKE_INSTALL_RPATH="${DEV_ROOT}/lib" -DCMAKE_INSTALL_PREFIX="${DEV_ROOT}" -DBUILD_LIBS=1 -DCMAKE_PREFIX_PATH="${PREFIX_PATH}" "${THIRDPARTY_SRC_FOLDER}"
			xcodebuild -project libindi-3rdparty.xcodeproj -alltargets -configuration Debug CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" OTHER_CODE_SIGN_FLAGS="--deep"
		else
			display "Building INDI 3rd Party Libraries"
			cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_MACOSX_RPATH=1 -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 -DCMAKE_INSTALL_RPATH="${DEV_ROOT}/lib" -DCMAKE_INSTALL_PREFIX="${DEV_ROOT}" -DBUILD_LIBS=1 -DCMAKE_PREFIX_PATH="${PREFIX_PATH}" "${THIRDPARTY_SRC_FOLDER}"
			make -j $(expr $(sysctl -n hw.ncpu) + 2)
			make install 
		fi
	
		setupAndEnterBuildDir "${THIRDPARTY_DRIVERS_BUILD_FOLDER}" "ThirdParty Drivers"
		
		if [ -n "${BUILD_XCODE}" ]
		then
			display "Building INDI 3rd Party Drivers using XCode"
			cmake -G Xcode -DCMAKE_BUILD_TYPE=Debug -DCMAKE_MACOSX_RPATH=1 -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 -DCMAKE_INSTALL_RPATH="${DEV_ROOT}/lib" -DCMAKE_INSTALL_PREFIX="${DEV_ROOT}" -DCMAKE_PREFIX_PATH="${PREFIX_PATH}" "${THIRDPARTY_SRC_FOLDER}"
			xcodebuild -project libindi-3rdparty.xcodeproj -alltargets -configuration Debug CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" OTHER_CODE_SIGN_FLAGS="--deep"
		else
			display "Building INDI 3rd Party Drivers"
			cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_MACOSX_RPATH=1 -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 -DCMAKE_INSTALL_RPATH="${DEV_ROOT}/lib" -DCMAKE_INSTALL_PREFIX="${DEV_ROOT}" -DCMAKE_PREFIX_PATH="${PREFIX_PATH}" "${THIRDPARTY_SRC_FOLDER}"
			make -j $(expr $(sysctl -n hw.ncpu) + 2)
			make install
		fi
	fi
	
# This section will build StellarSolver.

	if [ -n "${BUILD_STELLARSOLVER}" ]
	then
		if [ -n "${FORKED_STELLARSOLVER_REPO}" ]
		then
			createOrUpdateFork "${STELLAR_SRC_FOLDER}" "StellarSolver" "${STELLARSOLVER_REPO}" "${FORKED_STELLARSOLVER_REPO}"
		else
			downloadOrUpdateRepository "${STELLAR_SRC_FOLDER}" "StellarSolver" "${STELLARSOLVER_REPO}"
		fi
		
		setupAndEnterBuildDir "${STELLAR_BUILD_FOLDER}" "StellarSolver"
		
		#This will set the StellarSolver app bundle for linking.
		if [ -n "${BUILD_XCODE}" ]
		then
			export StellarApp="${STELLAR_BUILD_FOLDER}/Debug/StellarSolverTester.app"
		else
			export StellarApp="${STELLAR_BUILD_FOLDER}/StellarSolverTester.app"
		fi
		
		if [ -n "${BUILD_XCODE}" ]
		then
			display "Building StellarSolver using XCode"
			cmake -G Xcode -DCMAKE_BUILD_TYPE=Debug -DCMAKE_MACOSX_RPATH=1 -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 -DCMAKE_INSTALL_RPATH="${DEV_ROOT}/lib" -DCMAKE_INSTALL_PREFIX="${DEV_ROOT}" -DBUILD_TESTER=1 -DCMAKE_PREFIX_PATH="${PREFIX_PATH}" "${STELLAR_SRC_FOLDER}"
			xcodebuild -project StellarSolver.xcodeproj -alltargets -configuration Debug CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" OTHER_CODE_SIGN_FLAGS="--deep"
		else
			display "Building StellarSolver"
			cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_MACOSX_RPATH=1 -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 -DCMAKE_INSTALL_RPATH="${DEV_ROOT}/lib" -DCMAKE_INSTALL_PREFIX="${DEV_ROOT}" -DBUILD_TESTER=1 -DCMAKE_PREFIX_PATH="${PREFIX_PATH}" "${STELLAR_SRC_FOLDER}"
			make -j $(expr $(sysctl -n hw.ncpu) + 2)
			make install 
		fi
		
		ln -sf "${DEV_ROOT}/StellarSolverTester.app" "${TOP_FOLDER}/StellarSolverTester.app"
	fi
	
# This section will build KStars

	if [ -n "${BUILD_KSTARS}" ]
	then
		if [ -n "${FORKED_KSTARS_REPO}" ]
		then
			createOrUpdateFork "${KSTARS_SRC_FOLDER}" "KStars" "${KSTARS_REPO}" "${FORKED_KSTARS_REPO}"
		else
			downloadOrUpdateRepository "${KSTARS_SRC_FOLDER}" "KStars" "${KSTARS_REPO}"
		fi
		
        setupAndEnterBuildDir "${KSTARS_BUILD_FOLDER}" "KStars"
		
		#This will set the KStars app bundle the script will be building inside of.  It also makes sure the path to it exists.
		if [ -n "${BUILD_XCODE}" ]
		then
			export KStarsApp="${KSTARS_BUILD_FOLDER}/bin/Debug/KStars.app"
			mkdir -p "${KSTARS_BUILD_FOLDER}/bin/Debug"
		else
			export KStarsApp="${KSTARS_BUILD_FOLDER}/bin/KStars.app"
			mkdir -p "${KSTARS_BUILD_FOLDER}/bin/"
		fi
		
		writeQTConf "${KStarsApp}"
		
		if [ -n "${BUILD_XCODE}" ]
		then
			display "Building KStars using XCode"
			cmake -G Xcode -DCMAKE_BUILD_TYPE=Debug -DCMAKE_MACOSX_RPATH=1 -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 -DCMAKE_INSTALL_RPATH="${DEV_ROOT}/lib" -DCMAKE_INSTALL_PREFIX="${DEV_ROOT}" -DKDE_INSTALL_BUNDLEDIR="${DEV_ROOT}" -DCMAKE_PREFIX_PATH="${PREFIX_PATH}" "${KSTARS_SRC_FOLDER}"
			xcodebuild -project kstars.xcodeproj -target "kstars" -configuration Debug CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" OTHER_CODE_SIGN_FLAGS="--deep"
			
			# This is needed because sometimes in XCode you use the Debug folder and sometimes the Release folder.
			mkdir - p  "${KSTARS_BUILD_FOLDER}/bin/Release"
			cp -rf "${KSTARS_BUILD_FOLDER}/bin/Debug/KStars.app" "${KSTARS_BUILD_FOLDER}/bin/Release/KStars.app"
			
			codesign --force --deep -s "${CODE_SIGN_IDENTITY}" "${KSTARS_BUILD_FOLDER}/bin/Debug/KStars.app"
			codesign --force --deep -s "${CODE_SIGN_IDENTITY}" "${KSTARS_BUILD_FOLDER}/bin/Release/KStars.app"
		else
			display "Building KStars"
			if [ -n "${BUILD_TRANSLATIONS}" ]
			then
				cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_DOC=OFF -DFETCH_TRANSLATIONS=ON -DKDE_L10N_AUTO_TRANSLATIONS=ON -DCMAKE_MACOSX_RPATH=1 -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 -DCMAKE_INSTALL_RPATH="${DEV_ROOT}/lib" -DCMAKE_INSTALL_PREFIX="${DEV_ROOT}" -DKDE_INSTALL_BUNDLEDIR="${DEV_ROOT}" -DCMAKE_PREFIX_PATH="${PREFIX_PATH}" "${KSTARS_SRC_FOLDER}"
				make -j $(expr $(sysctl -n hw.ncpu) + 2)
				cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_DOC=OFF -DFETCH_TRANSLATIONS=OFF -DKDE_L10N_AUTO_TRANSLATIONS=ON -DCMAKE_MACOSX_RPATH=1 -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 -DCMAKE_INSTALL_RPATH="${DEV_ROOT}/lib" -DCMAKE_INSTALL_PREFIX="${DEV_ROOT}" -DKDE_INSTALL_BUNDLEDIR="${DEV_ROOT}" -DCMAKE_PREFIX_PATH="${PREFIX_PATH}" "${KSTARS_SRC_FOLDER}"
				make -j $(expr $(sysctl -n hw.ncpu) + 2)
			else
				cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_DOC=OFF -DCMAKE_MACOSX_RPATH=1 -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 -DCMAKE_INSTALL_RPATH="${DEV_ROOT}/lib" -DCMAKE_INSTALL_PREFIX="${DEV_ROOT}" -DKDE_INSTALL_BUNDLEDIR="${DEV_ROOT}" -DCMAKE_PREFIX_PATH="${PREFIX_PATH}" "${KSTARS_SRC_FOLDER}"
				cmake --build . --target kstars -- -j$(expr $(sysctl -n hw.ncpu) + 2)
			fi
			
			make install
		fi

		ln -sf "${DEV_ROOT}/KStars.app" "${TOP_FOLDER}/KStars.app"
	fi
	
# This section will build INDIWebManagerApp

	if [ -n "${BUILD_WEBMANAGER}" ]
	then
		if [ -n "${FORKED_WEBMANAGER_REPO}" ]
		then
			createOrUpdateFork "${WEBMANAGER_SRC_FOLDER}" "INDI Web Manager App" "${WEBMANAGER_REPO}" "${FORKED_WEBMANAGER_REPO}"
		else
			downloadOrUpdateRepository "${WEBMANAGER_SRC_FOLDER}" "INDI Web Manager App" "${WEBMANAGER_REPO}"
		fi

		setupAndEnterBuildDir "${WEBMANAGER_BUILD_FOLDER}" "INDI Web Manager App"
	
		#This will set the INDIWebManagerApp app bundle the script will be building inside of.  It also makes sure the path to it exists.
		if [ -n "${BUILD_XCODE}" ]
		then
			export INDIWebManagerApp="${WEBMANAGER_BUILD_FOLDER}/Debug/INDIWebManagerApp.app"
			mkdir -p "${WEBMANAGER_BUILD_FOLDER}/Debug"
		else
			export INDIWebManagerApp="${WEBMANAGER_BUILD_FOLDER}/INDIWebManagerApp.app"
			mkdir -p "${WEBMANAGER_BUILD_FOLDER}"
		fi
		
		writeQTConf ${INDIWebManagerApp}
		
		if [ -n "${BUILD_XCODE}" ]
		then
			display "Building INDI Web Manager App using XCode"
			cmake -G Xcode -DCMAKE_BUILD_TYPE=Debug -DCMAKE_MACOSX_RPATH=1 -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 -DCMAKE_INSTALL_RPATH="${DEV_ROOT}/lib" -DCMAKE_INSTALL_PREFIX="${DEV_ROOT}" -DKDE_INSTALL_BUNDLEDIR="${DEV_ROOT}" -DCMAKE_PREFIX_PATH="${PREFIX_PATH}" "${WEBMANAGER_SRC_FOLDER}"
			xcodebuild -project INDIWebManagerApp.xcodeproj -target "INDIWebManagerApp" -configuration Debug CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" OTHER_CODE_SIGN_FLAGS="--deep"
		else
			display "Building INDI Web Manager App"
			cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_MACOSX_RPATH=1 -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 -DCMAKE_INSTALL_RPATH="${DEV_ROOT}/lib" -DCMAKE_INSTALL_PREFIX="${DEV_ROOT}" -DKDE_INSTALL_BUNDLEDIR="${DEV_ROOT}" -DCMAKE_PREFIX_PATH="${PREFIX_PATH}" "${WEBMANAGER_SRC_FOLDER}"
			make -j $(expr $(sysctl -n hw.ncpu) + 2)
			make install
		fi

		ln -sf "${DEV_ROOT}/INDIWebManagerApp.app" "${TOP_FOLDER}/INDIWebManagerApp.app"
	fi

display "Script Execution Complete"
