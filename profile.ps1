function prompt {
    Get-Location | Split-Path -Leaf | ForEach-Object { $_ + "> "}
}

function importAll {
    Get-ChildItem -Path ~\OneDrive\ドキュメント\PowerShell\Modules | ForEach-Object {
        Import-Module -Name $_.Name -Force -Verbose
    }
}

Set-Location ~\OneDrive\ドキュメント\PowerShell
Get-Location
