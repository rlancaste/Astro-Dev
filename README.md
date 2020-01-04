# KStars-INDI-Mac-Dev
A Script to easily build INDI, INDI Web Manager, and KStars for Mac using existing app folder(s) and the latest sources.  This will get you the latest bleeding edge versions and will facilitate development.

# About the repository
This repository was written by myself, Rob Lancaster, for the purpose of making it easier for a person who is new to INDI, QT, KStars etc to get set up to easily build the latest versions of the software 
as well as to be able to edit the source code to test out ideas or to diagnose problems.  This script is not meant for distribution of any of these items.  For building the latest versions and distributing them as a DMG,
please see my other repository KSTars-on-OSX-Craft.  This script, unlike those in the other repository, does not attempt to build everything from scratch, but instead starts with already built APP bundles that 
have already been downloaded to your computer.  So it is very necessary that you download KStars.app first!  If you want to build or edit the INDI Web Manager App, you should download that one too, otherwise this script 
will skip that step.  So downloading KStars is required, but INDI Web Manager App is optional but recommended.  You will also need a version of QT, obtained from Homebrew, Craft, or installed using the official QT open source installer.
It is highly recommended that the version number of QT that you download should match the version that was originally used to build the app(s) you downloaded.  If the QT versions are different, there could be issues with functions 
not matching.

# Getting set up

1. Download and install KStars.app (if not done already)
2. (Optional) Download and install INDIWebManager.app (if not done already)
3. Download and install Qt 5.12 from whatever source (Homebrew, Craft, QT Installer, but version number should be close)
	Note: Be sure to install the QT Visualizations package with that.
4. Edit the script setup.sh to make sure all the variables are correct for your system.
5. Drag setup.sh to the OS X Terminal and run the script.
6. Now either use the programs, or get set up to edit the software.

# Using the newly built programs

At this point you have a currently up to date version of INDI, INDI-3rd Party, KStars, and (optionally) INDI Web Manager App in the Dev folder.
You can use these programs if you like, they should be fully functional and bleeding edge, 
but note that they are not portable, they rely on the files in the folders used to build these programs. This includes the QT version 
you linked it to, as well as the files in the ASTRO-ROOT directory.  So please don't delete these files, move the Dev folder to another location, or delete/replace QT.
If you do need to make a change like these, just re-run the setup script with the -r option and it will rebuild everything.  
If you want a truly portable app bundle, you will need to use the KSTars-on-OSX-Craft repository to do that.

# Editing and Making Changes to the software

One of the primary goals of this repository is to make it easy to make changes to the code.  You can use either XCode or QT Creator for this
purpose.  It is recommended that you use QT Creator because it has the ability to edit the UI files and it is designed for QT development,
but XCode has some very nice features, especially its code analysis algorithms.  For each program, you can use the repo folder in the src folder for your edits.
BUT, make sure that you use the already built build folder for KStars or INDI Web Manager App.  DO NOT make a new build folder, because the app bundles require 
a lot of other files that are ALREADY IN the build folder.  The setup script has already set that all up for you.  Just select the build folder in XCode or QT creator and you
are good to go.  NOTE:  more detailed instructions coming soon and maybe even some scripts for this.

# Submitting changes to the software

For INDI, INDI 3rd Party, or INDI Web Manger App, you need to make a fork of the repo, make your changes, commit them, and do a pull request.  I will put a script in here to automate some of that.
For KStars, you need to use phabricator.  I will put a script in here for that.