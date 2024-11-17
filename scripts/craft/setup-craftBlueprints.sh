#!/bin/bash

#	KStars and INDI Related Astronomy Software Development Setup Scripts
#﻿   Copyright (C) 2024 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

# This gets the directory from which this script is running so it can access files or other scripts in the repo
	DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# This option must come before build-engine. It determines whether to use your own Forked Repository or the official one for building.
# If you want to use the Forked Repo, enter Yes, otherwise No.
	export USE_FORKED_REPO="Yes"

# This sets up and provides access to all of the methods required to run the script.
	source ${DIR}/../settings.sh

# This section sets the options for building the package.
	export PACKAGE_NAME="Craft BluePrints"
	export PACKAGE_SHORT_NAME="craft-blueprints-kde"

# Display the Welcome message explaining what this script does.
	display "Setting up Craft BluePrints"

# This automatically sets the repositories based on the package information above and your Username variables from settings.sh
# If any of these are wrong or the variables are wrong you should change this.
	export REPO="https://github.com/indilib/${PACKAGE_SHORT_NAME}.git"
	export FORKED_REPO="git@github.com:${GIT_USERNAME}/${PACKAGE_SHORT_NAME}.git"	
	export FORKED_REPO_HTML="https://github.com/${GIT_USERNAME}/${PACKAGE_SHORT_NAME}.git"
	
# This method call will prepare the Source Directory to build the package
	prepareSourceDirectory