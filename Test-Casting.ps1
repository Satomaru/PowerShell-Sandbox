using module Satomaru.Util

function Test-Casting {
    [Outputtype([object])]

    param (
        [Parameter(ValueFromPipeline)] [AllowNull()] [object] $Value
    )

    Process {
        $Result = [PSCustomObject] @{
            Value = ConvertTo-Expression $Value
            Casted = ""
            Type = ""
        }

        try {
            # ここでキャストを実行。
            [String] $Casted = $Value

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
    ) | Test-Casting
}
