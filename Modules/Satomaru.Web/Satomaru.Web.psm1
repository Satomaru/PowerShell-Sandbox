using namespace Microsoft.PowerShell.Commands
using namespace System.Management.Automation
using module Satomaru.Definition

<#
    コンテンツ仕様。
        AsText:  テキストとして解釈できる場合は$true。
        AnyExts: どんな拡張子でも許容できる場合は$true。
        Exts:    このコンテンツに妥当である拡張子。
#>
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

<#
    .SYNOPSIS
    コンテンツ仕様を取得します。

    .DESCRIPTION
    Webレスポンスを受け取り、ヘッダーからコンテンツ仕様を解釈します。

    .PARAMETER Response
    Webレスポンス。

    .INPUTS
    Webレスポンス。

    .OUTPUTS
    [hashtable] コンテンツ仕様。
        RequestUri:            リクエストURI。
        ContentLocationHeader: Content-Locationヘッダーの値。
        ContentTypeHeader:     Content-Typeヘッダーの値。
        Type:                  コンテント・タイプ
        AsText:                テキストとして解釈できる場合は$true。
        Charset:               文字セット（ヘッダーに記述があった場合のみ）
        AnyExts:               このコンテンツがどんな拡張子でも許容できる場合は$true。
        Exts:                  このコンテンツに妥当である拡張子。
#>
function Get-ContentSpec {
    [OutputType([hashtable])]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)] [WebResponseObject] $Response
    )

    Process {
        [string] $ContentTypeHeader = Get-FirstItem $Response.Headers["Content-Type"]
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
            ContentLocationHeader = Get-FirstItem $Response.Headers["Content-Location"]
            ContentTypeHeader = $ContentTypeHeader
            Type = $Parts[0]
            AsText = $Item.AsText
            Charset = $Values.charset
            AnyExts = $Item.AnyExts
            Exts = $Item.Exts
        }
    }
}

<#
    .SYNOPSIS
    Webレスポンスからファイル名を解決します。

    .DESCRIPTION
    Content-Locationヘッダー、またはリクエストURIから、ファイル名を作成して返却します。

    この時、拡張子がない、または拡張子がコンテント・タイプにふさわしくない場合は、
    ふさわしい拡張子に取り替えます。

    Content-Locationヘッダー、またはリクエストURIからベース名を作成できなかった場合は、
    引数の空欄時ベース名を用います。

    .PARAMETER Response
    Webレスポンス。

    .PARAMETER BaseNameWhenEmpty
    空欄時ベース名。ベース名を作成できなかった場合に、ベース名として使用します。

    .INPUTS
    Webレスポンス。

    .OUTPUTS
    Webレスポンスから解決したファイル名。
#>
function Resolve-LocalName {
    [OutputType([string])]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)] [WebResponseObject] $Response,
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [string] $BaseNameWhenEmpty
    )

    Process {
        [hashtable] $ContentSpec = $Response | Get-ContentSpec
        [string] $LocalPath = Optimize-Void $ContentSpec.ContentLocationHeader | Split-Path -Leaf
        $LocalPath ??= $ContentSpec.RequestUri.LocalPath

        if (-not $LocalPath) {
            return $BaseNameWhenEmpty + $ContentSpec.Exts[0]
        }

        [string] $FileName = [System.IO.Path]::GetFileName($LocalPath)

        if (-not $FileName) {
            return $BaseNameWhenEmpty + $ContentSpec.Exts[0]
        }

        [System.IO.FileInfo] $FileInfo = [System.IO.FileInfo]::new($FileName)

        if (-not $FileInfo.Extension) {
            return $FileInfo.BaseName + $ContentSpec.Exts[0]
        }

        if ($ContentSpec.AnyExts -or $FileInfo.Extension -in $ContentSpec.Exts) {
            return $FileInfo.Name
        }

        return $FileInfo.BaseName + $ContentSpec.Exts[0]
    }
}

