#!/bin/bash

#	Astro-Dev Astronomy Software Development Submit Changes scripts
#	CraftBlueprints.sh - A Script to submit changes to the KDE Craft BluePrints Repo
#﻿  Copyright (C) 2024 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

# This gets the directory from which this script is running so it can access files or other scripts in the repo
	DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Prepare to run the script by setting all of the environment variables	
	source "${DIR}/submit-engine.sh"

# This section sets the critical options for finding the repo and forked src folder.
	export PACKAGE_NAME="Craft BluePrints"
	export PACKAGE_SHORT_NAME="craft-blueprints-kde"
	export FORKED_REPO="git@invent.kde.org:${GITLAB_USERNAME}/craft-blueprints-kde.git"
	export FORKED_REPO_HTML="https://invent.kde.org/${GITLAB_USERNAME}/craft-blueprints-kde.git"

	
# Check to make sure that you are not in the master branch, and make a branch if needed.
# Then committing changes in the new branch or the current branch
# Then sending the changes to the server
	commitAndPushToServer
