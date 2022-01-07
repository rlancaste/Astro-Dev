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
		echo "\033]0;$*\007"
	}

# This gets the directory from which this script is running so it can access any files there such as other scripts or the archive files.
# It also uses that to get the top folder file name so that it can use that in the scripts.
# Beware of changing the path to the top folder, you will have to run the script again if you do so since it will break links.
	DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
	
	
# This sets important system paths that the script will need to execute.  Please verify these paths.

		# This is the path to QT, it needs to point to the QT root folder whether it is Homebrew, Craft, or Installed QT
	export QT_PATH="${HOME}/Qt/5.15.1/clang_64"
		# This is your path to the SDK on your system.  It will be used in the ASTRO-ROOT/lib/cmake folder files to find the SDK on your system for building.
	export SDK_PATH="/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX11.1.sdk"


# These are the Paths to the Applications that will be used as a basis for the build so that you don't have to run the craft script
# Please make sure these applications are installed if you want to build those programs and make sure the path is right.

		# This is the path to the KStars App bundle the script will copy to setup the lib folder and kstars build folder
	export sourceKStarsApp="/Applications/KStars.app"
		# This is the path to the (optional) INDI Web Manager App bundle the script will copy to setup the INDI Web Manager build folder
	export sourceINDIWebManagerApp="/Applications/INDIWebManagerApp.app"


# This sets the directory paths.  Note that these are customizable, but they do get set here automatically.
# Beware that none of them should have spaces in the file path.

		#This is the base path
	export TOP_FOLDER=$( cd "${DIR}/../" && pwd )
		# This is the enclosing folder for the source code of INDI, KStars, and INDI Web Manager
	export SRC_FOLDER="${TOP_FOLDER}/src"
		# This is the enclosing folder for the forked source code of INDI, KStars, and INDI Web Manager
	export FORKED_SRC_FOLDER="${TOP_FOLDER}/src-forked"
		# This is the enclosing folder for the build folders of INDI, KStars, and INDI Web Manager
	export BUILD_FOLDER="${TOP_FOLDER}/build"
		# This is the enclosing folder for the forked build folders of INDI, KStars, and INDI Web Manager
	export FORKED_BUILD_FOLDER="${TOP_FOLDER}/forked-build"
		# This is the enclosing folder for the xcode build folders of INDI, KStars, and INDI Web Manager
	export XCODE_BUILD_FOLDER="${TOP_FOLDER}/xcode-build"
		# This is the enclosing folder for the forked xcode build folders of INDI, KStars, and INDI Web Manager
	export FORKED_XCODE_BUILD_FOLDER="${TOP_FOLDER}/forked-xcode-build"
		# This is the root folder for "installing" the software to facilitate building
	export DEV_ROOT="${TOP_FOLDER}/ASTRO-ROOT"
	
	
#These paths should not need to be changed on most systems
		# This sets the path to GET TEXT which is needed for building some packages.  This assumes it is in homebrew, but if not, change it.
	export GETTEXT_PATH=$(brew --prefix gettext)
		# This is a list of paths that will be used by find_package to locate libraries when building
		# These paths are root directories that contain cmake files and dynamic libraries
	export PREFIX_PATH="${QT_PATH};${DEV_ROOT};${GETTEXT_PATH}"
		# This is a list of paths to binaries that will be needed for building and running.  They are added to the PATH variable.
	export PATH="${DEV_ROOT}/bin:${KStarsApp}/Contents/MacOS/astrometry/bin:${KStarsApp}/Contents/MacOS/xplanet/bin:${QT_PATH}/bin:${GETTEXT_PATH}/bin:$PATH"
	
	# pkgconfig is not needed, but can be found by adding it to the path.
	#PATH="$(brew --prefix pkgconfig)/bin:$PATH"

# These are the urls for the repositories that will be used for building
# The prefix https://github.com/ and the suffix .git is asssumed.

	 export INDI_REPO="https://github.com/indilib/indi.git"
	 export THIRDPARTY_REPO="https://github.com/indilib/indi-3rdparty.git"
	 export STELLARSOLVER_REPO="https://github.com/rlancaste/stellarsolver.git"
	 export KSTARS_REPO="git@invent.kde.org:education/kstars.git"
	 export WEBMANAGER_REPO="https://github.com/rlancaste/INDIWebManagerApp.git"
	 
# These are the urls for the forks of the repositories that you will be using for editing these repos
# To use this section:
#		1. Make sure the user name has been edited to match your github user name
#		2. Uncomment the one(s) for which you would like to make/use a forked repo to edit (remove the #)
#		3. Run the setup script again to build the forked version.
# If you want to later change back to the standard repo, just comment out that line with a # again and run the setup script again.
# You should not need to actually change these paths, just uncomment them, they should automatically get forked and used

	 export GIT_USERNAME="rlancaste" # be sure to edit this using your own github username.
	 export GITLAB_USERNAME="lancaster" # be sure to edit this using your own gitlab username.
	 #export FORKED_INDI_REPO="git@github.com:${GIT_USERNAME}/indi.git"
	 #export FORKED_THIRDPARTY_REPO="git@github.com:${GIT_USERNAME}/indi-3rdparty.git"
	 #export FORKED_STELLARSOLVER_REPO="git@github.com:${GIT_USERNAME}/stellarsolver.git"
	 #export FORKED_KSTARS_REPO="git@invent.kde.org:${GITLAB_USERNAME}/kstars.git"
	 #export FORKED_WEBMANAGER_REPO="git@github.com:${GIT_USERNAME}/INDIWebManagerApp.git"

# This sets the minimum OS X version you are compiling for
# Note that the current version of qt can no longer build for anything less than 10.12

	export QMAKE_MACOSX_DEPLOYMENT_TARGET=10.13
	export MACOSX_DEPLOYMENT_TARGET=10.13
	
# These are the build options, you can make parts not build by just commenting out the line with a #
	export BUILD_INDI="Yep"
	export BUILD_THIRDPARTY="Yep"
	export BUILD_STELLARSOLVER="Yep"
	export BUILD_KSTARS="Yep"
	#export BUILD_WEBMANAGER="Yep"
	
display "Environment Variables Set."

echo "DIR                      is [${DIR}]"
echo "QT_PATH                  is [${QT_PATH}]"
echo "SDK_PATH                 is [${SDK_PATH}]"
echo "TOP_FOLDER               is [${TOP_FOLDER}]"
echo "SRC_FOLDER               is [${SRC_FOLDER}]"
echo "FORKED_SRC_FOLDER        is [${FORKED_SRC_FOLDER}]"
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
