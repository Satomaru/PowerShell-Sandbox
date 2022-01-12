using module Satomaru.Util

function Test-Casting {
    [Outputtype([string])]

    param (
        [Parameter(ValueFromPipeline)] [AllowNull()] [object] $Value
    )

    Process {
        $Result = [PSCustomObject] @{
            Value = ConvertTo-Expression $Value
            Casted = ""
        }

        try {
            # この行が、キャストを検証しています。
            [char[]] $Casted = $Value

            $Result.Casted = ConvertTo-Expression $Casted
        } catch {
            $Result.Casted = "*Error*"
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
    ) | Test-Casting
}
