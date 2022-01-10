using namespace System.Management.Automation

function prompt {
    (Get-Location | Split-Path -Leaf) + (">" * ($NestedPromptLevel + 1)) + " "
}

function home {
    Get-Item ~\OneDrive\ドキュメント\PowerShell
}

function modules {
    (home).GetDirectories("Modules") | Get-ChildItem -Directory
}

function rma {
    Clear-Host
    Get-Module -Name "Satomaru.*" | Remove-Module -Force -Verbose
    Get-Module
}

function ima {
    Clear-Host
    modules | Import-Module -Force -Verbose
    Get-Module
}

function help {
    Clear-Host
    Write-Host Satomaru Module Help:
    Write-Host

    [string[]] $ModuleNames = (modules).Name

    if ($ModuleNames.Length -eq 0) {
        Write-Host "Module Not Found."
        return
    }

    [nullable[int]] $ModuleIndex = Select-Array $ModuleNames -AbortWhenNot

    if ($null -eq $ModuleIndex) {
        return
    }

    Write-Host
    Write-Host $ModuleNames[$ModuleIndex] Help:
    Write-Host

    [object[]] $Commands = (Get-Module $ModuleNames[$ModuleIndex]).ExportedCommands.Values

    if ($Commands.Length -eq 0) {
        Write-Host "Command Not Found."
        return
    }

    [nullable[int]] $CommandIndex = Select-Array $Commands -AbortWhenNot

    if ($null -ne $CommandIndex) {
        $Commands[$CommandIndex] | Get-Help -Full
    }
}

[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[System.Console]::InputEncoding = [System.Text.Encoding]::UTF8
home | Set-Location
Get-Location
