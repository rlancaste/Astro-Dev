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

# This function will take a newly copied app bundle for building purposes, delete directories, and link it to the system QT
# $1 is the path to the App bundle to be processed.
	function reLinkAppBundle
	{
		App="$1"
		rm -rf "${App}/Contents/Frameworks"
		rm -r "${App}/Contents/Resources/qml"
		rm -r "${App}/Contents/Plugins"
		rm -r "${App}/Contents/MacOS/indi"*
		ln -sf "${DEV_ROOT}/bin/indi"* "${App}/Contents/MacOS/"
		
		#This Directory needs to be processed because there are number of executables that will be looking in Frameworks for their libraries
		#This command will cause them to look to the lib directory and QT.
		processDirectory "${App}/Contents/MacOS"
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
		Prefix = ${QT_PATH}
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
			#These are needed to add the new rpaths to QT and the libraries associated with this build.
			install_name_tool -add_rpath "${DEV_ROOT}/lib" $target >/dev/null 2>&1
			install_name_tool -add_rpath "${QT_PATH}/lib" $target >/dev/null 2>&1
			
			IGNORED_OTOOL_OUTPUT="/usr/lib/|/System/"
			entries=$(otool -L $target | sed '1d' | awk '{print $1}' | egrep -v "$IGNORED_OTOOL_OUTPUT")
			#echo "Processing $target"
			
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
						echo "    change reference $entry -> $newname" 

						install_name_tool -change \
						$entry \
						$newname \
						$target
					fi
				done
			fi
			
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

#This function will recursively process all the files in the CMAKE directory to correct the hard coded paths in there and relink them
	function processCMakeDirectory
	{
		directory=$1
		echo "Processing all of the CMake files in $directory"
		SDK_IN_ZIP="/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX11.0.sdk"
		#if [ "${SDK_PATH}" = "${SDK_IN_ZIP}" ]
        #then
        #	echo "Your requested SDK Path matches the path in the zip file, so the path to the SDK will not be updated in the cmake files."
        #fi
		for file in ${directory}/*
		do
        	if [ -d "${file}" ]
        	then
        		processCMakeDirectory "${file}"
        	else
        		#echo "Changing file: $file to have paths based on: $DEV_ROOT"
        		sed -i.bak 's|/Users/rlancaste/AstroRoot/craft-root/lib|'$DEV_ROOT'/lib|g' ${file}
        		sed -i.bak 's|/Users/rlancaste/AstroRoot/craft-root/include|'$DEV_ROOT'/include|g' ${file}
        		if [ "${SDK_PATH}" != "${SDK_IN_ZIP}" ]
        		then
        			#echo "Updating SDK Path in: $file to: $SDK_PATH"
        			sed -i.bak 's|'$SDK_IN_ZIP'|'$SDK_PATH'|g' ${file}
        		fi
        		baseDir=$(basename ${directory})
        		if [[ "${file}" == *Config.cmake ]] && [[ "${baseDir}" == Qt5* ]]
        		then
        			package="${baseDir:3}"
        			sed -i.bak 's|^get_filename_component(_qt5'$package'_install_prefix.*$|get_filename_component(_qt5'$package'_install_prefix '$QT_PATH' ABSOLUTE)|g' ${DEV_ROOT}/lib/cmake/Qt5"${package}"/Qt5"${package}"Config.cmake
        		fi
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
	display "This will use an existing KStars App to setup a Development Environment for KStars and INDI on your Mac that does not depend on Craft or Homebrew.  It assumes the KStars app bundle is at /Applications/KStars.app.  It will place the development directory at the location specified.  It will use QT Located in your home directory.  Edit this script if that is incorrect."

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
	if [[ -z ${DIR} || -z ${TOP_FOLDER} || -z ${SRC_FOLDER} || -z ${FORKED_SRC_FOLDER} || -z ${INDI_SRC_FOLDER} || -z ${THIRDPARTY_SRC_FOLDER} || -z ${KSTARS_SRC_FOLDER} || -z ${WEBMANAGER_SRC_FOLDER} || -z ${BUILD_FOLDER} || -z ${DEV_ROOT} || -z ${sourceKStarsApp} || -z ${sourceINDIWebManagerApp} ]]
	then
  		display "One or more critical directory variables is blank, please edit build-env.sh."
  		exit 1
	fi
	
# This checks the most important variables to see if the paths exist.  If they don't, it terminates the script with a message.
	if [ ! -d "${QT_PATH}" ]
	then
		display "QT Does Not Exist at the directory specified, please install QT or edit this script."
		exit 1
	fi
	
	if [ ! -d "${sourceKStarsApp}" ]
	then
		display "The source KStars app does not exist at the directory specified. This script relies on an existing KStars APP bundle in order to set up the development environment.  Please download KStars.app or edit this script."
		exit 1
	fi
	
	if [ ! -d "${sourceINDIWebManagerApp}" ]
	then
		display "The source INDI Web Manager App does not exist at the directory specified.  Skipping Web Manager build.  If you want to build the INDI Web Manager App, either download an existing copy, or edit this script to change the path to it."
		BUILD_WEBMANAGER=""
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

# This will remove all the files in the ASTRO development root folder so it can start fresh.
	if [ -n "${REMOVE_ALL}" ]
	then
		if [ -d "${DEV_ROOT}" ]
		then
			rm -fr "${DEV_ROOT}"
			rm "${TOP_FOLDER}/INDIWebManagerApp.app"
			rm "${TOP_FOLDER}/KStars.app"
		fi
	fi

# This section will copy the dynamic libraries that KStars and INDI will need from an existing KStars.app bundle
	if [ ! -d "${DEV_ROOT}/lib" ]
	then
		display "Copying Dynamic Libraries from an existing KStars.app"
		mkdir -p "${DEV_ROOT}/lib"
		libDir="${DEV_ROOT}/lib"
		cp -fr "${sourceKStarsApp}/Contents/Frameworks"/* "${DEV_ROOT}/lib/"

		display "Making Simple Dynamics Library copies so find_package can find them."
		for file in "${libDir}"/*
		do
			fileName=$(basename ${file})
		
		
			# This will make copies of the dynamic libraries in the lib folder without version numbers
			# If the file is a kf5 library, it also seems to need the FULL version number, not just the one in the KStars APP.
			# So this makes versions with those names as well so that KStars can find the libraries.
			# This is not necessarily the best idea, but it works.
			KF5_VERSION="5.90.0"
			
			if [[ ${fileName} == *dylib ]]
			then
				shortName=$(echo ${fileName} | sed 's/\..*$//' | sed 's/-.*//')
				longName=${shortName}.${KF5_VERSION}.dylib
				shortName=${shortName}.dylib
				if [[ ${fileName} != ${shortName} ]]
				then
					echo "Copying ${fileName} to ${shortName}"
					cp -f "${libDir}/${fileName}" "${libDir}/${shortName}"
					if [[ ${fileName} == libKF5* ]]
					then
						cp -f "${libDir}/${fileName}" "${libDir}/${longName}"
					fi
					if [[ ${fileName} == libstellarsolver* ]]
					then
						cp -f "${libDir}/${fileName}" "${libDir}/libstellarsolver.1.5.dylib"
					fi
					if [[ ${fileName} == libqt5keychain* ]]
					then
						cp -f "${libDir}/${fileName}" "${libDir}/libqt5keychain.0.9.1.dylib"
					fi
				else 
					echo "Skipping ${fileName} since it is already the simple name"
				fi
			fi
		
			#  If this is a directory it is one of the QT Frameworks bundled with KStars, and since it will cause issues to have 2 different Qt copies linked in the same project, we have to delete this one.
			#  And then link it to the other.  Unfortunately we can't just use this QT version since it has no header files.
			if [ -d "${file}" ]
			then
				if [[ ${fileName} == Qt* ]]
				then
					rm -r "${file}"
				fi
			fi
		done
	
		# This makes use of the functions above to relink the files in the lib directory
		display "Removing links to App Frameworks directory and linking to Qt Directory and lib directory instead."
		processDirectory "${DEV_ROOT}/lib"
	fi

# There are some files that are not included in KStars.app, but are needed to build INDI and KStars.
# This will install them from the archive folder in this repo.
	display "Copying any missing binary, include, lib, and share files into the Root DEV folder"

	if [ ! -d "${DEV_ROOT}/bin" ]
	then
		tar -xzf "${DIR}/archive/bin.zip" -C "${DEV_ROOT}"
		cp -fr "${sourceKStarsApp}/Contents/MacOS"/* "${DEV_ROOT}/bin/"
		processDirectory "${DEV_ROOT}/bin"
	fi

	if [ ! -d "${DEV_ROOT}/include" ]
	then
		tar -xzf "${DIR}/archive/include.zip" -C "${DEV_ROOT}" 
	fi

	if [ ! -d "${DEV_ROOT}/lib/libexec" ]
	then
		tar -xzf "${DIR}/archive/libexec.zip" -C "${DEV_ROOT}/lib" 
		processDirectory "${DEV_ROOT}/lib/libexec"
	fi

	if [ ! -d "${DEV_ROOT}/lib/cmake" ]
	then
		tar -xzf "${DIR}/archive/cmake.zip" -C "${DEV_ROOT}/lib" 
		processCMakeDirectory "${DEV_ROOT}/lib/cmake"
	fi
	
	#sed -i.bak 's|[$]{_IMPORT_PREFIX}|'$QT_PATH'|g' ${DEV_ROOT}/lib/cmake/Qt5Keychain/Qt5KeychainLibraryDepends.cmake

	#these are some library files that are not in the DMG, but are needed to allow it to compile
	if [ ! -f "${DEV_ROOT}/lib/libjpeg.a" ]
	then
		tar --strip-components=1 -xzf "${DIR}/archive/libs.zip" -C "${DEV_ROOT}/lib/"
		processDirectory "${DEV_ROOT}/lib"
	fi

	mkdir -p "${DEV_ROOT}/share/"

	if [ ! -d "${DEV_ROOT}/share/kf5" ]
	then
		tar -xzf "${DIR}/archive/share-kf5.zip" -C "${DEV_ROOT}/share" 
		ln -sf "${DEV_ROOT}/share/kf5" "${HOME}/Library/Application Support/kf5"
		sed -i.bak 's|/Users/rlancaste/AstroRoot/craft-root/share|'$DEV_ROOT'/share|g' ${DEV_ROOT}/share/kf5/kdoctools/customization/dtd/kdedbx45.dtd
		sed -i.bak 's|/Users/rlancaste/AstroRoot/craft-root/share|'$DEV_ROOT'/share|g' ${DEV_ROOT}/share/kf5/kdoctools/customization/kde-include-common.xsl
		sed -i.bak 's|/Users/rlancaste/AstroRoot/craft-root/share|'$DEV_ROOT'/share|g' ${DEV_ROOT}/share/kf5/kdoctools/customization/xsl/all-l10n.xml
	fi
	
	if [ ! -d "${DEV_ROOT}/share/xml" ]
	then
		tar -xzf "${DIR}/archive/share-xml.zip" -C "${DEV_ROOT}/share" 
	fi

	if [ ! -d "${DEV_ROOT}/share/ECM" ]
	then
		tar -xzf "${DIR}/archive/share-ECM.zip" -C "${DEV_ROOT}/share" 
	fi

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
			cmake -G Xcode -DCMAKE_BUILD_TYPE=Debug -DCMAKE_MACOSX_RPATH=1 -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 -DCMAKE_INSTALL_RPATH="${DEV_ROOT}/lib;${QT_PATH}/lib" -DCMAKE_INSTALL_PREFIX="${DEV_ROOT}" -DBUILD_TESTER=1 -DCMAKE_PREFIX_PATH="${PREFIX_PATH}" "${STELLAR_SRC_FOLDER}"
			xcodebuild -project StellarSolver.xcodeproj -alltargets -configuration Debug CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" OTHER_CODE_SIGN_FLAGS="--deep"
		else
			display "Building StellarSolver"
			cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_MACOSX_RPATH=1 -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 -DCMAKE_INSTALL_RPATH="${DEV_ROOT}/lib;${QT_PATH}/lib" -DCMAKE_INSTALL_PREFIX="${DEV_ROOT}" -DBUILD_TESTER=1 -DCMAKE_PREFIX_PATH="${PREFIX_PATH}" "${STELLAR_SRC_FOLDER}"
			make -j $(expr $(sysctl -n hw.ncpu) + 2)
			make install 
		fi
		
		ln -sf "${StellarApp}" "${TOP_FOLDER}/StellarSolverTester.app"
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
		
		# This will copy the source KStars app into the build directory and delete and/or replace any files necessary
		# It is very important that you build on top of an existing KStars app bundle since this script will not set up
		# all the ancillary files that KStars needs in the app bundle in order to run.
		if [ ! -d "${KStarsApp}" ]
		then
			cp -rf "${sourceKStarsApp}" "${KStarsApp}"
			reLinkAppBundle "${KStarsApp}"
		fi
		
		writeQTConf "${KStarsApp}"
		
		if [ -n "${BUILD_XCODE}" ]
		then
			display "Building KStars using XCode"
			cmake -G Xcode -DCMAKE_BUILD_TYPE=Debug -DCMAKE_MACOSX_RPATH=1 -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 -DCMAKE_INSTALL_RPATH="${DEV_ROOT}/lib;${QT_PATH}/lib" -DCMAKE_INSTALL_PREFIX="${DEV_ROOT}" -DCMAKE_PREFIX_PATH="${PREFIX_PATH}" "${KSTARS_SRC_FOLDER}"
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
				cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_DOC=OFF -DFETCH_TRANSLATIONS=ON -DKDE_L10N_AUTO_TRANSLATIONS=ON -DCMAKE_MACOSX_RPATH=1 -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 -DCMAKE_INSTALL_RPATH="${DEV_ROOT}/lib;${QT_PATH}/lib" -DCMAKE_INSTALL_PREFIX="${DEV_ROOT}" -DCMAKE_PREFIX_PATH="${PREFIX_PATH}" "${KSTARS_SRC_FOLDER}"
				make -j $(expr $(sysctl -n hw.ncpu) + 2)
				cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_DOC=OFF -DFETCH_TRANSLATIONS=OFF -DKDE_L10N_AUTO_TRANSLATIONS=ON -DCMAKE_MACOSX_RPATH=1 -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 -DCMAKE_INSTALL_RPATH="${DEV_ROOT}/lib;${QT_PATH}/lib" -DCMAKE_INSTALL_PREFIX="${DEV_ROOT}" -DCMAKE_PREFIX_PATH="${PREFIX_PATH}" "${KSTARS_SRC_FOLDER}"
				make -j $(expr $(sysctl -n hw.ncpu) + 2)
			else
				cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_DOC=OFF -DCMAKE_MACOSX_RPATH=1 -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 -DCMAKE_INSTALL_RPATH="${DEV_ROOT}/lib;${QT_PATH}/lib" -DCMAKE_INSTALL_PREFIX="${DEV_ROOT}" -DCMAKE_PREFIX_PATH="${PREFIX_PATH}" "${KSTARS_SRC_FOLDER}"
				cmake --build . --target kstars -- -j$(expr $(sysctl -n hw.ncpu) + 2)
			fi
			
			make install
		fi

		ln -sf "${KStarsApp}" "${TOP_FOLDER}/KStars.app"
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
		# This will copy the source INDIWebManagerApp app into the build directory and delete and/or replace any files necessary
		# It is very important that you build on top of an existing INDIWebManagerApp app bundle since this script will not set up
		# all the ancillary files that INDIWebManagerApp needs in the app bundle in order to run.
		if [ ! -d "${INDIWebManagerApp}" ]
		then
			cp -rf "${sourceINDIWebManagerApp}" "${INDIWebManagerApp}"
			reLinkAppBundle "${INDIWebManagerApp}"
		fi
		
		writeQTConf ${INDIWebManagerApp}
		
		if [ -n "${BUILD_XCODE}" ]
		then
			display "Building INDI Web Manager App using XCode"
			cmake -G Xcode -DCMAKE_BUILD_TYPE=Debug -DCMAKE_MACOSX_RPATH=1 -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 -DCMAKE_INSTALL_RPATH="${DEV_ROOT}/lib;${QT_PATH}/lib" -DCMAKE_INSTALL_PREFIX="${DEV_ROOT}" -DCMAKE_PREFIX_PATH="${PREFIX_PATH}" "${WEBMANAGER_SRC_FOLDER}"
			xcodebuild -project INDIWebManagerApp.xcodeproj -target "INDIWebManagerApp" -configuration Debug CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" OTHER_CODE_SIGN_FLAGS="--deep"
		else
			display "Building INDI Web Manager App"
			cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_MACOSX_RPATH=1 -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 -DCMAKE_INSTALL_RPATH="${DEV_ROOT}/lib;${QT_PATH}/lib" -DCMAKE_INSTALL_PREFIX="${DEV_ROOT}" -DCMAKE_PREFIX_PATH="${PREFIX_PATH}" "${WEBMANAGER_SRC_FOLDER}"
			make -j $(expr $(sysctl -n hw.ncpu) + 2)
		fi

		ln -sf "${INDIWebManagerApp}" "${TOP_FOLDER}/INDIWebManagerApp.app"
	fi

display "Script Execution Complete"
