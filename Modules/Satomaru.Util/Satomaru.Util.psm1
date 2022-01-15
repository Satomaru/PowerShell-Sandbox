<#
    .SYNOPSIS
    オブジェクトを式に変換します。

    .DESCRIPTION
    オブジェクトを、オブジェクトの内容を表すPowerScriptの式に変換します。
    ただし、全く同一の内容にはなりません。
    
    .PARAMETER Object
    変換するオブジェクト。

    .INPUTS
    変換するオブジェクト。

    .OUTPUTS
    [string] オブジェクトの内容を表すPowerScriptの式。

    .EXAMPLE
    ConvertTo-Expression @{Foo=@(1,2);Bar=@{A=$true;B=$null};Baz="abc"}

    以下の文字列を返却します。
    @{"Baz" = "abc"; "Bar" = @{"A" = $true; "B" = $null}; "Foo" = @(1, 2)}
#>
function ConvertTo-Expression {
    [CmdletBinding()]
    [OutputType([string])]

    Param(
        [Parameter(ValueFromPipeline)] [AllowNull()] [object] $Object
    )

    Process {
        if ($null -eq $Object) {
            return "`$null"
        }

        if ($Object.GetType().IsArray) {
            [string[]] $Elements = $Object | ConvertTo-Expression
            return "@($($Elements -join ", "))"
        }

        if ($Object -is [boolean]) {
            return $Object ? "`$true" : "`$false"
        }

        if ($Object -is [string]) {
            [string] $Escaped = $Object -replace '"', '""'
            return """$Escaped"""
        }

        if ($Object -is [char]) {
            return [string][int] $Object
        }

        if ($Object -is [scriptblock]) {
            return "{$Object}"
        }

        if ($Object -is [hashtable]) {
            [string[]] $Expressions = foreach ($Key in $Object.Keys) {
                [string] $FormattedKey = ConvertTo-Expression $Key
                [string] $FormattedValue = ConvertTo-Expression $Object[$Key]
                "$FormattedKey = $FormattedValue"
            }

            return "@{$($Expressions -join "; ")}"
        }

        [string] $TypeName = $Object.GetType().Name

        if ($TypeName -match "^(\w+)``") {
            $TypeName = $Matches[1]
        }

        if ($TypeName -in "ArrayList", "HashSet", "SortedSet") {
            return ConvertTo-Expression ([object[]] $Object)
        }

        if ($TypeName -in "OrderedDictionary", "SortedList") {
            return ConvertTo-Expression ([hashtable] $Object)
        }

        return [string] $Object
    }
}

<#
    .SYNOPSIS
    オブジェクトを抽出します。

    .DESCRIPTION
    条件に一致したオブジェクトを出力します。

    .PARAMETER Where
    検索条件スクリプトブロック。
    オブジェクトを抽出する時は、$trueを返却してください。

    スクリプトブロック内では、抽出するオブジェクトを$_で参照できます。
    Propertyパラメータを指定した場合は、$_は指定されたプロパティの値です。

    booleanを複数返却した場合は、全て$trueの時にそのオブジェクトを抽出しますが、
    Orパラメータを指定した場合は、いずれかが$trueの時に抽出します。
   
    .PARAMETER Property
    指定した場合は、抽出するオブジェクトからこのプロパティを取得して、検索条件スクリプトブロックに送ります。
    指定しなかった場合は、抽出するオブジェクトそのものを送ります。
   
    .PARAMETER Limit
    抽出する最大個数。

    .PARAMETER Or
    抽出条件の振る舞いを切り替えます。
    詳細は、Whereパラメータを参照してください。

    .PARAMETER Object
    抽出するオブジェクト。

    .INPUTS
    抽出するオブジェクト。

    .OUTPUTS
    [object] 抽出されたオブジェクト。

    .EXAMPLE
    Get-ChildItem | Find-Object { $_.Extension -eq ".ps1"; $_.Length -gt 1500 }

    拡張子が".ps1"、かつファイルサイズが1,500byteより大きいファイルを抽出します。
#>
function Find-Object {
    [CmdletBinding()]
    [OutputType([object])]

    Param(
        [Parameter(Mandatory)] [ValidateNotNull()] [scriptblock] $Where,
        [string] $Property,
        [ValidateRange(1, [int]::MaxValue)] [nullable[int]] $Limit,
        [switch] $Or,
        [Parameter(Mandatory, ValueFromPipeline)] [ValidateNotNull()] [object] $Object
    )

    Begin {
        [int] $Count = 0
    }

    Process {
        if ($null -eq $Limit -or $Count -lt $Limit) {
            [boolean] $Ok = Write-Output $Object | Test-Object -Where $Where -Property $Property -Or:$Or

            if ($Ok) {
                [void] ++$Count
                return $Object
            }
        }
    }
}

