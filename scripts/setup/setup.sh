#/bin/bash

#	KStars and INDI Related Astronomy Software Development Setup Scripts
#﻿   Copyright (C) 2024 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

# This gets the directory from which this script is running so it can access files or other scripts in the repo
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
	
# If using Craft as a building foundation, this checks if craft exists.  If it doesn't, it terminates the script with a message.
	if [[ "${BUILD_FOUNDATION}" == "CRAFT" ]]
	then
		if [ ! -d "${CRAFT_ROOT}" ]
		then
			display "Craft Does Not Exist at the directory specified, please install Craft or edit settings.sh."
			exit 1
		fi
	fi
	
# This sets up the development root directory for "installation"
	mkdir -p "${DEV_ROOT}"

# These links are needed on MacOS to successfully build outside of the main craft directories.
# We should look into why they are needed.
	if [[ "${OSTYPE}" == "darwin"* ]]
	then

		mkdir -p "${DEV_ROOT}/include"
		mkdir -p "${DEV_ROOT}/lib"
	
		# This one is for several packages that can't seem to find GSL
		craftLink include/gsl
		# These are several libraries that were actually found by KStars, but then did not link properly without being in DEV Root.
		craftLink lib/libcfitsio.dylib
		craftLink lib/libgsl.dylib
		craftLink lib/libgslcblas.dylib
		craftLink lib/libwcslib.a
		
		# These links were needed to successfully build for awhile, but I think I have got the settings right so they are not needed now.
		#craftLink bin
		#craftLink doc
		#craftLink lib
		#craftLink libexec
		#craftLink plugins
		#craftLink .//mkspecs
		#craftLink qml
		#craftLink share
	
	fi
	
# This provides a link for kdoctools to be found.
	ln -s "${CRAFT_ROOT}/share/kf6" "${HOME}/Library/Application Support/kf6"

# This following command will run the setup and build scripts for each of the packages.  You do not have do do this now, but it is good to get it all set up.
# You can always select certain ones to leave out if you edit the file listed below.
	source ${DIR}/../build/build-selectedPackages.sh


display "Script Execution Complete"
