function prompt {
    Get-Location | Split-Path -Leaf | ForEach-Object { $_ + "> "}
}

function importAll {
    Import-Module -Name Satomaru.Util -Force -Verbose
    Import-Module -Name Satomaru.Web -Force -Verbose
}

Set-Location ~\OneDrive\ドキュメント\PowerShell
Get-Location
