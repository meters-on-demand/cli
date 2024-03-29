function Help {
    param(
        [Parameter(Position = 0)]
        [string]
        $Topic
    )

    Limit-PowerShellVersion

    $skinSig = "[-Skin] <fullName>"
    $forceSig = "[-Force]"
    $packageWiki = "https://docs.rainmeter.skin/cli/package"
    $initWiki = "https://docs.rainmeter.skin/cli/init"
    
    if($MetersOnDemand.Config.AskAlias) {
        Write-Host "Use 'mond alias' to add aliases to your PowerShell profile"
        Write-Host "Use 'mond help alias' for more information"
        Write-Host "Use 'mond config AskAlias false' to suppress this message" -ForegroundColor Yellow
        Write-Host ""
    }

    $commands = @(
        [pscustomobject]@{
            Name        = "update"
            Signature   = ""
            Description = "updates the skins list"
        }, 
        [pscustomobject]@{
            Name        = "install"
            Signature   = "$skinSig $forceSig"
            Description = "installs the specified skin"
        }, 
        [pscustomobject]@{
            Name        = "list"
            Signature   = "[-Unmanaged]"
            Description = "lists installed skins. use -Unmanaged to list manually installed skins"
        }, 
        [pscustomobject]@{
            Name        = "search"
            Signature   = "[-Query] <keyword> [-Property <property>]"
            Description = "searches the skin list"
        }, 
        [pscustomobject]@{
            Name        = "upgrade"
            Signature   = "$skinSig $forceSig"
            Description = "upgrades the specified skin"
        }, 
        [pscustomobject]@{
            Name        = "uninstall"
            Signature   = "$skinSig $forceSig"
            Description = "uninstalls the specified skin"
        }, 
        [pscustomobject]@{
            Name        = "restore"
            Signature   = "$skinSig $forceSig"
            Description = "restores an upgraded or uninstalled skin from @Backup"
        },
        [pscustomobject]@{
            Name        = "version"
            Signature   = ""
            Description = "prints the MonD version"
        },
        [pscustomobject]@{
            Name        = "alias"
            Signature   = ""
            Description = "adds Set-Alias calls to your PowerShell `$PROFILE`n aliases speed up mond by skipping the cmd invocation`n if you use both PowerShell 5 and 7, you'll have to run 'mond alias' in both"
        },
        [pscustomobject]@{
            Name        = "help"
            Signature   = "[-Command] [dev]"
            Description = "show this help. use 'mond help dev' for a list of dev commands"
        }
    )

    $devCommands = @(
        [pscustomobject]@{
            Name        = "package"
            Signature   = "[[-Skin] <rootconfig>] [...]"
            Description = "creates a .rmskin package of the specified skin"
            Wiki        = $packageWiki
        }, 
        [pscustomobject]@{
            Name        = "init"
            Signature   = "[-Skin] <skinname>"
            Description = "creates a new skin folder from a template"
            Wiki        = $initWiki
        },
        [pscustomobject]@{
            Name        = "bang"
            Signature   = "[[-Bang] <bangs>] [-StartRainmeter | -Start] [-StopRainmeter | -Stop] [-NoStart]"
            Description = "runs bangs through `$RmApi or by commanding the executable directly`n if -Start or -Stop is present, bangs are run after or before starting or stopping Rainmeter`n if -NoStart is present, mond will skip the bang if Rainmeter is not running.`n you can also call the bang command directly without the mond prefix"
        },
        [pscustomobject]@{
            Name        = "open"
            Signature   = "$($skinSig)"
            Description = "Opens the specified skins #ROOTCONFIG# in your #CONFIGEDITOR#"
        },
        [pscustomobject]@{
            Name        = "lock"
            Signature   = "$($skinSig)"
            Description = "Generates a .lock.inc file for the specified skin"
        },
        [pscustomobject]@{
            Name        = "config"
            Signature   = ""
            Description = "Prints debug information of the main $($MetersOnDemand.FileName) script"
        },
        [pscustomobject]@{
            Name        = ""
            Signature   = "<property>"
            Description = "Prints the specified property if it's present in MetersOnDemand.ps1 `$MetersOnDemand or the mond cache.json"
        },
        [pscustomobject]@{
            Name        = "dir"
            Signature   = ""
            Description = "Opens #SKINSPATH#\$($MetersOnDemand.Directory)"
        },
        [pscustomobject]@{
            Name        = "refresh"
            Signature   = ""
            Description = "Reinstalls Meters on Demand"
        }
    )

    if ($Topic -eq "dev") {
        foreach ($command in $devCommands) {
            Write-Host "$($command.name) " -ForegroundColor White -NoNewline
            Write-Host "$($command.signature) " -ForegroundColor Cyan
            Write-Host " $($command.Description)" -ForegroundColor Gray -NoNewline
            if ($command.Wiki) {
                Write-Host "`n $($command.Wiki)" -ForegroundColor Blue -NoNewline
            }
            Write-Host "`n"
        }
        return
    }

    if ($Topic) {
        if ($Topic -eq "api") { 
            Start-Process "$($MetersOnDemand.Api.Wiki)"
            return
        }
        $command = $commands | Where-Object { $_.Name -eq $Topic }
        if (!$command) { $command = $devCommands | Where-Object { $_.Name -eq $Topic } }
        if (!$command) { 
            throw "$($Topic) is not a command. Use 'mond help' to see all available commands."
        }
        if ($Topic -eq "package") { 
            Start-Process "$($packageWiki)"
            return
        }
        Write-Host "$($command.Name) " -ForegroundColor White -NoNewline
        Write-Host "$($command.Signature) " -ForegroundColor Cyan
        Write-Host " $($command.Description)" -ForegroundColor Gray
        return
    }

    foreach ($command in $commands) {
        Write-Host "$($command.name) " -ForegroundColor White -NoNewline
        Write-Host "$($command.signature) " -ForegroundColor Cyan
        Write-Host " $($command.Description)" -ForegroundColor Gray -NoNewline
        if ($command.Wiki) {
            Write-Host "`n $($command.Wiki)" -ForegroundColor Blue -NoNewline
        }
        Write-Host "`n"
    }
    
    Write-Host "Check out the Meters on Demand wiki! " -NoNewline
    Write-Host $MetersOnDemand.Wiki -ForegroundColor Blue

    return 
}
