<#
    .SYNOPSIS
    テキストファイルを抽出します。

    .DESCRIPTION
    テキストファイルを受け取り、 期待する条件に一致することを検査します。
    期待する条件に一致する場合は、そのまま返却します。

    .PARAMETER Item
    テキストファイル。

    .PARAMETER ContentMatch
    内容が、指定した正規表現に一致することを期待します。

    .INPUTS
    テキストファイル。

    .OUTPUTS
    [System.IO.FileInfo] 期待する条件に一致する場合は、入力されたテキストファイル。

    .EXAMPLE
    Get-ChildItem -File -Recurse | Find-TextItem -ContentMatch あいうえお

    内容に「あいうえお」が存在するテキストファイルを抽出します。
#>
function Find-TextItem {
    [OutputType([System.IO.FileInfo])]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)] [System.IO.FileInfo] $Item,
        [regex] $ContentMatch
    )

    Process {
        if ($ContentMatch) {
            foreach ($Content in $Item | Get-TextContent) {
                if ($Content -match $ContentMatch) {
                    return $Item
                }
            }
        } else {
            return $Item
        }
    }
}

[System.Text.Encoding] $Script:SHIFT_JIS = [System.Text.Encoding]::GetEncoding(932)
[System.Text.Encoding] $Script:EUC_JP = [System.Text.Encoding]::GetEncoding(20932)
[System.Text.Encoding] $Script:JIS = [System.Text.Encoding]::GetEncoding(50220)
[System.Text.Encoding] $Script:UTF8 = [System.Text.Encoding]::GetEncoding(65001)

<#
    .SYNOPSIS
    テキストファイルの内容を取得します。

    .DESCRIPTION
    JIS、EUC-JP、SHIFT-JIS、UTF-8のテキストファイルを読み込み、その内容を返却します。
    上記以外のファイルは、正しく読むことができません。

    .INPUTS
    JIS、EUC-JP、SHIFT-JIS、UTF-8のいずれかのテキストファイル。

    .OUTPUTS
    [string] テキストファイルの内容。

    .EXAMPLE
    Get-Item -Path .\sample-*.txt | Get-TextContent

    sample-*.txtを読み込みます。
#>
function Get-TextContent {
    [OutputType([string])]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)] [System.IO.FileSystemInfo] $Item
    )

    Process {
        [byte[]] $Bytes = $Item | Get-Content -AsByteStream

        if ($Bytes.Count -eq 0) {
            return ""
        }

        # エンコードした文字列をもう一度デコードして、正しく復元された場合は、正常にエンコードできたとみなす。
        # なお、エンコードを試みる順番は重要で、以下の意味がある。
        # ・JISは、どのエンコーディングでも必ず復元されるので、一番最初に試みる。
        # ・EUC-JPは、SHIFT-JISでも正しく復元されるので、SHIFT-JISよりも先に試みる。

        foreach ($Encoding in @($Script:JIS, $Script:EUC_JP, $Script:SHIFT_JIS, $Script:UTF8)) {
            [string] $Encoded = $Encoding.GetString($Bytes)
            [byte[]] $Actual = $Encoding.GetBytes($Encoded)

            if (Test-Array -Actual ([ref] $Actual) -Expected ([ref] $Bytes)) {
                return $Encoded
            }
        }

        return [System.Text.Encoding]::ASCII.GetString($Bytes)
    }
}
