#/bin/bash

#	KStars and INDI Related Astronomy Software Development Build Scripts
#﻿   Copyright (C) 2024 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

# This gets the directory from which this script is running so it can access any files there such as other scripts or the archive files.
# It also uses that to get the top folder file name so that it can use that in the scripts.
	DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# The following commands call on the different scripts to build each package needed for INDI/KStars Development
# Comment out any of them you don't need to run by putting a # on the front of it.

	source ${DIR}/INDICore.sh
	source ${DIR}/INDI3rdParty.sh
	source ${DIR}/StellarSolver.sh
	source ${DIR}/KStars.sh
	source ${DIR}/INDIWebManagaerApp.sh



