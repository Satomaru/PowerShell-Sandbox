using namespace Microsoft.PowerShell.Commands

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

function Save-WebResponse {
    [OutputType([hashtable])]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)] [WebResponseObject] $Response,
        [string] $BaseNameWhenEmpty = "response<n>"
    )

    Begin {
        [int] $ResponseIndex = 1
    }

    Process {
        [hashtable] $ContentSpec = $Response | Get-ContentSpec
        [string] $Charset = $null
        [string] $FileName = $Response | Resolve-LocalName -BaseNameWhenEmpty $BaseNameWhenEmpty

        if ($FileName.Contains("<n>")) {
            $FileName = $FileName.Replace("<n>", $ResponseIndex++)
        }

        if ($ContentSpec.AsText) {
            [System.Text.Encoding] $Encoding = $Response | Resolve-Encoding
            $Charset = $Encoding.WebName

            $Response.Content `
                | Out-String `
                | ForEach-Object { $Encoding.GetBytes($_) } `
                | Set-Content -Path $FileName -AsByteStream
        } else {
            $Response.Content `
                | Set-Content -Path $FileName -AsByteStream
        }

        return @{
            Uri = $Response.BaseResponse.RequestMessage.RequestUri
            ContentType = $ContentSpec.ContentTypeHeader
            FileName = $FileName
            AsText = $ContentSpec.AsText
            Charset = $Charset
        }
    }
}
