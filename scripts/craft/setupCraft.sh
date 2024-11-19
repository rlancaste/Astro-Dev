#!/bin/bash

#	KStars and INDI Related Astronomy Software Development Setup Scripts
#﻿  Copyright (C) 2024 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

# This gets the directory from which this script is running so it can access files or other scripts in the repo
	DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
	
# Prepare to run the script by setting all of the environment variables	and loading the functions
	source ${DIR}/../settings.sh

# This method sets up craft with desired options.
	setupCraft

# This sets the craft environment based on the settings.
	source "${CRAFT_ROOT}/craft/craftenv.sh"

# This sets up stellarsolvertester which will build all of its dependencies in craft as well
	craft -vi stellarsolvertester

# This sets up kstars which will build all of its dependencies in craft as well
	craft -vi kstars

display "Script execution complete"
read -p "Ending Script. Hit enter to exit." var 