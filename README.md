# Meters on Demand

![MonD splash](https://repository-images.githubusercontent.com/601636170/25834e41-d86e-4f2a-809c-441ab80c2a8a)

the Rainmeter package manager. Install skins directly from the command line!

# Installation

Download the latest .rmskin from [releases](https://github.com/meters-on-demand/cli/releases).

MonD installs through Rainmeter so it can get the #SKINSPATH# variable and detect which skins you have installed. And as MonD is a skin manager, it can update itself through itself.

# Usage

To use MonD, you need to use the command line. Both `cmd` and `powershell` work. You can try `mond version` to test that MonD installed correctly.

Notice that if you had your terminal open before running the installer, you need to reopen it to make Windows detect the MonD script.

```ps1
update [-Force]
 updates the skins list

install [-Skin] <full_name> [-Force]
 installs the specified skin

search [-Query] <keyword> [-Property <property>]
 searches the skin list

upgrade [-Skin] <full_name> [-Force]
 upgrades the specified skin

uninstall [-Skin] <full_name> [-Force]
 uninstalls the specified skin

package [-Config] <rootconfig> [-LoadType <> -Load <> -VariableFiles <> -MinimumRainmeter <> -MinimumWindows <> -Author <> -HeaderImage <>]
 Creates an .rmskin package of the specified config, or the current working directory.
 The data is read from the skins Mond.inc, with optional commandline overrides.
 Please see https://github.com/meters-on-demand/cli/wiki/Package for documentation.

version
 prints the MonD version

help [-Command]
 show this help
```

Also check out the MonD [wiki](https://github.com/meters-on-demand/mond-api/wiki)!

# TO-DO:

- [ ] Packager skin that can
  - Take all of the information with the GUI
  - Read existing .rmskins by drag + drop
  - Create mond.inc, "save" the options
  - Read mond.inc and autofill the GUI
  - Package skins

# Credits

- Installer header and GitHub splash background image by [MA SH](https://www.artstation.com/artwork/L36yml)
- RMSKIN footer code from [auto-rmskin-package](https://github.com/brianferguson/auto-rmskin-package/blob/master/.github/workflows/release.yml) by @brianferguson
