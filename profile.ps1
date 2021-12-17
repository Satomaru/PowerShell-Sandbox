function prompt {
    Get-Location | Split-Path -Leaf | ForEach-Object { $_ + "> "}
}

Set-Location \Users\eryne\OneDrive\ドキュメント\PowerShell
Get-Location
