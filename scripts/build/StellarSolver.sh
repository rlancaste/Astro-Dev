#!/bin/bash

#	Astro-Dev Astronomy Software Development Build Scripts
# 	StellarSolver.sh - A Script meant to build StellarSolver with the requested options.
#﻿  Copyright (C) 2024 Robert Lancaster <rlancaste@gmail.com>
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
	export PACKAGE_NAME="StellarSolver"
	export PACKAGE_SHORT_NAME="stellarsolver"
	export BUILD_SUBDIR="stellar-build"
	export PACKAGE_BUILD_OPTIONS="-DBUILD_TESTER=ON -DBUILD_DEMOS=OFF -DBUILD_BATCH_SOLVER=OFF"
	export HOMEBREW_DEPENDENCIES="gsl cfitsio zlib wcslib"
	export UBUNTU_DEPENDENCIES="git cmake libgl1-mesa-dev libcfitsio-dev libgsl-dev wcslib-dev"

# Display the Welcome message explaining what this script does.
	display "Setting up and Building StellarSolver with the Tester Application.  If you want to build the Batch Solver or Demos, please enable those options in StellarSolver.sh"

# This will dynamically set the QT5 or QT6 build option using the USE_QT5 variable in settings.sh
	if [ -n "${USE_QT5}" ]
	then
		export PACKAGE_BUILD_OPTIONS="-DUSE_QT5=ON ${PACKAGE_BUILD_OPTIONS}"
		export HOMEBREW_DEPENDENCIES="${HOMEBREW_DEPENDENCIES} qt5"
		export UBUNTU_DEPENDENCIES="${UBUNTU_DEPENDENCIES} qtbase5-dev"
	else
		export PACKAGE_BUILD_OPTIONS="-DUSE_QT5=OFF ${PACKAGE_BUILD_OPTIONS}"
		export HOMEBREW_DEPENDENCIES="${HOMEBREW_DEPENDENCIES} qt6"
		export UBUNTU_DEPENDENCIES="${UBUNTU_DEPENDENCIES} qt6-base-dev"
	fi

# This automatically sets the repositories based on the package information above and your Username variables from settings.sh
# If any of these are wrong or the variables are wrong you should change this.
	export REPO="https://github.com/rlancaste/${PACKAGE_SHORT_NAME}.git"
	export FORKED_REPO="git@github.com:${GIT_USERNAME}/${PACKAGE_SHORT_NAME}.git"	
	export FORKED_REPO_HTML="https://github.com/${GIT_USERNAME}/${PACKAGE_SHORT_NAME}.git"
	
# This command will install dependencies for the package.
# If you know the dependencies are already installed, you can skip this step by commenting it out with a #.
	installDependencies
	
# This method call will prepare the Source Directory to build the package
	prepareSourceDirectory
	
# This method call will build the package using either xcode or cmake based on your setting
	buildPackage