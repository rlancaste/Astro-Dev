#!/bin/bash

#	KStars and INDI Related Astronomy Software Development Setup Scripts
#﻿   Copyright (C) 2024 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

# This gets the directory from which this script is running so it can access files or other scripts in the repo
	DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Prepare to run the script by setting all of the environment variables	
# If you want to customize any of those variables, you can edit this file
	source ${DIR}/settings.sh

# Display the Welcome message.
	display "This will setup a Development Environment for Astronomical Software related to KStars and INDI on your Computer.  This script runs all the setup and build scripts for all the packages.  On MacOS, it is based on Craft or Homebrew.  On Linux, it can be based on Craft or the system directories.  It will place the development directory at the location specified.  Edit settings.sh before running any scripts to configure your settings."

	read -p "Do you wish to continue? If so, type y. " runscript
	if [ "$runscript" != "y" ]
	then
		echo "Quitting the script as you requested."
		exit
	fi

# This following command will run the setup and build scripts for each of the packages.  You do not have do all of them, but it is good to get it all set up.
# Just comment out any that you don't need with a #
	source ${SCRIPTS_DIR}/build/INDICore.sh
	source ${SCRIPTS_DIR}/build/INDI3rdParty.sh
	source ${SCRIPTS_DIR}/build/StellarSolver.sh
	source ${SCRIPTS_DIR}/build/KStars.sh
	source ${SCRIPTS_DIR}/build/INDIWebManagerApp.sh
	source ${SCRIPTS_DIR}/build/GSC.sh
	source ${SCRIPTS_DIR}/craft/setup-craftBlueprints.sh

display "Script Execution Complete"
read -p "Ending Script. Hit enter to exit." var 
