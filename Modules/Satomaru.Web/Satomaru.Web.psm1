using namespace Microsoft.PowerShell.Commands
using namespace System.Management.Automation
using module Satomaru.Validator

[hashtable] $Script:ContentSpecs = @{
    "*/*"                          = @{ AsText = $false; AnyExts = $true;  Exts = @(".dat") }
    "application/gzip"             = @{ AsText = $false; AnyExts = $false; Exts = @(".gz") }
    "application/java-archiver"    = @{ AsText = $false; AnyExts = $false; Exts = @(".jar") }
    "application/javascript"       = @{ AsText = $true;  AnyExts = $false; Exts = @(".js") }
    "application/json"             = @{ AsText = $true;  AnyExts = $false; Exts = @(".json") }
    "application/octet-stream"     = @{ AsText = $false; AnyExts = $true;  Exts = @(".dat") }
    "application/pdf"              = @{ AsText = $false; AnyExts = $false; Exts = @(".pdf") }
    "application/zip"              = @{ AsText = $false; AnyExts = $false; Exts = @(".zip") }
    "audio/mpeg"                   = @{ AsText = $false; AnyExts = $false; Exts = @(".mp3") }
    "audio/wav"                    = @{ AsText = $false; AnyExts = $false; Exts = @(".wav") }
    "image/bmp"                    = @{ AsText = $false; AnyExts = $false; Exts = @(".bmp") }
    "image/gif"                    = @{ AsText = $false; AnyExts = $false; Exts = @(".gif") }
    "image/jpeg"                   = @{ AsText = $false; AnyExts = $false; Exts = @(".jpg", ".jpeg") }
    "image/png"                    = @{ AsText = $false; AnyExts = $false; Exts = @(".png") }
    "image/svg+xml"                = @{ AsText = $true;  AnyExts = $false; Exts = @(".svg") }
    "text/*"                       = @{ AsText = $true;  AnyExts = $true;  Exts = @(".txt") }
    "text/css"                     = @{ AsText = $true;  AnyExts = $false; Exts = @(".css") }
    "text/csv"                     = @{ AsText = $true;  AnyExts = $false; Exts = @(".csv") }
    "text/html"                    = @{ AsText = $true;  AnyExts = $false; Exts = @(".html", ".htm") }
    "text/javascript"              = @{ AsText = $true;  AnyExts = $false; Exts = @(".js"); }
    "text/plain"                   = @{ AsText = $true;  AnyExts = $false; Exts = @(".txt") }
    "video/quicktime"              = @{ AsText = $false; AnyExts = $false; Exts = @(".mov", ".moov", ".qt") }
    "video/mp4"                    = @{ AsText = $false; AnyExts = $false; Exts = @(".mp4") }
    "video/mpeg"                   = @{ AsText = $false; AnyExts = $false; Exts = @(".mpeg", ".mpg", ".mpe", ".mpv") }
    "video/x-msvideo"              = @{ AsText = $false; AnyExts = $false; Exts = @(".avi") }
}

function Get-ContentSpec {
    [OutputType([hashtable])]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)] [WebResponseObject] $Response
    )

    Process {
        [string] $ContentTypeHeader = $Response.Headers["Content-Type"][0]
        [hashtable] $Values = @{}
        [string[]] $Parts = $ContentTypeHeader | Split-Parameter -Values ([ref] $Values)

        [string] $Key = if ($Script:ContentSpecs.ContainsKey($Parts[0])) {
            $Parts[0]
        } elseif ($ContentTypeHeader.StartsWith("text/")) {
            "text/*"
        } else {
            "*/*"
        }

        [hashtable] $Item = $Script:ContentSpecs[$Key]

        return @{
            RequestUri = $Response.BaseResponse.RequestMessage.RequestUri
            ContentTypeHeader = $ContentTypeHeader
            Type = $Parts[0]
            AsText = $Item.AsText
            Charset = $Values.charset
            AnyExts = $Item.AnyExts
            Exts = $Item.Exts
        }
    }
}

function Resolve-LocalName {
    [OutputType([string])]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)] [WebResponseObject] $Response,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [string] $BaseNameWhenEmpty
    )

    Process {
        [hashtable] $ContentSpec = $Response | Get-ContentSpec
        [uri] $Uri = $Response.BaseResponse.RequestMessage.RequestUri

        if (-not $Uri.LocalPath) {
            return $BaseNameWhenEmpty + $ContentSpec.Exts[0]
        }

        [string] $FileName = [System.IO.Path]::GetFileName($Uri.LocalPath)

        if (-not $FileName) {
            return $BaseNameWhenEmpty + $ContentSpec.Exts[0]
        }

        [System.IO.FileInfo] $FileInfo = [System.IO.FileInfo]::new($FileName)

        if (-not $FileInfo.Extension) {
            return $FileInfo.BaseName + $ContentSpec.Exts[0]
        }

        if ($ContentSpec.AnyExts -or $ContentSpec.Exts.Contains($FileInfo.Extension)) {
            return $FileInfo.Name
        }

        return $FileInfo.BaseName + $ContentSpec.Exts[0]
    }
}

