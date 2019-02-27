# DMGGenerator (c) 2018 Robin Lobel
Simple bash script to generate DMG application and package installers, support background and localized licenses.  

In case of an application installer, your application icon is centered at 25%,50% of your background image and the shortcut to the /Applications folder is centered at 75%,50% of your background image.  
In case of a package installer, your package icon is centered at 50%,50% of your background image.

The license can be in txt or rtf format.  
Localized licenses are supported, in this case the language code (ISO 639-1) is added before the extension. For instance if you provide "eula_.txt" and specify en fr, it will look for "eula_en.txt" and "eula_fr.txt".  
The following languages are supported: en (English) fr (French) de (German) it (Italian) es (Spanish) ja (Japanese) ru (Russian) ko (Korean) zh (Chinese) pt (Portuguese)

Rez and ResMerger utilities (required when you add licenses) are provided for simplicity, but are part of XCode.  
This script has been fully tested on OS X 10.10, 10.11, macOS 10.12 and 10.13

Usage:
------
dmggenerator.bash dmgpath apporpkgpath backgroundpath [licensepath] [language1] [language2] [...]

Examples:
---------
Simple application installer with no license  
dmggenerator.bash "installer/My Installer.dmg" "bin/My App.app" "resources/installerbackground.png"  

Simple package installer with no license  
dmggenerator.bash "installer/My Installer.dmg" "bin/My Package.pkg" "resources/installerbackground.png"  

Application Installer with an english license  
dmggenerator.bash "installer/My Installer.dmg" "bin/My App.app" "resources/installerbackground.png" "resources/eula.rtf"

Application Installer with localized licenses in english and french  
dmggenerator.bash "installer/My Installer.dmg" "bin/My App.app" "resources/installerbackground.png" "resources/eula_.rtf" en fr
