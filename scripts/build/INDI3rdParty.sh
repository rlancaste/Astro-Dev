#!/bin/bash

#	Astro-Dev Astronomy Software Development Build Scripts
# 	INDI3rdParty.sh - A Script meant to build INDI 3rd Party Libraries and Drivers with the requested options.
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
	export PACKAGE_NAME="INDI 3rd Party Libraries"
	export PACKAGE_SHORT_NAME="indi-3rdparty"
	export CRAFT_PACKAGE="libs/indilib/indi-3rdparty"
	export BUILD_SUBDIR="indi-build/ThirdParty-Libraries"
	export PACKAGE_BUILD_OPTIONS="-DBUILD_LIBS=ON"
	#export PACKAGE_BUILD_OPTIONS="${PACKAGE_BUILD_OPTIONS} -DFIX_MACOS_LIBS=ON" # Uncomment this line to fix 3rd Party drivers with linking issues.
	export HOMEBREW_DEPENDENCIES="grep libdc1394 libgphoto2 libnova cfitsio curl libgphoto2 libftdi libdc1394 zeromq libraw libtiff fftw ffmpeg librtlsdr limesuite opencv"
	export UBUNTU_DEPENDENCIES="cmake git build-essential cdbs dkms fxload libdc1394-dev libgphoto2-dev libnova-dev libcfitsio-dev libcurl4-gnutls-dev libftdi-dev libftdi1-dev libzmq3-dev libraw-dev libtiff-dev" 
	export UBUNTU_DEPENDENCIES="${UBUNTU_DEPENDENCIES} libfftw3-dev ffmpeg libavcodec-dev libavdevice-dev libgps-dev libboost-regex-dev librtlsdr-dev liblimesuite-dev zlib1g-dev"
	
# Display the Welcome message explaining what this script does.
	display "This will build the INDI 3rd Party Libraries and Drivers."
	
# This automatically sets the repositories based on the package information above and your Username variables from settings.sh
# If any of these are wrong or the variables are wrong you should change this.
	export REPO="https://github.com/indilib/${PACKAGE_SHORT_NAME}.git"
	export FORKED_REPO="git@github.com:${GIT_USERNAME}/${PACKAGE_SHORT_NAME}.git"	
	export FORKED_REPO_HTML="https://github.com/${GIT_USERNAME}/${PACKAGE_SHORT_NAME}.git"

# This command will install dependencies for the package.
# If you know the dependencies are already installed, you can skip this step by commenting it out with a #.
	installDependencies

# This method call will prepare the Source Directory to build the package
	prepareSourceDirectory
	
# This method call will build the package using either xcode or cmake based on your setting
	buildPackage
	
# This section sets the options for building the package.  Note that for 3rd Party Drivers, there are only a few differences from the Libraries.
	export BUILD_SUBDIR="indi-build/ThirdParty-Drivers"
	export PACKAGE_NAME="INDI 3rd Party Drivers"
	export CRAFT_PACKAGE="libs/indilib/indi-3rdparty-libs"
	export PACKAGE_BUILD_OPTIONS=""
	
# This method call will build the package using either xcode or cmake based on your setting
	buildPackage
	