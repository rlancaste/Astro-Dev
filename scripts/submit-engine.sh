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

# This sets the script with the Build environment variables.
	source ${DIR}/build-env.sh
	
# This function checks to see if a connection to a website exists.
	function checkForConnection
	{
		testCommand=$(curl -Is $1 | head -n 1)
		if [[ "${testCommand}" == *"OK"* || "${testCommand}" == *"Moved"* || "${testCommand}" == *"HTTP/2 301"* || "${testCommand}" == *"HTTP/2 200"* ]]
  		then 
  			echo "$1 connection was found."
  		else
  			echo "The Online Repository was not found at $1. You can't submit changes if you cannot connect."
  			exit
		fi
	}

# Check to make sure that you are not in the master branch, and make a branch if needed.
# Then committing changes in the new branch or the current branch
# Then sending the changes to the server
	function commitAndPushToServer
	{
		# Check to see that the user has actually already make a forked source folder for INDI Web Manager App
		if [ ! -d "${SRC}" ]
		then
			echo "No forked repo detected at ${SRC}.  Please make sure to fork the repo, edit the code, and make changes to submit.  Make sure the settings are right for the location of the SRC folder."
			exit
		fi
		cd "${SRC}"
		branch=$(git rev-parse --abbrev-ref HEAD)
		echo "You are on branch ${branch}"
		read -p "Do you want to switch to another branch before committing? Type y for yes." switch
		if [[ "$branch" == "master" && "$switch" != "y" ]]
		then
			echo "You should not commit or submit your changes to the master branch.  This script will not do that. Make another branch for changes to submit."
			read -p "Hit [Enter] to end the script now." closing
			exit
		elif [[ "$switch" == "y" ]]
		then
			read -p "What do you want your new branch to be called?" newBranch
			git checkout -b "${newBranch}"
			read -p "Please type a message for your commit: " commitMsg
			git commit -am "${commitMsg}"
			git push -u origin "${newBranch}"
		else
			read -p "Please type a message for your commit: " commitMsg
			git commit -am "${commitMsg}"
			git push -u origin "$branch"
		fi
	}
