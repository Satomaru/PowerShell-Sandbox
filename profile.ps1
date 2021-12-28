function prompt {
    Get-Location | Split-Path -Leaf | ForEach-Object { $_ + "> "}
}

function ima {
    Get-ChildItem -Path .\Modules -Directory | ForEach-Object {
        Import-Module -Name $_.Name -Force -Verbose
    }
}

function import([string] $SubName) {
    Import-Module -Name "Satomaru.$SubName" -Force -Verbose
}

Set-Location ~\OneDrive\ドキュメント\PowerShell
Get-Location
