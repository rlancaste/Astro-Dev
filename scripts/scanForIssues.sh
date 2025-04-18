#!/bin/bash
#This script is meant to search for issues in the Craft bin and lib directories that could cause issues with packaging and/or running KStars

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
	source ${DIR}/settings.sh

#Files in these locations can be safely ignored.
	IGNORED_OTOOL_OUTPUT="/usr/lib/|/System/"

	# This fuction is meant to check for libraries that have the wrong architecture in CRAFT_ROOT, HOMEBREW_ROOT, or DEV_ROOT
	function checkForWrongArch
	{
		target=$1
		libArch=$(lipo -archs $target)
		#echo "Processing $target for wrong arch"
		
		if [[ "$libArch" != *"${BUILD_ARCH}"* ]]
		then
			echo "$target architecture ($libArch) does not include/match Build Arch (${BUILD_ARCH})"
		fi
	}

	# This fuction is meant to check for install name IDs that are not rpaths or full paths, since that causes linking problems later.
	function checkForBadID
	{
		target=$1
		itsID=$(otool -D $target | sed -n '2 p')
		#echo "Processing $target for bad install name ID"
		
		if [[ -L $itsID ]]
		then
			itsID=$(readlink -f $itsID)
		fi
		
		if [[ -L $target ]]
		then
			target=$(readlink -f $target)
		fi
		
		base=$(basename $target | cut -d. -f1)
		
		if [[ "$itsID" != @rpath/*$base* ]] && [[ "$itsID" != $target ]]
		then
			if [[ "$itsID" == "" ]] && [[ "$target" == *"Plugins"* ]]
			then
				echo "$target has no install ID, this is fine since it is just a plugin" > /dev/null
			elif [[ "$itsID" == "" ]] && [[ "$target" != *"Plugins"* ]]
			then
				echo "$target has no install ID"
			elif [[ "$itsID" == "/usr/local/opt/"* ]] && [[ "$target" == "/usr/local/"* ]]
			then
				echo "$target has install ID: $itsID, but this is ok in x86_64 Homebrew" > /dev/null
			elif [[ "$itsID" == "/opt/homebrew/opt/"* ]] && [[ "$target" == "/opt/homebrew/"* ]]
			then
				echo "$target has install ID: $itsID, but this is ok in arm64 Homebrew" > /dev/null
			else
				echo "$target ($base) has the wrong install ID: $itsID"
			fi
		fi
	}
	
	#This function is meant to check for links to homebrew programs or libraries.  
	#We want to link to craft libraries, not homebrew since homebrew doesn't build for distribution, so minimum macos version is newer than you want.
	function checkForHomebrewLinks
	{
		target=$1
        	
		entries=$(otool -L $target | sed '1d' | awk '{print $1}' | grep -E -v "$IGNORED_OTOOL_OUTPUT")
		#echo "Processing $target for homebrew links"
		
		for entry in $entries
		do
		#echo "$entry"
			if [[ "$entry" == "/usr/local/"* || "$entry" == "/opt/homebrew/"* ]]
			then
				echo "$target has a link to HomeBrew: $entry"
			fi
		done
	}
	
	#This function is intended to search for links that are not full paths, links to external folders, or not rpaths
	function checkForBadPaths
	{
		target=$1
        	
		entries=$(otool -L $target | sed '1d' | awk '{print $1}' | grep -E -v "$IGNORED_OTOOL_OUTPUT")
		#echo "Processing $target for bad paths"
		
		for entry in $entries
		do
		#echo "$entry"
			if [[ "$entry" != @rpath* ]] && [[ "$entry" != @executable_path* ]]  && [[ "$entry" != @loader_path* ]]
			then
				if [[ ! -f "${entry}" ]]
				then
					echo "$target has an invalid path: $entry"
				elif [[ "$entry" != "${CRAFT_ROOT}/"* ]] && [[ "$entry" != "${DEV_ROOT}/"* ]] && [[ "$entry" != "${HOMEBREW_ROOT}/"* ]]
				then
					echo "$target has a path outside craft, homebrew, or dev: $entry"
				fi
			fi
		done
	}
	
	#This function is intended to search for links that go to non-existant files
	function checkForBrokenLinks
	{
		target=$1

		entries=$(otool -L $target | sed '1d' | awk '{print $1}' | grep -E -v "$IGNORED_OTOOL_OUTPUT")
		#echo "Processing $target for broken links"

		for entry in $entries
		do
		#echo "$entry"
			if [[ "$entry" == @rpath* ]]
			then
				truePath=${CRAFT_ROOT}/lib/"${entry:7}"
				if [[ ! -f "${truePath}" ]]
				then
					echo "$target points to a file that doesn't exist: $entry points to: $truePath"
				fi
			fi
			
			if [[ "$entry" == @executable_path* ]]
			then
				truePath=${APP}/Contents/MacOS/"${entry:17}"
				if [[ ! -f "${truePath}" ]]
				then
					echo "$target points to a file that doesn't exist: $entry points to: $truePath"
				fi
			fi
			
			if [[ "$entry" == @loader_path* ]]
			then
				truePath=$(echo $target | awk -F $entry '{print $1}')/"${entry:13}"
				if [[ ! -f "${truePath}" ]]
				then
					echo "$target points to a file that doesn't exist: $entry points to: $truePath"
				fi
			fi


			if [[ "$entry" == /* ]]
			then
				if [[ ! -f "${entry}" ]]
				then
					echo "$target points to a file that doesn't exist: $entry"
				fi
			fi
		done
	}

	function processDirectory
	{
		directoryName=$1
		directory=$2
		#display "Processing all of the $directoryName files in $directory"
		for file in ${directory}/*
		do
    		base=$(basename $file)
    		
    		if [[ "$file" != *".dSYM" ]] && [[ "$file" != *".framework" ]]
    		then
				if [[ -f "$file" ]]
				then
					#echo "Processing $directoryName file $base"
					if [[ "$file" == *".dylib" ]]
					then
						checkForBadID $file
						checkForWrongArch $file
					fi
					
					if [[ "$file" != *".a" ]]
					then
						checkForBrokenLinks $file
						checkForBadPaths $file
					fi
					
					if [[ "$file" != *".a" ]] && [[ "$file" != "${HOMEBREW_ROOT}/"* ]]
					then
						checkForHomebrewLinks $file
					fi
					
				else
					if [[ -d $file && ! -L $file ]] # Don't process symbolic links to other directories
					then
						processDirectory $base $file
					fi
				fi
			fi
		done
	}
	
	
	
#########################################################################
#This is where the main part of the script starts!!
#

#This should stop the script so that it doesn't run if these paths are blank.
#That way it doesn't try to edit /Applications instead of ${CRAFT_ROOT}/Applications for example
	if [ -z "${DIR}" ] || [ -z  "${CRAFT_ROOT}" ] || [ -z  "${HOMEBREW_ROOT}" ]
	then
		echo "directory error! aborting Scan For Issues Scropt"
		exit 9
	fi

#This code makes sure the craft directory exists.  This won't work too well if it doesn't
	if [ ! -e ${DEV_ROOT} ]
	then
		"DEV directory does not exist."
		exit
	else
		display "Searching for issues in Homebrew lib folder"
		processDirectory lib "${HOMEBREW_ROOT}/lib"
		
		display "Searching for issues in Homebrew bin folder"
		processDirectory bin "${HOMEBREW_ROOT}/bin"
	fi

#This code makes sure the craft directory exists.  This won't work too well if it doesn't
	if [ ! -e ${DEV_ROOT} ]
	then
		"DEV directory does not exist."
		exit
	else
		display "Searching for issues in Dev Root Lib Directory and subfolders"
		processDirectory lib "${DEV_ROOT}/lib"
		
		display "Searching for issues in Dev Root Bin Directory"
		processDirectory bin "${DEV_ROOT}/bin"

	fi

#This code makes sure the craft directory exists.  This won't work too well if it doesn't
	if [ ! -e ${CRAFT_ROOT} ]
	then
		"Craft directory does not exist."
		exit
	else
		display "Searching for issues in CraftRoot Lib Directory and subfolders"
		processDirectory lib "${CRAFT_ROOT}/lib"
		
		display "Searching for issues in CraftRoot Bin Directory"
		processDirectory bin "${CRAFT_ROOT}/bin"
		
		display "Searching for issues in CraftRoot Plugins Directory"
		processDirectory plugins "${CRAFT_ROOT}/Plugins"
	fi



