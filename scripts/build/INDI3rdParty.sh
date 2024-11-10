#/bin/bash

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
	export PACKAGE_NAME="INDI 3rd Party Libraries"
	export REPO="https://github.com/indilib/indi-3rdparty.git"
	export FORKED_REPO="git@github.com:${GIT_USERNAME}/indi-3rdparty.git"	
	export REPO_HTML_PAGE="https://github.com/${GIT_USERNAME}/indi-3rdparty.git"
	export SRC_SUBDIR="indi-3rdparty"
	export BUILD_SUBDIR="indi-build/ThirdParty-Libraries"
	export PACKAGE_BUILD_OPTIONS="-DBUILD_LIBS=ON"
	#export PACKAGE_BUILD_OPTIONS="${PACKAGE_BUILD_OPTIONS} -DFIX_MACOS_LIBS=ON" # Uncomment this line to fix 3rd Party drivers with linking issues.
	export XCODE_PROJECT_NAME="libindi-3rdparty"
	
# Display the Welcome message explaining what this script does.
	display "This will build the INDI 3rd Party Libraries and Drivers."

# This method call will prepare the Source Directory to build the package
	prepareSourceDirectory
	
# This method call will build the package using either xcode or cmake based on your setting
	buildPackage
	
# This section sets the options for building the package.  Note that for 3rd Party Drivers, there are only a few differences from the Libraries.
	export BUILD="${TOP_BUILD_FOLDER}/indi-build/ThirdParty-Drivers"
	export PACKAGE_NAME="INDI 3rd Party Drivers"
	export PACKAGE_BUILD_OPTIONS=""
	
# This method call will build the package using either xcode or cmake based on your setting
	buildPackage
	