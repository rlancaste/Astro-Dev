import info
from CraftCore import CraftCore
from Package.CMakePackageBase import CMakePackageBase

class subinfo(info.infoclass):
    def setTargets(self):
        self.description = "PHD2 Open PHD Guiding"
        self.svnTargets["master"] = "https://github.com/OpenPHDGuiding/phd2.git"
        for ver in ["2.6.6"]:
            self.targets[ver] = f"https://github.com/OpenPHDGuiding/phd2/archive/refs/tags/v{ver}.tar.gz"
            self.archiveNames[ver] = f"phd2-{ver}.tar.gz"
            self.targetInstSrc[ver] = f"phd2-{ver}"
        self.defaultTarget = "2.6.6"
    
    def setDependencies(self):
        self.runtimeDependencies["virtual/base"] = None
        self.runtimeDependencies["libs/libwxwidgets"] = None
        self.runtimeDependencies["libs/cfitsio"] = None
        self.runtimeDependencies["libs/opencv/opencv"] = None
        self.runtimeDependencies["libs/libusb"] = None
        self.runtimeDependencies["libs/libnova"] = None
        self.runtimeDependencies["libs/indilib/indi"] = None
        self.runtimeDependencies["libs/libcurl"] = None
        self.runtimeDependencies["libs/eigen3"] = None

class Package(CMakePackageBase):
    def __init__(self):
        super().__init__()
