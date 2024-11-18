import info
from CraftCore import CraftCore
from Package.CMakePackageBase import CMakePackageBase

class subinfo(info.infoclass):
    def setTargets(self):
        self.description = "WxWidgets Cross Platform GUI Library"
        self.svnTargets["master"] = "https://github.com/wxWidgets/wxWidgets.git"
        for ver in ["3.2.6"]:
            self.targets[ver] = f"https://github.com/wxWidgets/wxWidgets/releases/download/v{ver}/wxWidgets-{ver}.tar.bz2"
            self.archiveNames[ver] = f"wxwidgets-{ver}.tar.gz"
            self.targetInstSrc[ver] = f"wxwidgets-{ver}"
        self.defaultTarget = "3.2.6"
    
    def setDependencies(self):
        self.runtimeDependencies["virtual/base"] = None

class Package(CMakePackageBase):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)