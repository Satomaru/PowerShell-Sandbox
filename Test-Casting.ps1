using module Satomaru.Util

function Test-Casting {
    [Outputtype([object])]

    param (
        [Parameter(Mandatory)] [ValidateNotNull()] [scriptblock] $Mapper,
        [Parameter(ValueFromPipeline)] [AllowNull()] [object] $Value
    )

    Process {
        $Result = [PSCustomObject] @{
            Value = ConvertTo-Expression $Value
            Casted = ""
            Type = ""
        }

        try {
            [object[]] $Mapped = Write-Output $Value -NoEnumerate | ForEach-Object $Mapper
            [object] $Casted = $Mapped[0]
            $Result.Casted = ConvertTo-Expression $Casted
            $Result.Type = ($null -ne $Casted) ? $Casted.GetType().Name : "" 
        } catch {
            $Result.Casted = "*Error*"
            $Result.Type = $_.Exception.GetBaseException().GetType().Name
        }

        return $Result
    }
}

function inspect {
    @(
        $null,
        $false,
        $true,
        0,
        1,
        "",
        " ",
        "0",
        "1",
        "a",
        "foo",
        @(),
        @($null),
        @($false),
        @($true),
        @(0),
        @(1),
        @(""),
        @(" "),
        @("0"),
        @("1"),
        @("a"),
        @("foo"),
        @($null, $null),
        @($false, $true),
        @(0, 1),
        @("", ""),
        @(" ", " "),
        @("0", "1"),
        @("a", "b"),
        @("foo", "bar")
    ) | Test-Casting { [boolean] $_ }
}
