function prompt {
    Get-Location | Split-Path -Leaf | ForEach-Object { $_ + "> "}
}

function rma {
    Get-Module -Name "Satomaru.*" | Remove-Module -Force -Verbose
    Clear-Host
    Get-Module
}

function ima {
    Get-ChildItem -Path .\Modules -Directory | Import-Module -Force -Verbose
    Clear-Host
    Get-Module
}

function import([string] $SubName) {
    Import-Module -Name "Satomaru.$SubName" -Force -Verbose
}

function help([string] $Command) {
    Get-Help -Name $Command -Full
}

Set-Location ~\OneDrive\ドキュメント\PowerShell
Get-Location
