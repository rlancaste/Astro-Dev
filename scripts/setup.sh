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

# This resets the script options to default values.
	REMOVE_ALL=""
	
# This function will download a git repo if needed, and will update it if not
# Note that this function should only be used on the real repo, not the forked one.  For that see the next function.
# $1 is the path of the Source folder that will be created when the clone is done
# $2 is the pretty name of the repository
# $3 is the git repository to be cloned
	function downloadOrUpdateRepository
	{
		mkdir -p "${SRC_FOLDER}"
		if [ ! -d "$1" ]
		then
			display "Downloading $2 GIT repository"
			cd "${SRC_FOLDER}"
			git clone https://github.com/"$3".git
		else
			display "Updating $2 GIT repository"
			cd "$1"
			git pull
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
		
		# This will download the fork if needed, or update it to the latest version if necessary
		mkdir -p "${FORKED_SRC_FOLDER}"
		if [ ! -d "$1" ]
		then
			display "The Forked Repo is not downloaded, checking if a $2 Fork is needed."
			# This will check to see if the repo already exists
			git ls-remote https://github.com/"$4".git -q >/dev/null 2>&1
			if [ $? -eq 0 ]
			then
				echo "The Forked Repo already exists, it can just get cloned."
			else
				echo "The $2 Repo has not been forked yet, attempting to do so now."
				# This will attempt to make a fork with your username, if one exists, it will not create another
				curl -u $GIT_USERNAME https://api.github.com/repos/$3/forks -d ''	
			fi
			
			# This will verify yet again if the repo exists.
			git ls-remote https://github.com/"$4".git -q >/dev/null 2>&1
			if [ ! $? -eq 0 ]
			then
				display "Error, the fork was not able to be created, you should do so manually and start the script again."
			fi
			
			display "Downloading $2 GIT repository"
			cd "${FORKED_SRC_FOLDER}"
			git clone https://github.com/"$4".git
		else
			display "Updating $2 GIT repository"
			cd "$1"
			git pull
		fi
		
		# This will attempt to update the fork to match the upstream master
		git fetch upstream
		git merge upstream/master
		git push
	}

# This function shortens the amount of code needed to clean the build directories if desired, make them if needed, and enter them
# $1 is the path to the build directory, $2 is the name of the package to be built
	function setupAndEnterBuildDir
	{
		display "Setting up and entering $2 build directory"
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
		rm "${App}/Contents/Resources/qt.conf"
		rm -r "${App}/Contents/Plugins"
		rm -r "${App}/Contents/MacOS/indi"
		ln -sf "${DEV_ROOT}/bin" "${App}/Contents/MacOS/indi"
		
		##################
		cat > "${App}/Contents/Resources/qt.conf" <<- EOF
		[Paths]
		Prefix = ${QT_PATH}
		Plugins = plugIns
		Imports = qml
		Qml2Imports = qml
		EOF
		##################
		
		#This Directory needs to be processed because there are number of executables that will be looking in Frameworks for their libraries
		#This command will cause them to look to the lib directory and QT.
		processDirectory "${App}/Contents/MacOS"
	}

#This will print out how to use the script
	function displayUsageAndExit
	{
		cat  <<- EOF
			script options:
				-h Display the help information
				-r Remove everything from the build directories and start fresh
		EOF
		exit
	}

#This function processes the user's options for running the script
	function processOptions
	{
		while getopts "rh" option
		do
			case $option in
				r)
					REMOVE_ALL="Yep"
					;;
				h)
					displayUsageAndExit
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
	}

