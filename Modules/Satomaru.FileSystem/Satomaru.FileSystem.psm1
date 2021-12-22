#Requires -Version 7
#Requires -Modules Satomaru.Util
using namespace Microsoft.PowerShell.Commands

<#
    .SYNOPSIS
    項目を抽出する。

    .DESCRIPTION
    パイプラインから項目（ファイルやフォルダ）を受け取って検査を行う。
    検査に合格した場合は、受け取った項目をそのまま返却する。

    .PARAMETER ReadOnly
    読み取り専用であることを期待する。

    .PARAMETER Extension
    指定した拡張子であることを期待する。
    拡張子はドット "." で開始する。また、カンマ "," で区切って複数指定することができる。

    .PARAMETER UpdateBefore
    最終更新日時が指定した値よりも過去であることを期待する。

    .PARAMETER UpdateAfter
    最終更新日時が指定した値よりも未来であることを期待する。

    .PARAMETER SmallerThan
    ファイルサイズが指定した値よりも小さいことを期待する。

    .PARAMETER LargerThan
    ファイルサイズが指定した値よりも大きいことを期待する。

    .PARAMETER NameMatch
    名前が指定した正規表現に一致することを期待する。

    .INPUTS
    検査する項目。

    .OUTPUTS
    検査に合格した場合は、検査した項目。

    .EXAMPLE
    Get-ChildItem -File -Recurse | Find-Item -Extension .txt, .md -LargerThan 5000
    拡張子が .txt または .md で、ファイルサイズが 5,000 byte より大きいファイルを抽出する。
#>
function Find-Item {
    [OutputType([System.IO.FileSystemInfo])]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)] [System.IO.FileSystemInfo] $Item,
        [switch] $ReadOnly,
        [string[]] $Extension,
        [datetime] $UpdateBefore,
        [datetime] $UpdateAfter,
        [object] $SmallerThan,
        [object] $LargerThan,
        [regex] $NameMatch
    )

    Process {
        return $Item `
            | Find-Object -Name IsReadOnly -EQ $ReadOnly `
            | Find-Object -Name Extension -Contains $Extension `
            | Find-Object -Name LastWriteTime -LT $UpdateBefore -GT $UpdateAfter `
            | Find-Object -Name Length -LT $SmallerThan -GT $LargerThan `
            | Find-Object -Name Name -Match $NameMatch
    }
}

<#
    .SYNOPSIS
    テキスト項目を抽出する。

    .DESCRIPTION
    パイプラインからテキストファイルを受け取って検査を行う。
    検査に合格した場合は、受け取った項目をそのまま返却する。

    .PARAMETER ContentMatch
    内容が指定した正規表現に一致する項目を抽出する。

    .INPUTS
    検査する項目。

    .OUTPUTS
    検査に合格した場合は、検査した項目。

    .EXAMPLE
    Get-ChildItem -File -Recurse | Find-TextItem -ContentMatch あいうえお
    内容に「あいうえお」が存在するファイルを抽出する。
#>
function Find-TextItem {
    [OutputType([System.IO.FileSystemInfo])]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)] [System.IO.FileSystemInfo] $Item,
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
    テキストファイルの内容を取得する。

    .DESCRIPTION
    JIS、EUC-JP、SHIFT-JIS、UTF-8のテキストファイルを読み込み、その内容を返却する。
    上記以外のファイルは、正しく読むことができない。

    .INPUTS
    JIS、EUC-JP、SHIFT-JIS、UTF-8のいずれかのテキストファイル。

    .OUTPUTS
    テキストファイルの内容。

    .EXAMPLE
    Get-Item -Path .\sample-*.txt | Get-TextContent
    sample-*.txtを読み込んで、その内容を表示する。
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

Export-ModuleMember -Function Find-Item
Export-ModuleMember -Function Find-TextItem
Export-ModuleMember -Function Get-TextContent
