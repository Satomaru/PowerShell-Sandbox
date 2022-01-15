using module Satomaru.Definition

<#
    .SYNOPSIS
    テキストファイルを読み込みます。

    .DESCRIPTION
    読み込む行の条件を指定した場合は、条件に一致する行のみ読み込みます。

    .PARAMETER Where
    読み込み条件スクリプトブロック。
    行を読み込む時は、$trueを返却してください。
    スクリプトブロック内では、読みこむ行を$_で参照できます。

    booleanを複数返却した場合は、全て$trueの時にその行を読み込みますが、
    Orパラメータを指定した場合は、いずれかが$trueの時に読み込みます。
   
    .PARAMETER Limit
    読み込む最大行数。

    .PARAMETER Or
    読み込み条件の振る舞いを切り替えます。
    詳細は、Whereパラメータを参照してください。

    .PARAMETER Tail
    末尾行から読み込みます。
    なお、行の順番は逆転しません。

    .PARAMETER Charset
    テキストファイルの文字セット。
    未指定時はデフォルト・エンコーディングを用います。

    .PARAMETER FileInfo
    読み込むテキストファイル。

    .INPUTS
    読み込むテキストファイル。

    .OUTPUTS
    [object] 読み込んだ内容。
        FileInfo: 読み込んだテキストファイル。
        Content:  読み込んだ行。

    .EXAMPLE
    Get-Item .\sample-jis.txt | Get-TextContent -Charset iso-2022-jp

    sample-jis.txtをiso-2022-jp (JIS)として読み込みます。
#>
function Get-TextContent {
    [CmdletBinding()]
    [OutputType([object])]

    Param(
        [scriptblock] $Where,
        [ValidateRange(1, [int]::MaxValue)] [nullable[int]] $Limit,
        [switch] $Or,
        [switch] $Tail,
        [ValidateSet([ValidateSetJaCharset], IgnoreCase = $true)] [string] $Charset,
        [Parameter(Mandatory, ValueFromPipeline)] [System.IO.FileInfo] $FileInfo
    )

    Begin {
        [System.Text.Encoding] $Encoding = if ($Charset -ne "") {
            [System.Text.Encoding]::GetEncoding($Charset)
        } else {
            [System.Text.Encoding]::Default
        }

        if ($null -eq $Limit) {
            $Tail = $false
        }
    }

    Process {
        [System.Collections.ArrayList] $Content = [System.Collections.ArrayList]::new()
        [System.IO.StreamReader] $Reader = [System.IO.StreamReader]::new($FileInfo.OpenRead(), $Encoding)

        try {
            while (-not $Reader.EndOfStream -and ($Tail -or $null -eq $Limit -or $Content.Count -lt $Limit)) {
                [string] $Line = $Reader.ReadLine()
                [boolean] $Ok = Write-Output $Line | Test-Object -Where $Where -Or:$Or

                if ($Ok) {
                    [void] $Content.Add($Line)

                    if ($Tail) {
                        while ($Content.Count -gt $Limit) {
                            $Content.RemoveAt(0)
                        }
                    }
                }
            }
        } finally {
            $Reader.Dispose()
        }

        if ($Content.Count -gt 0) {
            return [PSCustomObject] @{
                FileInfo = $FileInfo
                Content = $Content.ToArray()
            }
        }
    }
}
