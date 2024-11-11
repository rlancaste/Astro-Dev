#/bin/bash

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
	source ${DIR}/../settings.sh

# Display the Welcome message.
	display "This will setup a Development Environment for Astronomical Software related to KStars and INDI on your Computer.  It is based on Craft, which must already be setup using the setupCraft script. It will place the development directory at the location specified.  Edit settings.sh before running any scripts to configure your settings."

	read -p "Do you wish to continue? If so, type y. " runscript
	if [ "$runscript" != "y" ]
	then
		echo "Quitting the script as you requested."
		exit
	fi

# This following command will run the setup and build scripts for each of the packages.  You do not have do do this now, but it is good to get it all set up.
# You can always select certain ones to leave out if you edit the file listed below.
# Uncomment the command below to install them, but comment it out to not do it.
	source ${DIR}/../build/build-selectedPackages.sh


display "Script Execution Complete"