# This Function processes a given file using otool to see what files it is currently linked to.
# It adds RPATHS for the QT lib folder and the dev lib folder so that the files can be found when the local Frameworks folder and QT is deleted.
# If the file it is linking to is a Qt folder, it makes sure the link becomes an rpath so it can be found using the rpath.
# it uses install_name_tool to update those files
	function processTarget
	{
		target=$1
		
		install_name_tool -add_rpath "${DEV_ROOT}/lib" $target
		install_name_tool -add_rpath "${QT_PATH}/lib" $target
        	
		entries=$(otool -L $target | sed '1d' | awk '{print $1}')
		#echo "Processing $target"

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

# This checks if any of the path variables are blank, since if they are blank, it could start trying to do things in the / folder, which is not good
	if [[ -z ${DIR} || -z ${TOP_FOLDER} || -z ${SRC_FOLDER} || -z ${FORKED_SRC_FOLDER} || -z ${INDI_SRC_FOLDER} || -z ${THIRDPARTY_SRC_FOLDER} || -z ${KSTARS_SRC_FOLDER} || -z ${WEBMANAGER_SRC_FOLDER} || -z ${BUILD_FOLDER} || -z ${DEV_ROOT} || -z ${sourceKStarsApp} || -z ${KStarsApp} || -z ${sourceINDIWebManagerApp} || -z ${INDIWebManagerApp} ]]
	then
  		display "One or more critical directory variables is blank, please edit this script."
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

# This will remove all the files in the ASTRO development root folder so it can start fresh.
	if [ -n "${REMOVE_ALL}" ]
	then
		if [ -d "${DEV_ROOT}" ]
		then
			rm -fr "${DEV_ROOT}"
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
			if [[ ${fileName} == *dylib ]]
			then
				shortName=$(echo ${fileName} | sed 's/\..*$//' | sed 's/-.*//')
				longName=${shortName}.5.54.0.dylib
				shortName=${shortName}.dylib
				if [[ ${fileName} != ${shortName} ]]
				then
					echo "Copying ${fileName} to ${shortName}"
					cp -f "${libDir}/${fileName}" "${libDir}/${shortName}"
					if [[ ${fileName} == libKF5* ]]
					then
						cp -f "${libDir}/${fileName}" "${libDir}/${longName}"
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
	display "Copying any missing binary, include, and share files into the Root DEV folder"

	if [ ! -d "${DEV_ROOT}/bin" ]
	then
		tar -xzf "${DIR}/archive/bin.zip" -C "${DEV_ROOT}"
		cp -fr "${sourceKStarsApp}/Contents/MacOS/indi"/* "${DEV_ROOT}/bin/"
		processDirectory "${DEV_ROOT}/bin"
	fi

	if [ ! -d "${DEV_ROOT}/include" ]
	then
		tar -xzf "${DIR}/archive/include.zip" -C "${DEV_ROOT}" 
	fi

	if [ ! -d "${DEV_ROOT}/lib/libexec/kf5" ]
	then
		tar -xzf "${DIR}/archive/libexec-kf5.zip" -C "${DEV_ROOT}/lib" 
	fi

	if [ ! -d "${DEV_ROOT}/lib/cmake" ]
	then
		tar -xzf "${DIR}/archive/cmake.zip" -C "${DEV_ROOT}/lib" 
	fi

	if [ ! -f "${DEV_ROOT}/lib/libKF5KIOGui.5.54.0.dylib" ]
	then
		# Note this file isn't even needed at all, we just need to put it in there because the build fails if it isn't present.
		cp -f "${DIR}/archive/libKF5KIOGui.5.54.0.dylib" "${DEV_ROOT}/lib"
	fi

	mkdir -p "${DEV_ROOT}/share/"

	if [ ! -d "${DEV_ROOT}/share/kf5" ]
	then

		tar -xzf "${DIR}/archive/share-kf5.zip" -C "${DEV_ROOT}/share" 
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
	
		setupAndEnterBuildDir "${BUILD_FOLDER}/indi-build/indi-core" "INDI Core"
	
		display "Building INDI Core Drivers"
		cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_MACOSX_RPATH=1 -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 -DCMAKE_INSTALL_RPATH="${DEV_ROOT}/lib" -DCMAKE_INSTALL_PREFIX="${DEV_ROOT}" -DCMAKE_PREFIX_PATH="${PREFIX_PATH}" "${INDI_SRC_FOLDER}"
		make -j $(expr $(sysctl -n hw.ncpu) + 2)
		make install
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
	
		setupAndEnterBuildDir "${BUILD_FOLDER}/indi-build/ThirdParty-Libraries"
	
		display "Building INDI 3rd Party Libraries"
		cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_MACOSX_RPATH=1 -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 -DCMAKE_INSTALL_RPATH="${DEV_ROOT}/lib" -DCMAKE_INSTALL_PREFIX="${DEV_ROOT}" -DBUILD_LIBS=1 -DCMAKE_PREFIX_PATH="${PREFIX_PATH}" "${THIRDPARTY_SRC_FOLDER}"
		make -j $(expr $(sysctl -n hw.ncpu) + 2)
		make install 
	
		setupAndEnterBuildDir "${BUILD_FOLDER}/indi-build/ThirdParty-Drivers"
	
		display "Building INDI 3rd Party Drivers"
		cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_MACOSX_RPATH=1 -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 -DCMAKE_INSTALL_RPATH="${DEV_ROOT}/lib" -DCMAKE_INSTALL_PREFIX="${DEV_ROOT}" -DCMAKE_PREFIX_PATH="${PREFIX_PATH}" "${THIRDPARTY_SRC_FOLDER}"
		make -j $(expr $(sysctl -n hw.ncpu) + 2)
		make install
	fi

# This section will build KStars

	if [ -n "${BUILD_KSTARS}" ]
	then
		downloadOrUpdateRepository "${KSTARS_SRC_FOLDER}" "KStars" "${KSTARS_REPO}"

		setupAndEnterBuildDir "${BUILD_FOLDER}/kstars-build" "KStars"
	
		# This will copy the source KStars app into the build directory and delete and/or replace any files necessary
		# It is very important that you build on top of an existing KStars app bundle since this script will not set up
		# all the ancillary files that KStars needs in the app bundle in order to run.
		if [ ! -d "${KStarsApp}" ]
		then
			mkdir -p "${BUILD_FOLDER}/kstars-build/kstars/"
			cp -rf "${sourceKStarsApp}" "${KStarsApp}"
			reLinkAppBundle "${KStarsApp}"
		fi

		display "Building KStars"
		cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_MACOSX_RPATH=1 -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 -DCMAKE_INSTALL_RPATH="${DEV_ROOT}/lib" -DCMAKE_INSTALL_PREFIX="${DEV_ROOT}" -DCMAKE_PREFIX_PATH="${PREFIX_PATH}" "${KSTARS_SRC_FOLDER}"
		make -j $(expr $(sysctl -n hw.ncpu) + 2)

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

		setupAndEnterBuildDir "${BUILD_FOLDER}/webmanager-build" "INDI Web Manager App"
	
		# This will copy the source INDIWebManagerApp app into the build directory and delete and/or replace any files necessary
		# It is very important that you build on top of an existing INDIWebManagerApp app bundle since this script will not set up
		# all the ancillary files that INDIWebManagerApp needs in the app bundle in order to run.
		if [ ! -d "${INDIWebManagerApp}" ]
		then
			mkdir -p "${BUILD_FOLDER}/webmanager-build/"
			cp -rf "${sourceINDIWebManagerApp}" "${INDIWebManagerApp}"
			reLinkAppBundle "${INDIWebManagerApp}"
		fi

		display "Building INDI Web Manager App"
		cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_MACOSX_RPATH=1 -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 -DCMAKE_INSTALL_RPATH="${DEV_ROOT}/lib" -DCMAKE_INSTALL_PREFIX="${DEV_ROOT}" -DCMAKE_PREFIX_PATH="${PREFIX_PATH}" "${WEBMANAGER_SRC_FOLDER}"
		make -j $(expr $(sysctl -n hw.ncpu) + 2)

		ln -sf "${INDIWebManagerApp}" "${TOP_FOLDER}/INDIWebManagerApp.app"
	fi

display "Script Execution Complete"
