#/bin/bash

#	KStars and INDI Related Astronomy Software Development Build Scripts
#﻿   Copyright (C) 2024 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

# This gets the directory from which this script is running so it can access any files there such as other scripts or the archive files.
# It also uses that to get the top folder file name so that it can use that in the scripts.
	DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# This option must come before build-engine. It determines whether to use your own Forked Repository or the official one for building.
# If you want to use the Forked Repo, enter Yes, otherwise No.
	export USE_FORKED_REPO="Yes"

# This sets up and provides access to all of the methods required to run the script.
	source ${DIR}/build-engine.sh

# This section sets the options for building the package.
	export REPO="https://github.com/rlancaste/stellarsolver.git"
	export FORKED_REPO="git@github.com:${GIT_USERNAME}/stellarsolver.git"
	export REPO_HTML_PAGE="https://github.com/${GIT_USERNAME}/stellarsolver.git"
	export SRC="${TOP_SRC_FOLDER}/stellarsolver"
	export BUILD="${TOP_BUILD_FOLDER}/stellar-build"
	export PACKAGE_NAME="StellarSolver"
	export XCODE_PROJECT_NAME="StellarSolver"
	export PACKAGE_BUILD_OPTIONS="-DBUILD_TESTER=ON -DBUILD_DEMOS=OFF -DBUILD_BATCH_SOLVER=OFF -DUSE_QT5=OFF"

# Display the Welcome message explaining what this script does.
	display "Setting up and Building StellarSolver."
	
# This method call will prepare the Source Directory to build the package
	prepareSourceDirectory
	
# This method call will build the package using either xcode or cmake based on your setting
	buildPackage
	
# This makes a nice link for launching the Tester Application from the top folder on MacOS.
	if [[ "${OSTYPE}" == "darwin"* ]]
	then	
		ln -sf "${DEV_ROOT}/StellarSolverTester.app" "${TOP_FOLDER}/StellarSolverTester.app"
	fi