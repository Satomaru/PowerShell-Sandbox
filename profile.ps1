using namespace System.Management.Automation

function prompt {
    Get-Location | Split-Path -Leaf | ForEach-Object { $_ + (">" * ($NestedPromptLevel + 1)) + " " }
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
    [string] $ModuleMame = Read-ArrayItem -Array (modules | ForEach-Object Name)

    if (-not $ModuleMame) {
        return
    }

    Write-Host
    Write-Host $ModuleMame Help:
    Write-Host
    $Commands = Get-Module $ModuleMame | ForEach-Object ExportedCommands

    if ($Commands.Count -eq 0) {
        Write-Host "Commands Not Found."
        return
    }

    [CommandInfo] $Command = Read-ArrayItem -Array $Commands.Values

    if ($Command) {
        $Command | Get-Help -Full
    }
}

[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[System.Console]::InputEncoding = [System.Text.Encoding]::UTF8
home | Set-Location
Get-Location
