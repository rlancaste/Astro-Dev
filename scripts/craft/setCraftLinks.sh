#!/bin/bash

#	Astro-Dev Astronomy Software Development Craft Setup Scripts
#	setupCraft.sh - A script meant to get Craft all set up with the current options.
#﻿  Copyright (C) 2024 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

# This gets the directory from which this script is running so it can access files or other scripts in the repo
	DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
	
# Prepare to run the script by setting all of the environment variables	and loading the functions
	source ${DIR}/../settings.sh

# Display the Welcome message.
	display "This script links the craft git download folders to the src folders in your AstroRoot folder and the craft blueprints to the craft blueprints src folder.  This way you can test changes in your own repos and craft will build using them."

	read -p "Do you wish to continue? If so, type y. " runscript
	if [ "$runscript" != "y" ]
	then
		echo "Quitting the script as you requested."
		exit
	fi

	#export USE_FORKED_REPO="Yep"
	craftLinkSrcDir "indi" "libs/indilib/indi"
	
	#export USE_FORKED_REPO="Yep"
	craftLinkSrcDir "indi-3rdparty" "libs/indilib/indi-3rdparty"
	craftLinkSrcDir "indi-3rdparty" "libs/indilib/indi-3rdparty-libs"
	
	#export USE_FORKED_REPO="Yep"
	craftLinkSrcDir "stellarsolver" "libs/stellarsolver"
	craftLinkSrcDir "stellarsolver" "libs/stellarsolvertester"
	craftLinkSrcDir "stellarsolver" "libs/stellarbatchsolver"
	
	#export USE_FORKED_REPO="Yep"
	craftLinkSrcDir "kstars" "kde/applications/kstars"
	
	linkCraftBlueprints
	
	#restoreCraftBlueprints