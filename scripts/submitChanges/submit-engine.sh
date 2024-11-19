#!/bin/bash

#	Astro-Dev Astronomy Software Development Submit Changes Script Engine
#   submit-engine.sh - A script of functions used by the other submit changes scripts.
#﻿  Copyright (C) 2024 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

# This script is a script of functions that are used by the other scripts.  If you run this script by itself, nothing should happen.

# This gets the directory from which this script is running so it can access files or other scripts in the repo.
	DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# This sets the script with the Build environment variables.
	source ${DIR}/../settings.sh

# Check to make sure that you are not in the master branch, and make a branch if needed.
# Then committing changes in the new branch or the current branch
# Then sending the changes to the server
	function commitAndPushToServer
	{
	
		# This checks to make sure all variables used in this method have values, since it might be bad if they do not.
			if [[ -z ${PACKAGE_NAME} || -z ${FORKED_REPO_HTML} || -z ${PACKAGE_SHORT_NAME} ]]
			then
				display "Error. One or more critical variables is blank before running commitAndPushToServer."
				exit 1
			fi
			
		# This sets the source directory that will be used for the submission.
			export USE_FORKED_REPO="Yep"
			selectSourceDir

		# This checks to see if the remote server is accessible.
			checkForConnection "${PACKAGE_NAME}" "${FORKED_REPO_HTML}"
		
		# Display the message explaining what this script does.
			display "This script will submit your ${PACKAGE_NAME} changes in the forked-src folder to your fork on GITHub or GITLab.  You must have made changes in the forked-src folder for this to work."
		
		# This checks to make sure all variables used in this method have values, since it might be bad if they do not.
			if [ -z ${SRC_DIR} ]
			then
				display "The source directory is not set before using it in commitAndPushToServer."
				exit 1
			fi
			
		# Check to see that the user has actually already make a forked source folder for this package.
			if [ ! -d "${SRC_DIR}" ]
			then
				echo "No forked repo detected at ${SRC_DIR}.  Please make sure to fork the repo, edit the code, and make changes to submit.  Make sure the settings are right for the location of the SRC subdirectory folder."
				exit
			fi
			
		# This enters the source directory.
			cd "${SRC_DIR}"
			
		# This checks the current branch to make sure you are committing to a branch instead of master (a mistake I often made myself).
		# You can specify a name for a branch to switch to and it will switch to that branch.
		# Then after you switch branches, it commits your changes to that branch with your desired commit message, and finally pushes it to the server.
			branch=$(git rev-parse --abbrev-ref HEAD)
			echo "You are on branch ${branch}"
			read -p "Do you want to switch to another branch before committing? Type y for yes. " switch
			if [[ "$branch" == "master" && "$switch" != "y" ]]
			then
				echo "You should not commit or submit your changes to the master branch.  This script will not do that. Make another branch for changes to submit."
				read -p "Hit [Enter] to end the script now." closing
				exit
			elif [[ "$switch" == "y" ]]
			then
				read -p "What do you want your new branch to be called? " newBranch
				git checkout -b "${newBranch}"
				echo "Please type a message for your commit. Note that no quotes are required."
				read -p "Your commit message: " commitMsg
				git commit -am "${commitMsg}"
				git push -u origin "${newBranch}"
			else
				echo "Please type a message for your commit. Note that no quotes are required."
				read -p "Your commit message: " commitMsg
				git commit -am "${commitMsg}"
				git push -u origin "$branch"
			fi
			
		# This will switch back to the master branch if desired so that you can keep up with the current master branch and make more changes after your pull/merge request is accepted.
			read -p "Do you want to switch back to the master branch? Type y for yes. " switchBack
			if [[ "$switchBack" == "y" ]]
			then
				git checkout "master"
			fi
		
		# Display the final message
			display "Please go to ${FORKED_REPO_HTML} and click the submit pull request button if you are ready to make your pull request, or make other changes and other commits first."

	}
