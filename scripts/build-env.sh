#!/bin/bash

#	Build Environment setup script
#﻿   Copyright (C) 2019 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

# This function will display the message so it stands out in the Terminal both in the code and at the top.
	function display
	{
		# This will display the message in line in the commands.
		echo ""
		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
		echo "~ $*"
		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
		echo ""
	
		# This will display the message in the title bar.
		echo "\033]0;SettingUpMacDevEnvForKStars-INDI-$*\a"
	}

# This gets the directory from which this script is running so it can access any files there such as other scripts or the archive files.
# It also uses that to get the top folder file name so that it can use that in the scripts.
# Beware of changing the path to the top folder, you will have to run the script again if you do so since it will break links.
	DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
	

# This sets the directory paths.  Note that these are customizable.
# Beware that none of them should have spaces in the file path.
		#This is the base path
	export TOP_FOLDER=$( cd "${DIR}/../" && pwd )
		# This is the enclosing folder for the source code of INDI, KStars, and INDI Web Manager
	export SRC_FOLDER="${TOP_FOLDER}/src"
		# This is the enclosing folder for the build folders of INDI, KStars, and INDI Web Manager
	export BUILD_FOLDER="${TOP_FOLDER}/build"
		# This is the root folder for "installing" the software to facilitate building
	export DEV_ROOT="${TOP_FOLDER}/ASTRO-ROOT"
		# This is the path to the KStars App bundle the script will copy to setup the lib folder and kstars build folder
	export sourceKStarsApp="/Applications/KStars.app"
		# This the path to the KStars App bundle the script will be building inside of.
	export KStarsApp="${BUILD_FOLDER}/kstars-build/kstars/KStars.app"
		# This is the path to the INDI Web Manager App bundle the script will copy to setup the INDI Web Manager build folder
	export sourceINDIWebManagerApp="/Applications/INDIWebManagerApp.app"
		# This the path to the  INDI Web Manager App bundle the script will be building inside of.
	export INDIWebManagerApp="${BUILD_FOLDER}/webmanager-build/INDIWebManagerApp.app"
		# This is the path to QT, it needs to point to the QT root folder whether it is Homebrew, Craft, or Installed QT
	export QT_PATH="${HOME}/Qt/5.12.3/clang_64"
		# This sets the path to GET TEXT which is needed for building some packages.  This assumes it is in homebrew, but if not, change it.
	export GETTEXT_PATH=$(brew --prefix gettext)
		# This is a list of paths that will be used by find_package to locate libraries when building
		# These paths are root directories that contain cmake files and dynamic libraries
	export PREFIX_PATH="${QT_PATH};${DEV_ROOT};${GETTEXT_PATH}"
		# This is a list of paths to binaries that will be needed for building and running.  They are added to the PATH variable.
	export PATH="${DEV_ROOT}/bin:${KStarsApp}/Contents/MacOS/astrometry/bin:${QT_PATH}/bin:$PATH"
	
	# pkgconfig is not needed, but can be found by adding it to the path.
	#PATH="$(brew --prefix pkgconfig)/bin:$PATH"

# This sets the minimum OS X version you are compiling for
# Note that the current version of qt can no longer build for anything less than 10.12
	export QMAKE_MACOSX_DEPLOYMENT_TARGET=10.12
	export MACOSX_DEPLOYMENT_TARGET=10.12
	
display "Environment Variables Set."

echo "DIR                      is [${DIR}]"
echo "TOP_FOLDER               is [${TOP_FOLDER}]"
echo "SRC_FOLDER               is [${SRC_FOLDER}]"
echo "BUILD_FOLDER             is [${BUILD_FOLDER}]"
echo "DEV_ROOT                 is [${DEV_ROOT}]"
echo "sourceKStarsApp          is [${sourceKStarsApp}]"
echo "KStarsApp                is [${KStarsApp}]"
echo "sourceINDIWebManagerApp  is [${sourceINDIWebManagerApp}]"
echo "INDIWebManagerApp        is [${INDIWebManagerApp}]"
echo "QT_PATH                  is [${QT_PATH}]"
echo "GETTEXT_PATH             is [${GETTEXT_PATH}]"

echo "PREFIX_PATH              is [${PREFIX_PATH}]"
echo "PATH                     is [${PATH}]"

echo "OSX Deployment target    is [${QMAKE_MACOSX_DEPLOYMENT_TARGET}]"
