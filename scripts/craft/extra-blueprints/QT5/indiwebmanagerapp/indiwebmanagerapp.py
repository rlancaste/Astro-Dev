import info
from CraftCore import CraftCore
from Package.CMakePackageBase import CMakePackageBase

class subinfo(info.infoclass):
    def setTargets(self):
        self.description = 'A Graphical program to Manage, Configure, Launch, and Monitor an INDI WebManager on OS X and Linux'
        self.displayName = "INDI Web Manager App"
        self.svnTargets['master'] = "https://github.com/rlancaste/INDIWebManagerApp.git"
        self.defaultTarget = 'master'

    def setDependencies(self):
        self.runtimeDependencies["libs/qt/qtbase"] = None
        self.runtimeDependencies["libs/qt/qtwebsockets"] = None
        self.runtimeDependencies["kde/frameworks/tier2/kdoctools"] = None
        self.runtimeDependencies["kde/frameworks/tier1/kconfig"] = None
        self.runtimeDependencies["kde/frameworks/tier3/kio"] = None
        
        # MacOS and Linux build indi client/server, Windows builds indi client only
        self.runtimeDependencies["libs/indilib/indi"] = None
        self.runtimeDependencies["libs/indilib/indi-3rdparty"] = None
        self.runtimeDependencies["libs/indilib/indi-3rdparty-libs"] = None

from Package.CMakePackageBase import *

class Package(CMakePackageBase):
    def __init__(self):
        super().__init__()
