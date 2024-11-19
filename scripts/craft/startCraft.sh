#!/bin/bash

#	Craft Startup Script
#﻿  Copyright (C) 2024 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

# This checks whether this script has been executed directly or run as a source script.
	if [[ ${BASH_SOURCE[0]} == ${0} ]]
	then
  		echo "In order to use this script to enter the craft environment in the terminal, you need to call it with the source command, not just execute the script. Please try again."
  		exit 1
	fi

# This gets the directory from which this script is running so it can access files or other scripts in the repo
	DIR=$( cd "$( dirname "${0}" )" && pwd )
	
# Prepare to run the script by setting all of the environment variables	
	source ${DIR}/../settings.sh

# This checks if any of the path variables are blank, since if they are blank, it could start trying to do things in the / folder, which is not good
	if [[ -z ${ASTRO_ROOT} || -z ${CRAFT_ROOT} ]]
	then
  		display "One or more critical directory variables is blank, please edit settings.sh."
  		exit 1
	fi

# This checks if craft exists.  If it doesn't, it terminates the script with a message.
	if [ ! -d "${CRAFT_ROOT}" ]
	then
		display "Craft Does Not Exist at the directory specified, please install Craft, run craftSetup.sh, or edit settings.sh."
		exit 1
	fi

# This sets the craft environment based on the settings.
	source "${CRAFT_ROOT}/craft/craftenv.sh"

# This enters the craft root directory so you can do whatever you need to in craft.
	cd "${CRAFT_ROOT}"