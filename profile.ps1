function prompt {
    Get-Location | Split-Path -Leaf | ForEach-Object { $_ + (">" * ($NestedPromptLevel + 1)) + " " }
}

function rma {
    Clear-Host
    Get-Module -Name "Satomaru.*" | Remove-Module -Force -Verbose
    Get-Module
}

function ima {
    Clear-Host
    Get-ChildItem -Path .\Modules -Directory | Import-Module -Force -Verbose
    Get-Module
}

Set-Location ~\OneDrive\ドキュメント\PowerShell
Get-Location
