#!/bin/bash

#	KStars and INDI Related Astronomy Software Development Build Scripts
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

# The following commands call on the different scripts to build each package needed for INDI/KStars Development
# Comment out any of them you don't need to run by putting a # on the front of it.

	source ${SCRIPTS_DIR}/build/INDICore.sh
	source ${SCRIPTS_DIR}/build/INDI3rdParty.sh
	source ${SCRIPTS_DIR}/build/StellarSolver.sh
	source ${SCRIPTS_DIR}/build/KStars.sh
	source ${SCRIPTS_DIR}/build/INDIWebManagerApp.sh
	source ${SCRIPTS_DIR}/build/GSC.sh



