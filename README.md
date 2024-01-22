# Meters on Demand

![MonD splash](https://repository-images.githubusercontent.com/601636170/25834e41-d86e-4f2a-809c-441ab80c2a8a)

the Rainmeter package manager. Install skins directly from the command line!

# Installation

Download the latest .rmskin from [releases](https://github.com/meters-on-demand/cli/releases).

Check out the [Meters on Demand wiki](https://docs.rainmeter.skin/) for more information and usage instructions.

# Contributing

Check the TO-DO below if you want to help!

Installing mond for development (requires mond):

```ps
Set-Location "$(mond SkinPath)"
Remove-Item "Meters on Demand" -Recurse -Force
git clone "https://github.com/meters-on-demand/cli.git" "Meters on Demand"
Set-Location ".\Meters on Demand"
mond refresh # Optional 
```

`mond refresh` runs the installer again to copy the script into #Mond

When testing you can run `.\MetersOnDemand.ps1` directly instead of waiting for the refresh

# Dev commands

The cli has "hidden" developer commands. To see the list use `mond help dev`. Some of the hidden commands are useful for skin makers too. 

# Testing

You should always run the tests when committing or at least before creating a PR to confirm everything still works.

## Installing Pester

```ps
Install-Module Pester -Force
Import-Module Pester -PassThru
```

## Running Pester tests, in the "Meters on Demand" directory

```ps
Invoke-Pester -Output Detailed
```

# TO-DO:

- [x] Put $Cache inside $MetersOnDemand, initialize cache with New-Cache stuff already there
  - [x] Look into using PowerShell modules to isolate $MetersOnDemand into module scope
  - Too hard and Microsoft ain't doin shit about it
- [ ] Clean function signatures and the code base in general skull
- [ ] Use ParameterSets and Aliases instead of a billion different variables and checking if they're set
  - eg. `Alias("Bangs", "Bang")` instead of `if($Parameter -and !$Bang) { $Bang = $Parameter }`
  - Read https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_advanced_parameters?view=powershell-7.4
- [ ] Add `Set-Alias` into powershell profile to access MetersOnDemand.ps1 directly in PowerShell
  - Ask the user before doing this. Maybe use registry or something to store if the user has already been asked? Or the config file. 
- [ ] Make `uninstall` and `restore` send bangs to Rainmeter
- [x] Use Version from mond.inc for skins that have it in `Get-InstalledSkins`
- [ ] Work on `mond plugin [-Plugin] <plugin> [-Version <version>]` and the [plugin repository](https://github.com/meters-on-demand/plugins)
  - `mond plugin` is needed for silent installs and installs from git sources in general
  - Using a repository is kinda sussy since it's just .dll files. At least it's public but still 
  - Investigate how easy it'd be to scrape the forums or how ethical it'd be to include the .dlls into a repository
- [x] Make the API work with any git source. Git itself has tags which are the way the API tracks skin updates.
  - This would also enable silent installs
  - [x] Make `mond install` accept a git uri and use git clone on it directly. Useful if the API is down or the skin not registered.
  - [ ] Document `mond install <uri>`
  - [ ] Make `mond install` check the API even if installing from git uri
  - [ ] Use `mond plugin` to install plugins for git cloned skins
  - [ ] Make `mond install` git clone by default
- [x] Investigate getting rid of `mond update` it's annoying and most of the time commands that need it will auto update anyway(?)
  - For example, `mond install <fullName>` could internally `mond update` and try again before failing
  - Added `mond config AlwaysUpdate 1` for this
  - Document `mond config`
- [x] Use PSRM in Installer.ini to show status messages while installing (?)
- [ ] Implement fuzzy search :3
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
