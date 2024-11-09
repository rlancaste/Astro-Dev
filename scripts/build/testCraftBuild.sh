#/bin/bash

#	KDE Craft Testing Script for KStars and INDI Development
#﻿  Copyright (C) 2024 Robert Lancaster <rlancaste@gmail.com>
#	This script is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public
#	License as published by the Free Software Foundation; either
#	version 2 of the License, or (at your option) any later version.

# This gets the directory from which this script is running so it can access files or other scripts in the repo
	DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
	
	
VERBOSE=""
VERSION=""

# This will print out how to use the script
function usage
{

cat <<EOF
	options:
	    -h Display the options for the script
	    -r Remove everything and do a fresh install
	    -v Print out verbose output while building
	    -s Builds everything with the latest stable releases
	    -m Builds everything with the latest master releases
	    -q Craft is in quiet mode while building
EOF
}

# This function prints the usage information if the user enters an invalid option or no option at all and quits the program 
	function dieUsage
	{
		echo ""
		echo $*
		echo ""
		usage
		exit 9
	}

# This function processes the user's options for running the script
	function processOptions
	{
		while getopts "hvmsq" option
		do
			case $option in
				h)
					usage
					exit
					;;
				v)
					VERBOSE="v"
					;;
				q)
					VERBOSE="q"
					;;
				m)
					VERSION="master"
					;;
				s)
					VERSION="None"
					;;
				*)
					dieUsage "Unsupported option $option"
					;;
			esac
		done
		shift $((${OPTIND} - 1))

		echo ""
		echo "VERBOSE            = ${VERBOSE:-Nope}"
		echo "VERSION            = ${VERSION:-Nope}"
	}
	
	
########################################################################################
# This is where the main part of the script starts!
#

# Prepare to run the script by setting all of the environment variables	
# If you want to customize any of those variables, you can edit this file
	source ${DIR}/../settings.sh

# Display the Welcome message.
	display "This script will test KStars and INDI Builds in Craft.  You can test the latest master or the latest stable releases of packages important to KStars/INDI development.  You can also test your own recipes in the blueprints folder and packaging with craft."

# Process the command line options to determine what to do.
	processOptions $@

# This checks if any of the path variables are blank, since if they are blank, it could start trying to do things in the / folder, which is not good
	if [[ -z ${DIR} || -z ${TOP_FOLDER} || -z ${SRC_FOLDER} || -z ${FORKED_SRC_FOLDER} ]]
	then
  		display "One or more critical directory variables is blank, please edit build-env.sh."
  		exit 1
	fi
	
# This checks the most important variables to see if the paths exist.  If they don't, it terminates the script with a message.
	if [ ! -d "${CRAFT_ROOT}" ]
	then
		display "Craft Does Not Exist at the directory specified, please install Craft or edit this script."
		exit 1
	fi

# This sets the version of all the packages as desired if using the -s or -m option.  If these are not specified, it just uses the current settings in craft
	if [ -n "${VERSION}" ]
	then
		display "Setting the versions of the astronomy packages to $VERSION."
		craft --set version="$VERSION" indi
		craft --set version="$VERSION" indi-3rdparty-libs
		craft --set version="$VERSION" indi-3rdparty
		craft --set version="$VERSION" stellarsolver
		craft --set version="$VERSION" stellarsolvertester
		craft --set version="$VERSION" kstars 
	fi
	
	if [ -n "${BUILD_INDI}" ]
	then
		craft -i"$VERBOSE" indi
	fi
	
	if [ -n "${BUILD_THIRDPARTY}" ]
	then
		craft -i"$VERBOSE" indi-3rdparty-libs
		craft -i"$VERBOSE" indi-3rdparty
	fi
	
	if [ -n "${BUILD_STELLARSOLVER}" ]
	then
		craft -i"$VERBOSE" stellarsolver
	fi
	
	if [ -n "${BUILD_STELLARSOLVERTESTER}" ]
	then
		craft -i"$VERBOSE" stellarsolvertester
	fi
	
	if [ -n "${BUILD_KSTARS}" ]
	then
		craft -i"$VERBOSE" kstars
	fi


display "Script Execution Complete"
