#/bin/bash

# This gets the directory from which this script is running so it can access any files there such as other scripts or the archive files.
# It also uses that to get the top folder file name so that it can use that in the scripts.
# Beware of changing the path to the top folder, you will have to run the script again if you do so since it will break links.
	DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
	TOP_FOLDER=$( cd "${DIR}/../" && pwd )

# This resets the script options to default values.
	REMOVE_ALL=""

# This function will display the message so it stands out in the Terminal both in the code and at the top.
	function display
	{
		# This will display the message in line in the commands.
		echo ""
		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
		echo "~ $*"
		echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
		echo ""
	
		# This will display the message in the title bar.
		echo "\033]0;SettingUpMacDevEnvForKStars-INDI-$*\a"
	}

# This function shortens the amount of code needed to clean the build directories if desired, make them if needed, and enter them
	function setupAndEnterBuildDir
	{
		if [ -d "$1" ]
		then
			if [ -n "$REMOVE_ALL" ]
			then
				rm -r "$1"/*
			fi
		else
			mkdir -p "$1"
		fi
		cd "$1"
	}

#This will print out how to use the script
	function usage
	{
		cat  <<- EOF
			options:
				-r Remove everything from the build directories and start fresh
		EOF
	}

#This function processes the user's options for running the script
	function processOptions
	{
		while getopts "r" option
		do
			case $option in
				r)
					REMOVE_ALL="Yep"
					;;
				*)
					dieUsage "Unsupported option $option"
					;;
			esac
		done
		shift $((${OPTIND} - 1))

		echo ""
		echo "REMOVE_ALL         = ${REMOVE_ALL:-Nope}"
	}

# This Function processes a given file using otool to see what files it is currently linked to.
# It adds RPATHS for the QT lib folder and the dev lib folder so that the files can be found when the local Frameworks folder and QT is deleted.
# If the file it is linking to is a Qt folder, it makes sure the link becomes an rpath so it can be found using the rpath.
# it uses install_name_tool to update those files
	function processTarget
	{
		target=$1
		
		install_name_tool -add_rpath "${DEV_ROOT}/lib" $target
		install_name_tool -add_rpath "${QT_PATH}/lib" $target
        	
		entries=$(otool -L $target | sed '1d' | awk '{print $1}')
		echo "Processing $target"

		for entry in $entries
		do
			baseEntry=$(echo ${entry} | sed 's/^.*Frameworks//' | sed 's/^.*@loader_path//')
			
			if [[ $baseEntry == /Qt* ]]
			then
			
				newname=""
				newname="@rpath${baseEntry}"
				echo "    change reference $entry -> $newname" 

				install_name_tool -change \
				$entry \
				$newname \
				$target
			fi
			
		done
		#echo ""
		#echo "   otool for $target after"
		#otool -L $target | awk '{printf("\t%s\n", $0)}'
	
	}

#This function will recursively process all the files in a directory and will use the processTarget function on them
	function processDirectory
	{
		directory=$1
		echo "Processing all of the files in $directory"
		for file in ${directory}/*
		do
			if [[ $file == *.dylib ]]
			then
    			base=$(basename ${file})
        		echo "Processing file ${base}"
        		processTarget ${file}
        	fi
        	if [ -d "$file" ]
        	then
        		processDirectory "${file}"
        	fi
		done
	}
	
	
	
	
	
########################################################################################
# This is where the main part of the script starts!
#

#Process the command line options to determine what to do.
	processOptions $@

	display "This will use an existing KStars App to setup a Development Environment for KStars and INDI on your Mac that does not depend on Craft or Homebrew.  It assumes the KStars app bundle is at /Applications/KStars.app.  It will place the development directory at the location specified.  It will use QT Located in your home directory.  Edit this script if that is incorrect."

# These are the script options.  You can change these if needed.
	SRC_FOLDER="${TOP_FOLDER}/src"
	BUILD_FOLDER="${TOP_FOLDER}/build"
	DEV_ROOT="${TOP_FOLDER}/ASTRO-ROOT"
	sourceKStarsApp="/Applications/KStars.app"
	KStarsApp="${BUILD_FOLDER}/kstars-build/kstars/KStars.app"
	QMAKE_MACOSX_DEPLOYMENT_TARGET=10.12
	MACOSX_DEPLOYMENT_TARGET=10.12
	QT_PATH="${HOME}/Qt/5.12.3/clang_64/"
	GETTEXT_PATH=$(brew --prefix gettext)
	PREFIX_PATH="${QT_PATH};${DEV_ROOT};${GETTEXT_PATH}"
	PATH="${DEV_ROOT}/bin:${KStarsApp}/Contents/MacOS/astrometry/bin:${QT_PATH}/bin:$PATH"
	
	# pkgconfig is not needed, but can be found by adding it to the path.
	#PATH="$(brew --prefix pkgconfig)/bin:$PATH"
	
# This checks the most important variables to see if the paths exist.  If they don't, it terminates the script with a message.
	if [ ! -d "${QT_PATH}" ]
	then
		display "QT Does Not Exist at the directory specified, please install QT or edit this script."
		exit
	fi
	
	if [ ! -d "${sourceKStarsApp}" ]
	then
		display "The source KStars app does not exist at the directory specified. This script relies on an existing KStars APP bundle in order to set up the development environment.  Please download KStars.app or edit this script."
		exit
	fi

# This will remove all the files in the ASTRO development root folder so it can start fresh.
	if [ -n "${REMOVE_ALL}" ]
	then
		if [ -d "${DEV_ROOT}" ]
		then
			rm -r "${DEV_ROOT}"
		fi
	fi

# This section will copy the dynamic libraries that KStars and INDI will need from an existing KStars.app bundle
	if [ ! -d "${DEV_ROOT}/lib" ]
	then
		display "Copying Dynamic Libraries from an existing KStars.app"
		mkdir -p "${DEV_ROOT}/lib"
		libDir="${DEV_ROOT}/lib"
		cp -fr "${sourceKStarsApp}/Contents/Frameworks"/* "${DEV_ROOT}/lib/"

		display "Making Simple Dynamics Library copies so find_package can find them."
		for file in "${libDir}"/*
		do
			fileName=$(basename ${file})
		
		
			# This will make copies of the dynamic libraries in the lib folder without version numbers
			# If the file is a kf5 library, it also seems to need the FULL version number, not just the one in the KStars APP.
			# So this makes versions with those names as well so that KStars can find the libraries.
			# This is not necessarily the best idea, but it works.
			if [[ ${fileName} == *dylib ]]
			then
				shortName=$(echo ${fileName} | sed 's/\..*$//' | sed 's/-.*//')
				longName=${shortName}.5.54.0.dylib
				shortName=${shortName}.dylib
				if [[ ${fileName} != ${shortName} ]]
				then
					echo "Copying ${fileName} to ${shortName}"
					cp -f "${libDir}/${fileName}" "${libDir}/${shortName}"
					if [[ ${fileName} == libKF5* ]]
					then
						cp -f "${libDir}/${fileName}" "${libDir}/${longName}"
					fi
				else 
					echo "Skipping ${fileName} since it is already the simple name"
				fi
			fi
		
			#  If this is a directory it is one of the QT Frameworks bundled with KStars, and since it will cause issues to have 2 different Qt copies linked in the same project, we have to delete this one.
			#  And then link it to the other.  Unfortunately we can't just use this QT version since it has no header files.
			if [ -d "${file}" ]
			then
				if [[ ${fileName} == Qt* ]]
				then
					rm -r "${file}"
				fi
			fi
		done
	
		# This makes use of the functions above to relink the files in the lib directory
		display "Removing links to App Frameworks directory and linking to Qt Directory and lib directory instead."
		processDirectory "${DEV_ROOT}/lib"
	fi

# There are some files that are not included in KStars.app, but are needed to build INDI and KStars.
# This will install them from the archive folder in this repo.
	display "Copying any missing binary, include, and share files into the Root DEV folder"

	if [ ! -d "${DEV_ROOT}/bin" ]
	then
		tar -xzf "${DIR}/archive/bin.zip" -C "${DEV_ROOT}" 
	fi

	if [ ! -d "${DEV_ROOT}/include" ]
	then
		tar -xzf "${DIR}/archive/include.zip" -C "${DEV_ROOT}" 
	fi

	if [ ! -d "${DEV_ROOT}/lib/libexec/kf5" ]
	then
		tar -xzf "${DIR}/archive/libexec-kf5.zip" -C "${DEV_ROOT}/lib" 
	fi

	if [ ! -d "${DEV_ROOT}/lib/cmake" ]
	then
		tar -xzf "${DIR}/archive/cmake.zip" -C "${DEV_ROOT}/lib" 
	fi

	if [ ! -f "${DEV_ROOT}/lib/libKF5KIOGui.5.54.0.dylib" ]
	then
		cp -f "${DIR}/archive/libKF5KIOGui.5.54.0.dylib" "${DEV_ROOT}/lib"
	fi

	mkdir -p "${DEV_ROOT}/share/"

	if [ ! -d "${DEV_ROOT}/share/kf5" ]
	then

		tar -xzf "${DIR}/archive/share-kf5.zip" -C "${DEV_ROOT}/share" 
	fi

	if [ ! -d "${DEV_ROOT}/share/ECM" ]
	then
		tar -xzf "${DIR}/archive/share-ECM.zip" -C "${DEV_ROOT}/share" 
	fi

# This is the start of the build section of the Script.

# This section will build INDI CORE
	if [ ! -d "${SRC_FOLDER}/indi" ]
	then
		display "Downloading INDI Core GIT repository"
		mkdir -p "${SRC_FOLDER}"
		cd "${SRC_FOLDER}"
		git clone https://github.com/indilib/indi.git 
	else
		display "Updating INDI Core GIT repository"
		cd "${SRC_FOLDER}/indi"
		git pull
	fi

	display "Building INDI Core Drivers"
	setupAndEnterBuildDir "${BUILD_FOLDER}/indi-build/indi-core"
	cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_MACOSX_RPATH=1 -DCMAKE_INSTALL_RPATH="${DEV_ROOT}/lib" -DCMAKE_INSTALL_PREFIX="${DEV_ROOT}" -DCMAKE_PREFIX_PATH="${PREFIX_PATH}" "${SRC_FOLDER}/indi"
	make -j $(expr $(sysctl -n hw.ncpu) + 2)
	make install

# This section will build INDI 3rd Party libraries and drivers.
	if [ ! -d "${SRC_FOLDER}/indi-3rdparty" ]
	then
		display "Downloading INDI 3rd Party GIT repository"
		cd "${SRC_FOLDER}"
		git clone https://github.com/indilib/indi-3rdparty.git
	else
		display "Updating INDI 3rd Party GIT repository"
		cd "${SRC_FOLDER}/indi-3rdparty"
		git pull
	fi

	display "Building INDI 3rd Party Libraries"
	setupAndEnterBuildDir "${BUILD_FOLDER}/indi-build/ThirdParty-Libraries"
	cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_MACOSX_RPATH=1 -DCMAKE_INSTALL_RPATH="${DEV_ROOT}/lib" -DCMAKE_INSTALL_PREFIX="${DEV_ROOT}" -DBUILD_LIBS=1 -DCMAKE_PREFIX_PATH="${PREFIX_PATH}" "${SRC_FOLDER}/indi-3rdParty"
	make -j $(expr $(sysctl -n hw.ncpu) + 2)
	make install 

	display "Building INDI 3rd Party Drivers"
	setupAndEnterBuildDir "${BUILD_FOLDER}/indi-build/ThirdParty-Drivers"
	cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_MACOSX_RPATH=1 -DCMAKE_INSTALL_RPATH="${DEV_ROOT}/lib" -DCMAKE_INSTALL_PREFIX="${DEV_ROOT}" -DCMAKE_PREFIX_PATH="${PREFIX_PATH}" "${SRC_FOLDER}/indi-3rdParty"
	make -j $(expr $(sysctl -n hw.ncpu) + 2)
	make install

# This section will build KStars
	if [ ! -d "${SRC_FOLDER}/kstars" ]
	then
		display "Downloading KStars GIT repository"
		cd "${SRC_FOLDER}"
		git clone https://github.com/KDE/kstars.git 
	else
		display "Updating KStars GIT repository"
		cd "${SRC_FOLDER}/kstars"
		git pull
	fi

	display "Setting Up KStars Build Directory"
	setupAndEnterBuildDir "${BUILD_FOLDER}/kstars-build"
	
	if [ -n "$REMOVE_ALL" ]
	then
		if [ -d "${KStarsApp}" ]
		then
			rm -r "${KStarsApp}"
		fi
	fi
	
	# This will copy the source KStars app into the build directory and delete and/or replace any files necessary
	# It is very important that you build on top of an existing KStars app bundle since this script will not set up
	# all the ancillary files that KStars needs in the app bundle in order to run.
	if [ ! -d "${KStarsApp}" ]
	then
		mkdir -p "${BUILD_FOLDER}/kstars-build/kstars/"
		cp -rf "${sourceKStarsApp}" "${KStarsApp}"
		rm -rf "${KStarsApp}/Contents/Frameworks"
		rm -r "${KStarsApp}/Contents/Resources/qml"
		rm "${KStarsApp}/Contents/Resources/qt.conf"
		rm -r "${KStarsApp}/Contents/Plugins"
		rm -r "${KStarsApp}/Contents/MacOS/indi"
		ln -sf "${DEV_ROOT}/bin" "${KStarsApp}/Contents/MacOS/indi"
		cp -f "${sourceKStarsApp}/Contents/MacOS/indi/gsc" "${DEV_ROOT}/bin"
		##################
		cat > "${KStarsApp}/Contents/Resources/qt.conf" <<- EOF
		[Paths]
		Prefix = ${QT_PATH}
		Plugins = plugIns
		Imports = qml
		Qml2Imports = qml
		EOF
		##################
		
		#This Directory needs to be processed because there are number of executables that will be looking in Frameworks for their libraries
		#This command will cause them to look to the lib directory and QT.
		processDirectory "${KStarsApp}/Contents/MacOS"
	fi

	display "Building KStars"
	cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_MACOSX_RPATH=1 -DCMAKE_INSTALL_RPATH="${DEV_ROOT}/lib" -DCMAKE_INSTALL_PREFIX="${DEV_ROOT}" -DCMAKE_PREFIX_PATH="${PREFIX_PATH}" "${SRC_FOLDER}/kstars"
	make -j $(expr $(sysctl -n hw.ncpu) + 2)

	ln -sf "${KStarsApp}" "${TOP_FOLDER}/KStars.app"


display "Script Execution Complete"
