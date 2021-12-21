#Requires -Version 7
using namespace Microsoft.PowerShell.Commands

function Search-Item {
    [OutputType([System.IO.FileSystemInfo])]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)] [System.IO.FileSystemInfo] $Item,
        [switch] $ReadOnly,
        [string[]] $Extension,
        [datetime] $UpdateBefore,
        [datetime] $UpdateAfter,
        [long] $SmallerThan,
        [long] $LargerThan,
        [string] $NameMatch,
        [string] $ContentMatch,
        [System.Text.Encoding] $Encoding = [System.Text.Encoding]::Default
    )

    Process {
        if ($ReadOnly) {
            if (-not $Item.IsReadOnly) {
                return
            }
        }

        if ($Extension.Count -gt 0) {
            if ($Extension -notcontains $Item.Extension) {
                return
            }
        }

        if ($null -ne $UpdateBefore) {
            if ($UpdateBefore -le $Item.LastWriteTime) {
                return
            }
        } 

        if ($null -ne $UpdateAfter) {
            if ($UpdateAfter -ge $Item.LastWriteTime) {
                return
            }
        } 

        if ($SmallerThan -gt 0) {
            if ($SmallerThan -le $Item.Length) {
                return
            }
        }

        if ($LargerThan -gt 0) {
            if ($LargerThan -ge $Item.Length) {
                return
            }
        }

        if ($NameMatch -ne "") {
            if ($Item.Name -notmatch $NameMatch) {
                return
            }
        }

        if ($ContentMatch -ne "") {
            [boolean] $Hit = $false

            foreach ($Content in $Item | Get-Content -Encoding $Encoding) {
                if ($Content -match $ContentMatch) {
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
