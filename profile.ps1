function prompt {
    Get-Location | Split-Path -Leaf | ForEach-Object { $_ + "> "}
}

function importAll {
    Import-Module -Name Satomaru.Util -Force -verbose
    Import-Module -Name Satomaru.Web -Force -verbose
}

Set-Location \Users\eryne\OneDrive\ドキュメント\PowerShell
Get-Location
