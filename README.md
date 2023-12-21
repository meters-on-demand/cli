# Meters on Demand

![MonD splash](https://repository-images.githubusercontent.com/601636170/25834e41-d86e-4f2a-809c-441ab80c2a8a)

the Rainmeter package manager. Install skins directly from the command line!

# Installation

Download the latest .rmskin from [releases](https://github.com/meters-on-demand/cli/releases).

Check out the [Meters on Demand wiki](https://docs.rainmeter.skin/) for more information and usage instructions.

# Contributing

The cli has "hidden" developer commands. To see the list use `mond help dev`. Some of the hidden commands are useful for skin makers too. 

Check the TO-DO below if you want to help!

# TO-DO:

- [x] Put $Cache inside $MetersOnDemand, initialize cache with New-Cache stuff already there
- [ ] Make `uninstall` and `restore` send bangs to Rainmeter
- [ ] Make the API work with any git source. Git itself has tags which are the way the API tracks skin updates.
  - If a skin is from not-GitHub, `git clone` it and use `mond plugin` to install its plugins
  - This would also enable silent installs
  - Make `mond install` git clone by default
  - Make `mond install` accept a git uri and use git clone on it directly. Useful if the API is down or the skin not registered.
- [ ] Work on `mond plugin [-Plugin] <plugin> [-Version <version>]` and the [plugin repository](https://github.com/meters-on-demand/plugins)
  - Should download and install the plugin from the plugin repository
  - In the future it would be used to do silent installs and installs from git sources that can't host releases
- [ ] Implement fuzzy search :3
- [ ] Investigate getting rid of `mond update` it's annoying and most of the time commands that need it will auto update anyway(?)
  - For example, `mond install <full_name>` could internally `mond update` and try again before failing
- [ ] Use Version from mond.inc for skins that have it in `Get-InstalledSkins`
- [ ] Use PSRM in Installer.ini to show status messages while installing (?)
- [ ] Packager skin that looks exactly like the skin packager GUI but it can
  - Read existing .rmskins by drag + drop
  - Create a mond.inc to save the package information
  - Read a skins mond.inc and autofill the GUI
  - Package skins of course
  - It basically acts as a GUI for creating and editing mond.inc :3
- [ ] Detect included and used Fonts
  - Add-Type -AssemblyName PresentationCore
  - (New-Object -TypeName Windows.Media.GlyphTypeface -ArgumentList 'path\to\font').Win32FamilyNames.Values

# Credits

- Installer header and GitHub splash background image by [MA SH](https://www.artstation.com/artwork/L36yml)
- RMSKIN footer code from [auto-rmskin-package](https://github.com/brianferguson/auto-rmskin-package/blob/master/.github/workflows/release.yml) by [@brianferguson](https://github.com/brianferguson)
- Logo design by [@creepertron95](https://github.com/creepertron95) with edits by Jeff
- Testers and complainers
  - [@modkavartini](https://github.com/modkavartini)
  - [@keifufu](https://github.com/keifufu)
