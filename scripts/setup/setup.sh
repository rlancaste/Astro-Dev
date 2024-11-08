#/bin/bash

#	KStars and INDI Related Astronomy Software Development Setup Scripts
#﻿   Copyright (C) 2024 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

# This gets the directory from which this script is running so it can access any files there such as other scripts or the archive files.
# It also uses that to get the top folder file name so that it can use that in the scripts.
	DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
	
#This function links a file or folder in the dev directory to one in the craft-root directory
	function craftLink
	{
		ln -s ${CRAFT_ROOT}/$1 ${DEV_ROOT}/$1
	}

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
			
# This checks if any of the path variables are blank, since if they are blank, it could start trying to do things in the / folder, which is not good
	if [[ -z ${DIR} || -z ${CRAFT_ROOT} || -z ${DEV_ROOT} ]]
	then
  		display "One or more critical directory variables is blank, please edit settings.sh."
  		exit 1
	fi
	
# This checks the most important variables to see if the paths exist.  If they don't, it terminates the script with a message.
	if [ ! -d "${CRAFT_ROOT}" ]
	then
		display "Craft Does Not Exist at the directory specified, please install Craft or edit settings.sh."
		exit 1
	fi
	
# This sets up the development root directory for "installation"
	mkdir -p "${DEV_ROOT}"
	
	craftLink bin
	craftLink doc
	craftLink include
	craftLink lib
	craftLink libexec
	craftLink plugins
	craftLink .//mkspecs
	craftLink qml
	craftLink share
	
# This provides a link for kdoctools to be found.
	ln -s "${CRAFT_ROOT}/share/kf6" "${HOME}/Library/Application Support/kf6"

# This following command will run the setup and build scripts for each of the packages.  You do not have do do this now, but it is good to get it all set up.
# You can always select certain ones to leave out if you edit the file listed below.
	source ${DIR}/../build/build-selectedPackages.sh


display "Script Execution Complete"
