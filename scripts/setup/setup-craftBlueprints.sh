#/bin/bash

#	KStars and INDI Development Setup Script
#﻿   Copyright (C) 2024 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

# This gets the directory from which this script is running so it can access any files there such as other scripts or the archive files.
# It also uses that to get the top folder file name so that it can use that in the scripts.
# Beware of changing the path to the top folder, you will have to run the script again if you do so since it will break links.
	DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# This option must come before build-engine. It determines whether to use your own Forked Repository or the official one for building.
# If you want to use the Forked Repo, enter Yes, otherwise No.
	export USE_FORKED_REPO="Yes"

# This sets up and provides access to all of the methods required to run the script.
	source ${DIR}/../build/build-engine.sh

# This section sets the options for building the package.
	export REPO="https://invent.kde.org/packaging/craft-blueprints-kde.git"
	export FORKED_REPO="git@invent.kde.org:${GITLAB_USERNAME}/craft-blueprints-kde.git"
	export REPO_HTML_PAGE="https://invent.kde.org/${GITLAB_USERNAME}/craft-blueprints-kde.git"
	export SRC="${TOP_SRC_FOLDER}/craft-blueprints-kde"
	export PACKAGE_NAME="Craft BluePrints"

# Display the Welcome message explaining what this script does.
	display "Setting up Craft BluePrints"
	
# This method call will prepare the Source Directory to build the package
	prepareSourceDirectory