#Requires -Version 7
using namespace Microsoft.PowerShell.Commands

<#
.SYNOPSIS
    条件に合った項目を抽出する。

.DESCRIPTION
    パイプラインから項目（ファイルやフォルダ）を受け取り、パラメータの内容で検査する。
    検査に合格した場合は、受け取った項目をそのまま返却する。

.PARAMETER ReadOnly
    読み取り専用の項目を抽出する。

.PARAMETER Extension
    指定した拡張子の項目を抽出する。
    拡張子はドット "." で開始する。また、カンマ "," で区切って複数指定できる。

.PARAMETER UpdateBefore
    最終更新日時が指定した値よりも過去の項目を抽出する。

.PARAMETER UpdateAfter
    最終更新日時が指定した値よりも未来の項目を抽出する。

.PARAMETER SmallerThan
    ファイルサイズが指定した値よりも小さい項目を抽出する。

.PARAMETER LargerThan
    ファイルサイズが指定した値よりも大きい項目を抽出する。

.PARAMETER NameMatch
    名前が指定した正規表現に一致する項目を抽出する。

.PARAMETER ContentMatch
    内容が指定した正規表現に一致する項目を抽出する。

.INPUTS
    System.IO.FileSystemInfo

.OUTPUTS
    System.IO.FileSystemInfo

.EXAMPLE
    Get-ChildItem -File -Recurse | Find-Item -Extension .txt, .md -ContentMatch あいうえお
    拡張子が .txt または .md で、かつ内容に「あいうえお」が存在するファイルが抽出される。

.EXAMPLE
    Get-ChildItem -File -Recurse | Find-Item -UpdateAfter 2021/12/22 -LargerThan 5000
    最終更新日時が 2021/12/22 00:00:00 以降で、かつファイルサイズが 5,000 byte よりも大きいファイルが抽出される。
#>
function Find-Item {
    [OutputType([System.IO.FileSystemInfo])]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)] [System.IO.FileSystemInfo] $Item,
        [switch] $ReadOnly,
        [string[]] $Extension,
        [datetime] $UpdateBefore,
        [datetime] $UpdateAfter,
        [long] $SmallerThan,
        [long] $LargerThan,
        [string] $NameMatch,
        [string] $ContentMatch
    )

    Process {
        if ($ReadOnly) {
            if (-not $Item.IsReadOnly) {
                return
            }
        }

        if ($Extension.Count -gt 0) {
            if ($Extension -notcontains $Item.Extension) {
                return
            }
        }

        if ($null -ne $UpdateBefore) {
            if ($UpdateBefore -le $Item.LastWriteTime) {
                return
            }
        } 

        if ($null -ne $UpdateAfter) {
            if ($UpdateAfter -ge $Item.LastWriteTime) {
                return
            }
        } 

        if ($SmallerThan -gt 0) {
            if ($SmallerThan -le $Item.Length) {
                return
            }
        }

        if ($LargerThan -gt 0) {
            if ($LargerThan -ge $Item.Length) {
                return
            }
        }

        if ($NameMatch -ne "") {
            if ($Item.Name -notmatch $NameMatch) {
                return
            }
        }

        if ($ContentMatch -ne "") {
            [boolean] $Hit = $false

            foreach ($Content in $Item | Get-TextContent) {
                if ($Content -match $ContentMatch) {
                    $Hit = $true
                    break
                }
            }

            if (-not $Hit) {
                return
            }
        }

        return $Item
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
    System.IO.FileSystemInfo
    JIS、EUC-JP、SHIFT-JIS、UTF-8のいずれかのテキストファイル。

.OUTPUTS
    string
    テキストファイルの内容。

.EXAMPLE
    Get-ChildItem -Path .\sample-*.txt | Get-TextContent
    sample-*.txtを読み込んで、その内容を表示する。
#>
function Get-TextContent {
    [OutputType([string])]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)] [System.IO.FileSystemInfo] $Item
    )

    Process {
        [byte[]] $Bytes = $Item | Get-Content -AsByteStream

        # エンコードした文字列をもう一度デコードして、正しく復元された場合は、正常にエンコードできたとみなす。
        # なお、エンコードを試みる順番は重要で、以下の意味がある。
        # ・JISは、必ず正しく復元されるので、一番最初に試みる。
        # ・EUC-JPは、SHIFT-JISの場合であっても正しく復元されるので、SHIFT-JISよりも先に試みる。

        foreach ($Encoding in @($Script:JIS, $Script:EUC_JP, $Script:SHIFT_JIS, $Script:UTF8)) {
            [string] $Encoded = $Encoding.GetString($Bytes)
            [byte[]] $Actual = $Encoding.GetBytes($Encoded)

            if ($Actual.Count -eq $Bytes.Count) {
                [boolean] $Hit = $true

                for ($Index = 0; $Index -lt $Actual.Count; $Index++) {
                    if ($Actual[$Index] -ne $Bytes[$Index]) {
                        $Hit = $false
                        break
                    }
                }

                if ($Hit) {
                    return $Encoded
                }
            }
        }

        return [System.Text.Encoding]::ASCII.GetString($Bytes)
    }
}

Export-ModuleMember -Function Find-Item
Export-ModuleMember -Function Get-TextContent
