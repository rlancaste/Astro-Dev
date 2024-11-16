#!/bin/bash

#	KStars and INDI Related Astronomy Software Development Build Scripts
#﻿   Copyright (C) 2024 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

# This gets the directory from which this script is running so it can access files or other scripts in the repo
	DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# This sets up and provides access to all of the methods required to run the script.
	source ${DIR}/build-engine.sh
	
# If you want to use the Forked Repo for this package, uncomment the following option by removing the #.
# If you have not forked this package yet, or would prefer to use the original repo, comment it out with a #.
	#export USE_FORKED_REPO="Yep"

# This section sets the options for building the package.
	export PACKAGE_NAME="INDI Web Manager App"
	export PACKAGE_SHORT_NAME="indiwebmanagerapp"
	export BUILD_SUBDIR="webmanager-build"
	export PACKAGE_BUILD_OPTIONS=""
	export HOMEBREW_DEPENDENCIES="qt6 extra-cmake-modules"

# Display the Welcome message explaining what this script does.
	display "Setting up and Building INDI Web Manager App."

# This will dynamically set the QT5 or QT6 build option using the USE_QT5 variable in settings.sh
	if [ -n "${USE_QT5}" ]
	then
		export PACKAGE_BUILD_OPTIONS="-DUSE_QT5=ON ${PACKAGE_BUILD_OPTIONS}"
	else
		export PACKAGE_BUILD_OPTIONS="-DUSE_QT5=OFF ${PACKAGE_BUILD_OPTIONS}"
	fi

# This automatically sets the repositories based on the package information above and your Username variables from settings.sh
# If any of these are wrong or the variables are wrong you should change this.
	export REPO="https://github.com/indilib/${PACKAGE_SHORT_NAME}.git"
	export FORKED_REPO="git@github.com:${GIT_USERNAME}/${PACKAGE_SHORT_NAME}.git"	
	export FORKED_REPO_HTML="https://github.com/${GIT_USERNAME}/${PACKAGE_SHORT_NAME}.git"

# This command will install dependencies for the package.
# If you know the dependencies are already installed, you can skip this step by commenting it out with a #.
	installDependencies
	if [[ "${BUILD_FOUNDATION}" != "CRAFT" && "${OSTYPE}" == "darwin"* ]]
	then	    
		echo "A list of kf6 packages are needed, but are not currently available to my knowledge in homebrew.  Please use Craft for INDIWebManagerApp in QT6 on macos"
		exit 1
	fi
	
# This method call will prepare the Source Directory to build the package
	prepareSourceDirectory
	
# This method call will build the package using either xcode or cmake based on your setting
	buildPackage
	
# This makes a nice link for launching the Application from the top folder on MacOS.
	if [[ "${OSTYPE}" == "darwin"* ]]
	then
		ln -sf "${DEV_ROOT}/INDIWebManagerApp.app" "${ASTRO_ROOT}/INDIWebManagerApp.app"
	fi