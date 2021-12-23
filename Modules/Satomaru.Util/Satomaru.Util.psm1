#Requires -Version 7
using namespace Microsoft.PowerShell.Commands

<#
    .SYNOPSIS
    オブジェクトを抽出する。

    .DESCRIPTION
    パイプラインからオブジェクトを受け取って検査を行う。
    検査に合格した場合は、受け取ったオブジェクトをそのまま返却する。
    なお、null の場合は、その時点で不合格とする。

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
            | Where-Object { -not $Contains -or $Contains -contains $_ } `
            | Where-Object { -not $Match -or $_ -match $Match } `
            | ForEach-Object { $Target }
    }
}

<#
    .SYNOPSIS
    ハッシュテーブルをまとめる。

    .DESCRIPTION
    パイプラインで受け取ったハッシュテーブルから全てのエントリを取得して、
    パラメータで指定されたハッシュテーブルに追加する。

    .PARAMETER To
    エントリの追加先となるハッシュテーブルの参照。

    .INPUTS
    ハッシュテーブル。

    .OUTPUTS
    なし。

    .EXAMPLE
    "foo=1; bar=2" -split ";" | New-KeyValue | Join-Hashtable -To ([ref] $map)
    $mapに、foo と bar のエントリが追加される。
#>
function Join-Hashtable {
    [OutputType([void])]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)] [hashtable] $From,
        [Parameter(Mandatory)] [hashtable] [ref] $To
    )

    Process {
        foreach ($Key in $From.Keys) {
            $To.Add($Key, $From.$Key)
        }
    }
}

<#
    .SYNOPSIS
    ハッシュテーブルを作成する。

    .DESCRIPTION
    パイプラインで受け取った文字列からエントリ式を解析し、作成したハッシュテーブルに追加する。
    なおエントリ式の左辺と右辺は、Optimize-String によって最適化される。

    .PARAMETER ExpressionDelimiter
    別名 "ED"。エントリ式の区切り記号。未指定時は ";" が用いられる。

    .PARAMETER ExpressionDelimiter
    別名 "KS"。エントリ式の左辺と右辺の区切り記号。未指定時は "=" が用いられる。

    .INPUTS
    エントリ式を表す文字列。

    .OUTPUTS
    ハッシュテーブル。

    .EXAMPLE
    "foo=1; bar=2" | New-Hashtable
    foo と bar のエントリを持つハッシュテーブルを返却する。
#>
function New-Hashtable {
    [OutputType([hashtable])]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)] [string] $Target,
        [Alias("ED")] [string] $ExpressionDelimiter = ";",
        [Alias("KS")] [string] $KeyValueSeparator = "="
    )

    Process {
        [hashtable] $Hashtable = @{}

        $Target -split $ExpressionDelimiter `
            | New-KeyValue -Separator $KeyValueSeparator `
            | Join-Hashtable -To ([ref] $Hashtable)

        return $Hashtable
    }
}

<#
    .SYNOPSIS
    エントリ式を解析して結果をハッシュテーブルで返す。

    .DESCRIPTION
    エントリ式の左辺と右辺は、Optimize-Stringによって最適化される。
    なお、文字列をエントリ式とみなせなかった場合は、空のハッシュテーブルを返却する。

    .PARAMETER Separator
    エントリ式の左辺と右辺の区切り記号。未指定時は "=" が用いられる。

    .INPUTS
    エントリ式を表す文字列。

    .OUTPUTS
    ハッシュテーブル。

    .EXAMPLE
    " foo = 'abc' " | New-KeyValue
    @{ foo = "abc" } が返却される。
#>
function New-KeyValue {
    [OutputType([hashtable])]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)] [string] $Target,
        [string] $Separator = "="
    )

    Process {
        [hashtable] $KeyValue = @{}
        [string[]] $Pair = $Target -split $Separator, 2 | Optimize-String

        if ($Pair.Count -eq 2) {
            $KeyValue.Add($Pair[0], $Pair[1])
        }

        return $KeyValue
    }
}

<#
    .SYNOPSIS
    文字列を最適化する。

    .DESCRIPTION
    文字列の前後にあるホワイトスペースを除去した後、クォートを解除する。
    クォートの解除は、先頭と末尾がともにダブルクォート、
    またはともにシングルクォートの場合のみ行う。
    
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

Export-ModuleMember -Function Find-Object
Export-ModuleMember -Function Join-Hashtable
Export-ModuleMember -Function New-Hashtable
Export-ModuleMember -Function New-KeyValue
Export-ModuleMember -Function Optimize-String
Export-ModuleMember -Function Test-Array