<#
    .SYNOPSIS
    Webレスポンスからエンコーディングを解決します。

    .DESCRIPTION
    Content-Typeヘッダーに文字セットが記述されている場合は、そのエンコーディングを返却します。
    記述されていない場合は、HTMLおよびCSSの時は、内容から判断します。
    上記以外の場合は、Webレスポンスに格納されているエンコーディングをそのまま返します。

    .PARAMETER Response
    Webレスポンス。

    .INPUTS
    Webレスポンス。

    .OUTPUTS
    Webレスポンスから解決したエンコーディング。
#>
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

<#
    .SYNOPSIS
    HTMLの内容からエンコーディングを判断します。

    .DESCRIPTION
    meta要素を探し出して、指定されている文字セットに該当するエンコーディングを返却します。

    .PARAMETER Response
    Webレスポンス。

    .INPUTS
    Webレスポンス。

    .OUTPUTS
    HTMLの内容から判断されたエンコーディング。
#>
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

            if ($Element -match "meta\s+charset\s*=\s*[""']?(?<charset>[\w-]+)[""']?") {
                return [System.Text.Encoding]::GetEncoding($Matches["charset"])
            }
        }
    }
}

<#
    .SYNOPSIS
    CSSの内容からエンコーディングを判断します。

    .DESCRIPTION
    @charsetを探し出して、指定されている文字セットに該当するエンコーディングを返却します。

    .PARAMETER Response
    Webレスポンス。

    .INPUTS
    Webレスポンス。

    .OUTPUTS
    CSSの内容から判断されたエンコーディング。
#>
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
    Webレスポンスを保存します。

    .DESCRIPTION
    Invoke-WebRequestの結果をファイルに保存します。
    なお、テキストファイルの場合は、原則としてオリジナルの文字セットでエンコードされます。
    
    .PARAMETER Response
    Webレスポンス。
    
    .PARAMETER BaseName
    保存するファイルのベース名に使用されます。
    "{n}"を記述した場合は、パイプラインで処理されるごとに、1,2,3...と置換されます。

    なお、Namingパラメータが指定された場合は、
    まず、Webレスポンスから適切なファイル名を作成することを試みます。
    適切なファイル名が作成できなかった場合は、このパラメータが使用されます。
    
    .PARAMETER Directory
    ファイルを保存するディレクトリ。
    
    .PARAMETER Naming
    Webレスポンスから適切なファイル名を作成することを試みます。
    Content-LocationヘッダーやリクエストURIなどからファイル名を作成しますが、
    作成できなかった場合は、BaseNameパラメータが使用されます。

    .INPUTS
    Webレスポンス。

    .OUTPUTS
    [hashtable] 保存情報。
        RequestUri:  リクエストURI
        ContentType: Content-Type ヘッダー
        FileName:    保存したファイル名
        AsText:      テキストとして保存した場合は $true
        Encoding:    テキストとして保存した場合は、使用したエンコード

    .EXAMPLE
    Invoke-WebRequest "https://placeimg.com/800/600/any.jpg" | Save-WebResponse -Directory work -Naming -Confirm

    .\work\any.jpg が作成されます。
    なお、作成前に確認のプロンプトが表示されます。

    .EXAMPLE
    Invoke-WebRequest google.com | Save-WebResponse -BaseName index -ErrorAction Ignore

    .\index.html が作成されます。
    作成に失敗した場合は、例外を出さずに終了します。
#>
function Save-WebResponse {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact="Low")]
    [OutputType([hashtable])]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)] [WebResponseObject] $Response,
        [ValidateNotNullOrEmpty()] [ValidateFileName()] [string] $BaseName = "response{n}",
        [ValidateNotNullOrEmpty()] [ValidateDirectory()] [string] $Directory = ".",
        [switch] $Naming
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

        $Info.FileName = if ($Naming) {
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
                $Retry = Confirm-Exception -Exception $_.Exception -ErrorAction $ErrorActionPreference
            }
        } while ($Retry)
    }
}
