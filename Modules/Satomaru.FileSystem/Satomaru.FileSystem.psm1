#Requires -Version 7
using namespace Microsoft.PowerShell.Commands

function Search-Item {
    [OutputType([System.IO.FileSystemInfo])]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)] [System.IO.FileSystemInfo] $Item,
        [ValidateNotNull()] [string] $ByName,
        [ValidateNotNull()] [string] $ByContent,
        [FileSystemCmdletProviderEncoding] $Encoding
    )

    Process {
        if ($ByName -ne "") {
            if ($Item.Name -notmatch $ByName) {
                return
            }
        }

        if ($ByContent -ne "") {
            if ($null -ne $Encoding) {
                $Encoding = [FileSystemCmdletProviderEncoding]::Ascii
            }

            [boolean] $Hit = $false

            foreach ($Content in $Item | Get-Content -Encoding $Encoding) {
                if ($Content -match $ByContent) {
                    $Hit = $true
                    break
                }
            }

            if (-not $Hit) {
                return
            }
        }

        return $Item
    }
}

Export-ModuleMember -Function Search-Item
