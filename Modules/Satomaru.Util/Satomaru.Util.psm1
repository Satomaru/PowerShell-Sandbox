#Requires -Version 7
using namespace Microsoft.PowerShell.Commands

function ConvertTo-Trimmed {
    [OutputType([string])]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)] [string] $Target
    )

    Process {
        $Target = $Target.Trim()

        if ($Target -match "^""(.*)""$") {
            return $Matches[1]
        } else {
            return $Target
        }
    }
}

function ConvertTo-Bytes {
    [OutputType([byte[]])]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)] [string] $Target,
        [Parameter(Mandatory)] [string] $Charset
    )

    Process {
        return [System.Text.Encoding]::GetEncoding($Charset).GetBytes($Target) 
    }
}

function ConvertTo-Hashtable {
    [OutputType([hashtable])]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)] [string] $Target,
        [Parameter(Mandatory)] [Alias("ED")] [string] $ElementDelimiter,
        [Parameter(Mandatory)] [Alias("PS")] [string] $PairSeparator
    )

    Process {
        [hashtable] $Hashtable = @{}

        $Target -split $ElementDelimiter | ForEach-Object {
            [string[]] $Pair = $_ -split $PairSeparator, 2 | ConvertTo-Trimmed

            if ($pair.Count -eq 2) {
                $Hashtable.Add($Pair[0], $Pair[1])
            }        
        }

        return $Hashtable
    }
}

Export-ModuleMember -Function ConvertTo-Trimmed
Export-ModuleMember -Function ConvertTo-Bytes
Export-ModuleMember -Function ConvertTo-Hashtable
