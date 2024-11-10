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
	export USE_FORKED_REPO="Yep"

# This section sets the options for building the package.
	export PACKAGE_NAME="KStars"
	export REPO="https://github.com/KDE/kstars.git"
	export FORKED_REPO="git@invent.kde.org:${GITLAB_USERNAME}/kstars.git"
	export FORKED_REPO_HTML="https://invent.kde.org/${GITLAB_USERNAME}/kstars.git"
	export SRC_SUBDIR="kstars"
	export BUILD_SUBDIR="kstars-build"
	export XCODE_PROJECT_NAME="kstars"
	export PACKAGE_BUILD_OPTIONS="-DBUILD_QT5=OFF -DBUILD_TESTING=OFF -DBUILD_DOC=OFF"

# Display the Welcome message explaining what this script does.
	display "Setting up and Building KStars."
	
# This method call will prepare the Source Directory to build the package
	prepareSourceDirectory
	
# This method call will build the package using either xcode or cmake based on your setting
	buildPackage
	
# This makes a nice link for launching the Application from the top folder on MacOS.
	if [[ "${OSTYPE}" == "darwin"* ]]
	then
		ln -sf "${DEV_ROOT}/KStars.app" "${TOP_FOLDER}/KStars.app"
	fi