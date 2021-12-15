<#
    .SYNOPSIS
    Webリクエストを行って、レスポンスをファイルに保存します。

    .DESCRIPTION
    ！まだ作成途中です!
    レスポンスを保存するファイルは、カレントディレクトリに作成されます。
    ファイル名は、リクエストURLとレスポンスの内容で決定します。
    リクエストURLの末端パスが拡張子を持ち、かつその拡張子がレスポンスの内容にふさわしい場合は、
    リクエストURLの末端パスがファイル名となります。
    そうでない場合は "response.*" というファイル名になります。拡張子は、レスポンスの内容で決定します。
    カレントディレクトリに同名のファイルが既に存在する場合は、上書き保存されます。

    .PARAMETER RequestUrl
    リクエストURL

    .OUTPUTS
    ContentType  レスポンスのContent-Type
    ResponseFile レスポンスを保存したファイル
    Encoding     レスポンスのエンコーディング（テキストの場合）
    AsText       レスポンスをテキストとして保存した場合はTrue (cf. バイナリ)
#>
function Save-WebRequest() {
    Param(
        [Parameter(Mandatory, ValueFromPipeline)][Alias("Url")][string] $RequestUrl
    )

    Invoke-WebRequest -Uri $RequestUrl | % {
        $ContentType = $_.Headers["Content-Type"]

        if ($ContentType -match "^(?<type>[\w+-]+)/(?<subtype>[\w+-]+)") {
            $Type = $Matches.type
            $SubType = $Matches.subtype
        } else {
            throw "Illegal Content-Type: ${ContentType}"
        }

        $Charset = if ($ContentType -match "charset=(?<charset>[\w+-]+)") { $Matches.charset }
        $DefaultCharset = "ISO-8859-1"
        $Extentions = @("dat")
        $AsText = $false

        switch ($Type) {
            "text" {
                $AsText = $true

                switch ($SubType) {
                    "html" { $DefaultCharset = "UTF-8"; $Extentions = @("html", "htm"); break }
                }

                break
            }

            "image" {
                switch ($SubType) {
                    "gif"  { $Extentions = @("gif"); break }
                    "jpeg" { $Extentions = @("jpg", "jpeg"); break }
                    "png"  { $Extentions = @("png"); break }
                }

                break
            }
        }

        $UrlLeaf = ($RequestUrl -split "[?#;]")[0] | Split-Path -Leaf
        $UrlExtension = if ($UrlLeaf -match "\.(?<extension>\w+)$") { $Matches.extension }
        $ResponseFile = if ($Extentions -contains $UrlExtension) { $UrlLeaf } else { "response.$($Extentions[0])" }
        $Encoding = if ($Charset -ne $null) { $Charset } else { $DefaultCharset }

        if ($AsText) {
            $_.Content | Out-String | % { [System.Text.Encoding]::GetEncoding($Encoding).GetBytes($_) } | Set-Content -Path $ResponseFile -Encoding Byte
        } else {
            $_.Content | Set-Content -Path $ResponseFile -Encoding Byte
        }

        @{
            ContentType = $ContentType;
            ResponseFile = $ResponseFile;
            Encoding = $Encoding;
            AsText = $AsText;
        }
    }
}

Export-ModuleMember -Function Save-WebRequest