<#
    .SYNOPSIS
    配列の最初の要素を取得します。

    .DESCRIPTION
    配列が$nullまたは要素を持たない場合は、$nullを返却します。
    
    .PARAMETER Target
    配列。

    .INPUTS
    配列。

    .OUTPUTS
    [object] 最初の要素。存在しない場合は$null

    .EXAMPLE
    Get-FirstItem @('foo, 'bar')

    fooを返却します。

    .EXAMPLE
    Get-FirstItem $null

    $nullを返却します。
#>
function Get-FirstItem {
    [CmdletBinding()]
    [OutputType([object])]

    Param(
        [object[]] [AllowNull()] $Target
    )

    Process {
        if ($Target.Length -gt 0) {
            return $Target[0]
        }
    }
}

<#
    .SYNOPSIS
    文字列を最適化します。

    .DESCRIPTION
    文字列の前後にあるホワイトスペースを除去した後、クォートを解除します。
    クォートの解除は、先頭と末尾がともにダブルクォート、
    またはともにシングルクォートの場合のみ行います。

    .PARAMETER String
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
    [CmdletBinding()]
    [OutputType([string])]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)] [string] $String
    )

    Process {
        $String = $String.Trim()

        if ($String -match '^"(.*)"$') {
            return $Matches[1]
        } elseif ($String -match "^'(.*)'$") {
            return $Matches[1]
        } else {
            return $String
        }
    }
}

<#
    .SYNOPSIS
    $nullをAutomationNullに変換します。

    .DESCRIPTION
    $nullをAutomationNullに変換することで、
    オブジェクトを安全にパイプラインに流すことができます。
    
    .PARAMETER Object
    オブジェクト。

    .INPUTS
    なし。

    .OUTPUTS
    [object] オブジェクト。オブジェクトが$nullの場合は、AutomationNull。

    .EXAMPLE
    Optimize-Void 1

    1を返却します。

    .EXAMPLE
    Optimize-Void $null

    AutomationNullを返却します。
#>
function Optimize-Void {
    [CmdletBinding()]
    [OutputType([object])]

    Param(
        [object] [AllowNull()] $Target
    )

    Process {
        if ($null -ne $Target) {
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
    [CmdletBinding()]
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
    オブジェクトを検証します。

    .DESCRIPTION
    オブジェクトが条件に一致した場合は$trueを返却します。

    .PARAMETER Where
    条件スクリプトブロック。
    オブジェクトが条件に一致する場合は$trueを返却してください。

    スクリプトブロック内では、検証するオブジェクトを$_で参照できます。
    Propertyパラメータを指定した場合は、$_は指定されたプロパティの値です。

    booleanを複数返却した場合は、全て$trueの時にそのオブジェクトが条件に一致したとみなしますが、
    Orパラメータを指定した場合は、いずれかが$trueの時に一致したとみなします。
   
    .PARAMETER Property
    指定した場合は、検証するオブジェクトからこのプロパティを取得して、条件スクリプトブロックに送ります。
    指定しなかった場合は、検証するオブジェクトそのものを送ります。

    .PARAMETER Or
    条件の振る舞いを切り替えます。
    詳細は、Whereパラメータを参照してください。

    .PARAMETER Object
    検証するオブジェクト。

    .INPUTS
    検証するオブジェクト。

    .OUTPUTS
    [boolean] オブジェクトが条件に一致する場合は$true。

    .EXAMPLE
    Get-Item .\README.md | Test-Object { $_.Length -ge 1000; $_.LastWriteTime -gt "2022/01/01" }

    README.mdのファイルサイズが1,000byte以上、かつ最終更新日が2022/01/01より後の場合は、$trueを返却します。
#>
function Test-Object {
    [CmdletBinding()]
    [OutputType([boolean])]

    Param(
        [Parameter(Mandatory)] [AllowNull()] [scriptblock] $Where,
        [string] $Property,
        [switch] $Or,
        [Parameter(Mandatory, ValueFromPipeline)] [ValidateNotNull()] [object] $Object
    )

    Process {
        if ($null -eq $Where) {
            return $true
        }

        [object] $Target = ($Property -ne "") ? $Object.$Property : $Object

        if ($null -eq $Target) {
            return $false
        }

        [boolean[]] $Test = Write-Output $Target | ForEach-Object $Where

        if ($Test.Length -eq 0) {
            return $false
        }

        if ($Or) {
            return $Test -contains $true
        } else {
            return -not ($Test -contains $false)
        }
    }
}
