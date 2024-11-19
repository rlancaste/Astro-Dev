#!/bin/bash

#	Astro-Dev Astronomy Software Development Build Scripts
# 	GSC.sh - A Script meant to build The Hubble Guide Star Catalog with the requested options.
#﻿  Copyright (C) 2024 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

# This gets the directory from which this script is running so it can access files or other scripts in the repo
	DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# This sets up and provides access to all of the methods required to run the script.
	source ${DIR}/build-engine.sh

# This section sets the options for building the package.
	export PACKAGE_NAME="Hubble Guide Star Catalog"
	export PACKAGE_SHORT_NAME="gsc"
	export BUILD_SUBDIR="gsc-build"
	export PACKAGE_BUILD_OPTIONS=""
	export PACKAGE_ARCHIVE="http://www.indilib.org/jdownloads/kstars/gsc-1.3.tar.gz"
	
# Display the Welcome message explaining what this script does.
	display "Setting up and Building the INDI Core Drivers."
	
# This method call will prepare the Source Directory to build the package
	prepareSourceDirectory
	
# This method call will build the package using either xcode or cmake based on your setting
	buildPackage
	
