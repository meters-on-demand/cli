# Pester tests
# Invoke-Pester -Output Detailed

BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
}

Describe "Cached skins" {
    Context "MetersOnDemand object" {
        It "Exists" { 
            $MetersOnDemand | Should -BeOfType pscustomobject
        }
    }
    Context "API" {
        It "Calls /skins and receives values" {        
            $response = Get-Request "$($MetersOnDemand.Api.Endpoints.Skins)"
            $response | ConvertFrom-Json | Should -BeOfType pscustomobject
        }
    }
    Context "Get-SkinList" {
        It "Contains skin objects" {
            $skins = Get-SkinList -Cache $MetersOnDemand.Cache
            $skins | Should -BeOfType pscustomobject
        }
    }
    Context "Get-SkinObject" {
        It "Gets the 'meters-on-demand/cli' skin object" {
            $me = Get-SkinObject "meters-on-demand/cli"
            $me.skin_name | Should -Be "Meters on Demand"
        }
        It "Gets the 'meters-on-demand/cli' skin object using skin_name" {
            $me = Get-SkinObject -RootConfig "Meters on Demand"
            $me.skin_name | Should -Be "Meters on Demand"
        }
    }
}

Describe "Search" {
    It "Finds skins" {
        Search -Query "reisir" -Quiet | Should -BeOfType pscustomobject
    }
    It "Finds meters-on-demand/cli skin" {
        $results = Search -Query "meters-on-demand/cli" -Quiet
        $me = $results[0]
        $me.full_name | Should -Be "meters-on-demand/cli"
    }
    It "Finds skins using other properties" {
        $results = Search -Query "Meters on Demand" -Property "skin_name" -Quiet
        $me = $results[0]
        $me.full_name | Should -Be "meters-on-demand/cli"
    }
}

Describe "Reading config information" {
    Context "Get-MondInc" {
        It "Returns path to skin configuration file" {
            Get-MondInc -RootConfig "Meters on Demand" | Split-Path -Leaf | Should -Be "mond.inc"
        }
        It "Works when given rootconfigpath" {
            $Cache = $MetersOnDemand.Cache
            Get-MondInc -Path "$($Cache.SkinPath)\Meters on Demand" | Should -Be "$($Cache.SkinPath)\Meters on Demand\@Resources\mond.inc"
        }
    }
    Context "Get-SkinInfo" {
        It "Returns skin configuration object" {
            $me = Get-SkinInfo -RootConfig "Meters on Demand"
            $me.SkinName | Should -Be "Meters on Demand"
            $me.LoadType | Should -Be "Skin"
            $me.Load | Should -Be "Meters on Demand\Installer.ini"
        }
    }
}

Describe "Plugins" {
    Context "Test-BuiltIn" {
        It "Correctly assesses third-party plugin PowershellRM" {
            Test-BuiltIn "PowershellRM" | Should -Be $False
        }
        It "Correctly assesses built-in measure WebParser" {
            Test-BuiltIn "WebParser" | Should -Be $True
        }
        It "Correctly assesses built-in plugin AudioLevel" {
            Test-BuiltIn "AudioLevel" | Should -Be $True
        }
    }
    Context "Get-Plugins" {
        It "Reads the skins plugins" {
            Get-Plugins -RootConfig "Meters on Demand" | Should -Be @("powershellrm")
        }
    }
    Context "Lock" {
        It "Generates the plugin lock file" {
            Remove-Item ".\.lock.inc"
            New-Lock "Meters on Demand" -Quiet
            Get-Content ".\.lock.inc" | Should -Be @("[Plugins]", "powershellrm=0.6.0.0")
        }
    }
}

Describe "Package" {
    It "Doesn't throw" {
        { New-Package "Meters on Demand"  -Quiet } | Should -Not -Throw
    }
}

Describe "Invoke-Bang" {
    Context "Start and Stop" {
        BeforeAll {
            Get-Process -Name "Rainmeter" -ErrorAction Ignore | Stop-Process
            Start-Sleep -Milliseconds 250
        }
        It "Starts Rainmeter" {
            Invoke-Bang -StartRainmeter
            Get-Process -Name "Rainmeter" | Should -BeTrue
        }
        It "Stops Rainmeter" {
            Invoke-Bang -StopRainmeter
            Start-Sleep -Milliseconds 250
            Get-Process -Name "Rainmeter" -ErrorAction Ignore | Should -BeFalse
        }
    }
    Context "Bangs" {
        BeforeAll {
            $pesterInc = "$($MetersOnDemand.ScriptRoot)\pester.inc"
            if (!(Test-Path $pesterInc)) { New-Item -Path $pesterInc }
        }
        It "!WriteKeyValue" {
            $rs = ( -join ((65..90) + (97..122) | Get-Random -Count 5 | % { [char]$_ }))
            Invoke-Bang -StartRainmeter -Bang "[!WriteKeyValue `"Pester`" `"TestOutput`" `"$($rs)`" `"$($pesterInc)`"]"
            Start-Sleep -Milliseconds 250
            Get-Content -Path $pesterInc | Should -Be @("[Pester]", "TestOutput=$($rs)")
        }
        AfterAll {
            Remove-Item -Path $pesterInc -ErrorAction Ignore
        }
    }
}
