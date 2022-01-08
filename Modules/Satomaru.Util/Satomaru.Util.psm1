<#
    .SYNOPSIS
    オブジェクトを抽出します。

    .DESCRIPTION
    オブジェクトを受け取り、 期待する条件に一致することを検査します。
    期待する条件に一致する場合は、そのまま返却します。

    .PARAMETER Target
    オブジェクト。

    .PARAMETER Property
    オブジェクトの検査対象となるプロパティ名。
    指定しなかった場合は、オブジェクトそのものが検査されます。

    .PARAMETER Truthy
    trueと解釈できることを期待します。

    .PARAMETER Falsy
    falseと解釈できることを期待します。

    .PARAMETER EQ
    指定値と等しいことを期待します。

    .PARAMETER NE
    指定値と異なることを期待します。

    .PARAMETER LT
    指定値よりも小さいことを期待します。

    .PARAMETER LE
    指定値よりも小さいか等しいことを期待します。

    .PARAMETER GT
    指定値よりも大きいことを期待します。

    .PARAMETER GE
    指定値よりも大きいか等しいことを期待します。

    .PARAMETER Contains
    指定値のうちのいずれか一つと等しいことを期待します。

    .PARAMETER Match
    指定された正規表現に一致することを期待します。

    .INPUTS
    オブジェクト。

    .OUTPUTS
    [object] 期待する条件に一致する場合は、入力されたオブジェクト。

    .EXAMPLE
    1..5 | Find-Object -GE 2 -LE 4

    2, 3, 4 が抽出される。

    .EXAMPLE
    Get-Item *.txt | Find-Object -Property Length -LE 70

    ファイルサイズが 70 byte 以下の *.txt が抽出される。
#>
function Find-Object {
    [OutputType([object])]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)] [object] $Target,
        [string] $Property,
        [switch] $Truthy,
        [switch] $Falsy,
        [object] $EQ,
        [object] $NE,
        [object] $LT,
        [object] $LE,
        [object] $GT,
        [object] $GE,
        [object[]] $Contains,
        [regex] $Match
    )

    Process {
        return $Target `
            | ForEach-Object { $Property ? $_.$Property : $_ } `
            | Where-Object { -not $Truthy -or $_ } `
            | Where-Object { -not $Falsy -or -not $_ } `
            | Where-Object { $null -eq $EQ -or $_ -eq $EQ } `
            | Where-Object { $null -eq $NE -or $_ -ne $NE } `
            | Where-Object { $null -eq $LT -or $_ -lt $LT } `
            | Where-Object { $null -eq $LE -or $_ -le $LE } `
            | Where-Object { $null -eq $GT -or $_ -gt $GT } `
            | Where-Object { $null -eq $GE -or $_ -ge $GE } `
            | Where-Object { -not $Contains -or $_ -in $Contains } `
            | Where-Object { -not $Match -or $_ -match $Match } `
            | ForEach-Object { $Target }
    }
}

<#
    .SYNOPSIS
    文字列を最適化します。

    .DESCRIPTION
    文字列の前後にあるホワイトスペースを除去した後、クォートを解除します。
    クォートの解除は、先頭と末尾がともにダブルクォート、
    またはともにシングルクォートの場合のみ行います。

    .PARAMETER Target
    最適化する文字列。

    .INPUTS
    最適化する文字列。

    .OUTPUTS
    [string] 最適化された文字列。

    .EXAMPLE
    " 'foo ' " | Optimize-String

    "foo " が返却されます。
#>
function Optimize-String {
    [OutputType([string])]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)] [string] $Target
    )

    Process {
        $Target = $Target.Trim()

        if ($Target -match '^"(.*)"$') {
            return $Matches[1]
        } elseif ($Target -match "^'(.*)'$") {
            return $Matches[1]
        } else {
            return $Target
        }
    }
}

<#
    .SYNOPSIS
    パラメータ文字列を式毎に分割します。

    .DESCRIPTION
    パラメータ文字列とは、以下のような文字列を意味します。
    "Foo = 1; Bar = 2; Baz"

    まずパラメータ文字列を、パーツ区切り文字（上記例では";"）で分割します。
    分割したパーツがプロパティ式になっている場合（上記例ではFooとBar）は、
    さらに名前と値に分割され、引数のhashtableに格納されます。
    なお、名前と値は、必ずstringになります。

    .PARAMETER Parameter
    パラメータ文字列。

    .PARAMETER Values
    プロパティ式の名前と値を格納する、ハッシュテーブルの参照。

    .PARAMETER PartsDelimiter
    パーツ区切り文字。省略時は ";" を用います。

    .PARAMETER ValueSeparator
    プロパティ式の値区切り文字。省略時は "=" を用います。
    
    .INPUTS
    パラメータ文字列。

    .OUTPUTS
    [string[]] 分割されたパーツの配列。

    .EXAMPLE
    [string[]] $Parts = "text/html; charset=UTF-8" | Split-Parameter -Values ([ref] $Values)

    $Parts には @("text/html", "charset=UTF-8") が、$Props には @{charset = "UTF-8"} が格納されます。
#>
function Split-Parameter {
    [OutputType([string[]])]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)] [string] $Parameter,
        [hashtable] [ref] $Values,
        [Alias("PD")] [ValidateNotNullOrEmpty()] [string] $PartsDelimiter = ";",
        [Alias("VS")] [ValidateNotNullOrEmpty()] [string] $ValueSeparator = "="
    )

    Process {
        return $Parameter -split $PartsDelimiter | ForEach-Object {
            [string] $Part = $_.Trim()

            if ($null -ne $Values) {
                [string[]] $Pair = $Part -split $ValueSeparator, 2 | Optimize-String

                if ($Pair.Count -eq 2) {
                    $Values.Add($Pair[0], $Pair[1])
                }
            }

            return $Part
        }
    }
}

<#
    .SYNOPSIS
    配列が期待どおりであることを検査します。

    .DESCRIPTION
    配列の長さ、および各要素の値が等しい場合は$trueを返却します。

    .PARAMETER Actual
    検査対象となる配列の参照。

    .PARAMETER Expected
    期待値となる配列の参照。

    .INPUTS
    なし。

    .OUTPUTS
    [boolean] 配列の長さ、および各要素の値が等しい場合は$true。

    .EXAMPLE
    Test-Array -Actual ([ref] $foo) -Expected ([ref] $bar)

    $fooと$barの要素数、および各要素の値が等しい場合は、$rueが返却されます。
#>
function Test-Array {
    [OutputType([boolean])]

    Param(
        [Parameter(Mandatory)] [object[]] [ref] $Actual,
        [Parameter(Mandatory)] [object[]] [ref] $Expected
    )

    Process {
        if ($Actual.Count -ne $Expected.Count) {
            return $false
        }

        for ($Index = 0; $Index -lt $Actual.Count; $Index++) {
            if ($Actual[$Index] -ne $Expected[$Index]) {
                return $false
            }
        }

        return $true
    }
}
