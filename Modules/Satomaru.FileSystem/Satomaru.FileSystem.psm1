#Requires -Version 7
using namespace Microsoft.PowerShell.Commands

function Search-ByName {
    [OutputType([System.IO.FileSystemInfo])]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)] [System.IO.FileSystemInfo] $Target,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [string] $Pattern
    )

    Process {
        if ($target.Name -match $Pattern) {
            return $Target
        }
    }
}

Export-ModuleMember -Function Search-ByName
