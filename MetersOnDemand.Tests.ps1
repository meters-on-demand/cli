
BeforeAll {
    . .\MetersOnDemand.ps1
}

Describe "MetersOnDemand object" {
    It "Exists" { 
        $MetersOnDemand | Should -BeOfType pscustomobject
    }
}

Describe "Lock" {
    It "Generates the plugin list" {
        Remove-Item ".\.lock.inc"
        New-Lock "Meters on Demand" -Quiet
        Get-Content ".\.lock.inc" | Should -Be @("[Plugins]", "powershellrm=0.6.0.0")
    }
}

Describe "Package" {
    It "Doesn't throw" {
        { New-Package "Meters on Demand"  -Quiet } | Should -Not -Throw
    }
}

Describe "SkinList" {
    It "Contains skin objects" {
        $skins = Get-SkinList -Cache $MetersOnDemand.Cache
        $skins | Should -BeOfType pscustomobject
    }
}

Describe "Search" {
    It "Returns array of skin objects" {
        Search -Query "reisir" -Quiet | Should -BeOfType pscustomobject
    }
    It "Returns meters-on-demand/cli skin object" {
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

Describe "Get-SkinObject" {
    It "Gets the skin object" {
        $me = Get-SkinObject "meters-on-demand/cli"
        $me.skin_name | Should -Be "Meters on Demand"
    }
    It "Gets the skin object using rootconfig" {
        $me = Get-SkinObject -RootConfig "Meters on Demand"
        $me.skin_name | Should -Be "Meters on Demand"
    }
}

Describe "API request" {
    It "Should respond with array of skin objects" {        
        $response = Get-Request "$($MetersOnDemand.Api.Endpoints.Skins)"
        $response | ConvertFrom-Json | Should -BeOfType pscustomobject
    }
}

Describe "Get-MondInc" {
    It "Returns path to skin configuration file" {
        Get-MondInc -RootConfig "Meters on Demand" | Split-Path -Leaf | Should -Be "mond.inc"
    }
    It "Works when given rootconfigpath" {
        $Cache = $MetersOnDemand.Cache
        Get-MondInc -Path "$($Cache.SkinPath)\Meters on Demand" | Should -Be "$($Cache.SkinPath)\Meters on Demand\@Resources\mond.inc"
    }
}

Describe "Get-SkinInfo" {
    It "Returns skin configuration object" {
        $me = Get-SkinInfo -RootConfig "Meters on Demand"
        $me.SkinName | Should -Be "Meters on Demand"
        $me.LoadType | Should -Be "Skin"
        $me.Load | Should -Be "Meters on Demand\Installer.ini"
    }
}

Describe "Test-BuiltIn" {
    It "Correctly assesses plugin PowershellRM" {
        Test-BuiltIn "PowershellRM" | Should -Be $False
    }
    It "Correctly assesses plugin WebParser" {
        Test-BuiltIn "WebParser" | Should -Be $True
    }
    It "Correctly assesses plugin AudioLevel" {
        Test-BuiltIn "AudioLevel" | Should -Be $True
    }
}

Describe "Get-Plugins" {
    It "Reads the skins plugins" {
        Get-Plugins -RootConfig "Meters on Demand" | Should -Be @("powershellrm")
    }
}
