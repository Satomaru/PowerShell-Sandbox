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
            [boolean] $NoEnumerate = $null -ne $Value -and $Value.GetType().IsArray
            [object[]] $Mapped = Write-Output $Value -NoEnumerate:$NoEnumerate | ForEach-Object $Mapper
            [object] $Casted = $Mapped[0]
            $Result.Casted = ConvertTo-Expression $Casted
            $Result.Type = ($null -ne $Casted) ? $Casted.GetType().Name : "" 
        } catch {
            $Result.Casted = "*Error*"
        }

        return $Result
    }
}

function inspect {
    Clear-Host

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
    ) | Test-Casting { [string] $_ }
}
