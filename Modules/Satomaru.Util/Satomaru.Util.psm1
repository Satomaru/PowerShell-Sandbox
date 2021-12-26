<#
    .SYNOPSIS
    オブジェクトを抽出する。

    .DESCRIPTION
    オブジェクトを受け取って検査を行う。
    検査に合格した場合は、受け取ったオブジェクトをそのまま返却する。
    なお、null の場合は、その時点で不合格とする。

    .PARAMETER Target
    検査するオブジェクト。

    .PARAMETER Property
    オブジェクトの検査対象となるプロパティ名。
    指定しなかった場合は、オブジェクトそのものが検査される。

    .PARAMETER Truthy
    true と解釈されることを検査する。

    .PARAMETER Falsy
    false と解釈されることを検査する。

    .PARAMETER EQ
    指定値と等しいことを検査する。

    .PARAMETER NE
    指定値と異なることを検査する。

    .PARAMETER LT
    指定値よりも小さいことを検査する。

    .PARAMETER LE
    指定値よりも小さいか等しいことを検査する。

    .PARAMETER GT
    指定値よりも大きいことを検査する。

    .PARAMETER GE
    指定値よりも大きいか等しいことを検査する。

    .PARAMETER Contains
    指定値のうちのいずれか一つと等しいことを検査する。

    .PARAMETER Match
    指定された正規表現に一致することを検査する。

    .INPUTS
    検査するオブジェクト。

    .OUTPUTS
    検査に合格した場合は、検査したオブジェクト。

    .EXAMPLE
    @(1,2,3,4,5) | Find-Object -GE 2 -LE 4
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
            | Where-Object { -not $Contains -or $Contains.Contains($_) } `
            | Where-Object { -not $Match -or $_ -match $Match } `
            | ForEach-Object { $Target }
    }
}

<#
    .SYNOPSIS
    文字列を最適化する。

    .DESCRIPTION
    文字列の前後にあるホワイトスペースを除去した後、クォートを解除する。
    クォートの解除は、先頭と末尾がともにダブルクォート、
    またはともにシングルクォートの場合のみ行う。
    
    .PARAMETER Target
    最適化する文字列。

    .INPUTS
    最適化する文字列。

    .OUTPUTS
    最適化された文字列。

    .EXAMPLE
    " 'foo ' " | Optimize-String
    "foo " が返却される。
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
    パラメータ文字列を要素毎に分割する。

    .DESCRIPTION
    まずパラメータ文字列をパーツ区切り文字で分割する。
    分割したパーツがプロパティ式の書式になってい場合は、さらに名前と値に分割する。

    .PARAMETER Parameter
    パラメータ文字列。

    .PARAMETER Values
    プロパティ式の名前と値を格納する、ハッシュテーブルの参照。

    .PARAMETER PartsDelimiter
    別名 "PD"。パーツ区切り文字。省略時は ";" を用いる。

    .PARAMETER ValueSeparator
    別名 "VS"。プロパティ式の値区切り文字。省略時は "=" を用いる。
    
    .INPUTS
    パラメータ文字列。

    .OUTPUTS
    パーツ区切り文字で分割された、パーツの配列。

    .EXAMPLE
    [string[]] $Parts = "text/html; charset=UTF-8" | Split-Parameter -Values ([ref] $Values)
    $Parts には @("text/html", "charset=UTF-8") が、$Props には @{charset = "UTF-8"} が格納される。
#>
function Split-Parameter {
    [OutputType([string[]])]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)] [string] $Parameter,
        [hashtable] [ref] $Values,
        [Alias("PD")] [string] $PartsDelimiter = ";",
        [Alias("VS")] [string] $ValueSeparator = "="
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
    配列が期待どおりであることを検査する。

    .DESCRIPTION
    配列の長さ、および各要素の値が等しい場合は true を返却する。

    .PARAMETER Actual
    検査対象となる配列の参照。

    .PARAMETER Expected
    期待値となる配列の参照。

    .INPUTS
    なし。

    .OUTPUTS
    判定結果。

    .EXAMPLE
    Test-Array -Actual ([ref] $foo) -Expected ([ref] $bar)
    $foo と $bar の要素数、および各要素の値が等しい場合は、true が返却される。
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
