using module Satomaru.Definition

function Test-Validate {
    [CmdletBinding()]
    [OutputType([object])]

    Param(
        [Parameter(Mandatory)] [ValidateDirectory()] [string] $Directory,
        [Parameter(Mandatory)] [ValidateFileName()] [string] $FileName,
        [Parameter(Mandatory)] [ValidateSet([ValidateSetJaCharset])] [string] $Charset
    )

    Process {
        [PSCustomObject]@{
            Directory = Resolve-Path -LiteralPath $Directory
            FileName = $FileName
            Encoding = [System.Text.Encoding]::GetEncoding($Charset)
        }
    }
}