function Resolve-Encoding {
    [OutputType([System.Text.Encoding])]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)] [WebResponseObject] $Response
    )

    Process {
        [hashtable] $ContentSpec = $Response | Get-ContentSpec

        [System.Text.Encoding] $Encoding = if ($ContentSpec.Charset) {
            [System.Text.Encoding]::GetEncoding($ContentSpec.Charset)
        } elseif ($ContentSpec.Type -eq "text/html") {
            Search-HtmlEncoding -Html $Response.Content
        } elseif ($ContentSpec.Type -eq "text/css") {
            Search-CssEncoding -Css $Response.Content
        }

        return $Encoding ?? $Response.Encoding
    }
}

function Search-HtmlEncoding {
    [OutputType([System.Text.Encoding])]

    Param(
        [Parameter(Mandatory)] [string] $Html
    )

    Process {
        [string] $Target = $Html.ReplaceLineEndings("") -replace "<script.+?</script>", ""

        foreach ($Element in $Target -split ">.*?<") {
            if ($Element -match "meta.+content-type") {
                if ($Element -match "charset\s*=\s*(?<charset>[\w-]+)") {
                    return [System.Text.Encoding]::GetEncoding($Matches["charset"])
                }
            }
        }
    }
}

function Search-CssEncoding {
    [OutputType([System.Text.Encoding])]

    Param(
        [Parameter(Mandatory)] [string] $Css
    )

    Process {
        foreach ($Element in $Css -split "`r|`r`n") {
            if ($Element -match '^@charset\s+"(?<charset>.+?)"') {
                return [System.Text.Encoding]::GetEncoding($Matches["charset"])
            }
        }
    }
}

<#
    .SYNOPSIS
    Webレスポンスを保存する。

    .DESCRIPTION
    Invoke-WebRequestの結果をファイルに保存する。
    ファイル名は、Webレスポンスの内容から決定される。
    テキストファイルの場合は、オリジナルの文字セットでエンコードされる。
    
    .PARAMETER Response
    保存するWebレスポンス。
    
    .PARAMETER BaseName
    保存するファイル名のベース名に使用される。
    なお "{n}" は、パイプラインのループ回数に置換される。
    
    .PARAMETER Directory
    ファイルを保存するディレクトリを指定する。
    
    .PARAMETER NamingFromUri
    指定すると、リクエストURIからファイル名が作成される。
    リクエストURIが末端 (Leaf) でない場合は、BaseName が使用される。
    また、リクエストURIが拡張子を持たない、またはコンテントタイプにふさわしくない拡張子の場合は、
    コンテントタイプにふさわしい拡張子が代わりに使用される。

    .INPUTS
    保存するWebレスポンス。

    .OUTPUTS
    保存情報。

    - RequestUri:  リクエストURI
    - ContentType: Content-Type ヘッダー
    - FileName:    保存したファイル名
    - AsText:      テキストとして保存した場合は $true
    - Encoding:    テキストとして保存した場合は、使用したエンコード

    .EXAMPLE
    Invoke-WebRequest "https://placeimg.com/800/600/any.jpg" | Save-WebResponse -Directory work -NamingFromUri -Overwrite

    .\work\any.jpg が作成される。既に存在する場合は上書きされる。

    .EXAMPLE
    Invoke-WebRequest google.com | Save-WebResponse -BaseName index -Directory work -ErrorAction Stop

    .\index.html が作成される。既に存在する場合は、例外が発生して処理が停止する。
#>
function Save-WebResponse {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact="Low")]
    [OutputType([hashtable])]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)] [WebResponseObject] $Response,
        [ValidateNotNullOrEmpty()] [ValidateFileName()] [string] $BaseName = "response{n}",
        [ValidateNotNullOrEmpty()] [ValidateDirectory()] [string] $Directory = ".",
        [switch] $NamingFromUri
    )

    Begin {
        [int] $ResponseIndex = 1
        $Directory = Resolve-Path -LiteralPath $Directory
    }

    Process {
        [hashtable] $ContentSpec = $Response | Get-ContentSpec

        [hashtable] $Info = @{
            RequestUri = $ContentSpec.RequestUri
            ContentType = $ContentSpec.ContentTypeHeader
            FileName = ""
            AsText = $ContentSpec.AsText
            Encoding = $Response | Resolve-Encoding
        }

        $Info.FileName = if ($NamingFromUri) {
            $Response | Resolve-LocalName -BaseNameWhenEmpty $BaseName
        } else {
            $BaseName + $ContentSpec.Exts[0]
        }

        if ($Info.FileName.Contains("{n}")) {
            $Info.FileName = $Info.FileName.Replace("{n}", $ResponseIndex++)
        }

        $Info.FileName = [System.IO.Path]::Combine($Directory, $Info.FileName)

        do {
            [boolean] $Retry = $false

            try {
                if ($Info.AsText) {
                    $Response.Content `
                        | Out-String `
                        | ForEach-Object { $Info.Encoding.GetBytes($_) } `
                        | Set-Content -Path $Info.FileName -AsByteStream -ErrorAction Stop
                } else {
                    $Response.Content `
                        | Set-Content -Path $Info.FileName -AsByteStream -ErrorAction Stop
                }

                return $Info
            } catch {
                $Retry = Confirm-Exception -Exception $_.Exception -Retriable
            }
        } while ($Retry)
    }
}
