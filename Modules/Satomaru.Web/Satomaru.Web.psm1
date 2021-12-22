#Requires -Version 7
#Requires -Modules Satomaru.Util
using namespace Microsoft.PowerShell.Commands

$Script:Specs = @{
    "*/*"                          = @{ AsText = $false; Extensions = @("dat", "*");                  Charset = "ISO-8859-1" }
    "application/gzip"             = @{ AsText = $false; Extensions = @("gz");                        Charset = "ISO-8859-1" }
    "application/java-archiver"    = @{ AsText = $false; Extensions = @("jar");                       Charset = "ISO-8859-1" }
    "application/json"             = @{ AsText = $true;  Extensions = @("json");                      Charset = "UTF-8" }
    "application/octet-stream"     = @{ AsText = $false; Extensions = @("dat", "*");                  Charset = "ISO-8859-1" }
    "application/pdf"              = @{ AsText = $false; Extensions = @("pdf");                       Charset = "ISO-8859-1" }
    "application/zip"              = @{ AsText = $false; Extensions = @("zip");                       Charset = "ISO-8859-1" }
    "application/x-gzip"           = @{ AsText = $false; Extensions = @("gz");                        Charset = "ISO-8859-1" }
    "application/x-zip-compressed" = @{ AsText = $false; Extensions = @("zip");                       Charset = "ISO-8859-1" }
    "audio/mpeg"                   = @{ AsText = $false; Extensions = @("mp3");                       Charset = "ISO-8859-1" }
    "audio/wav"                    = @{ AsText = $false; Extensions = @("wav");                       Charset = "ISO-8859-1" }
    "audio/x-mpeg"                 = @{ AsText = $false; Extensions = @("mp3");                       Charset = "ISO-8859-1" }
    "audio/x-wav"                  = @{ AsText = $false; Extensions = @("wav");                       Charset = "ISO-8859-1" }
    "image/bmp"                    = @{ AsText = $false; Extensions = @("bmp");                       Charset = "ISO-8859-1" }
    "image/gif"                    = @{ AsText = $false; Extensions = @("gif");                       Charset = "ISO-8859-1" }
    "image/jpeg"                   = @{ AsText = $false; Extensions = @("jpg", "jpeg");               Charset = "ISO-8859-1" }
    "image/png"                    = @{ AsText = $false; Extensions = @("png");                       Charset = "ISO-8859-1" }
    "image/svg+xml"                = @{ AsText = $true;  Extensions = @("svg");                       Charset = "UTF-8" }
    "image/x-bmp"                  = @{ AsText = $false; Extensions = @("bmp");                       Charset = "ISO-8859-1" }
    "image/x-ms-bmp"               = @{ AsText = $false; Extensions = @("bmp");                       Charset = "ISO-8859-1" }
    "image/x-png"                  = @{ AsText = $false; Extensions = @("png");                       Charset = "ISO-8859-1" }
    "text/*"                       = @{ AsText = $true;  Extensions = @("txt", "*");                  Charset = "ISO-8859-1" }
    "text/css"                     = @{ AsText = $true;  Extensions = @("css");                       Charset = "ISO-8859-1" }
    "text/csv"                     = @{ AsText = $true;  Extensions = @("csv");                       Charset = "ISO-8859-1" }
    "text/html"                    = @{ AsText = $true;  Extensions = @("html", "htm");               Charset = "UTF-8" }
    "text/javascript"              = @{ AsText = $true;  Extensions = @("js");                        Charset = "ISO-8859-1" }
    "text/plain"                   = @{ AsText = $true;  Extensions = @("txt");                       Charset = "ISO-8859-1" }
    "video/quicktime"              = @{ AsText = $true;  Extensions = @("mov", "moov", "qt");         Charset = "ISO-8859-1" }
    "video/mp4"                    = @{ AsText = $false; Extensions = @("mp4");                       Charset = "ISO-8859-1" }
    "video/mpeg"                   = @{ AsText = $false; Extensions = @("mpeg");                      Charset = "ISO-8859-1" }
    "video/x-mpeg"                 = @{ AsText = $false; Extensions = @("mpeg", "mpg", "mpe", "mpv"); Charset = "ISO-8859-1" }
    "vide/x-msvideo"               = @{ AsText = $false; Extensions = @("avi");                       Charset = "ISO-8859-1" }
}

class ContentTypeInfo {
    [string] $ContentType
    [string[]] $Elements
    [hashtable] $Attributes
    [string] $Charset
    [boolean] $AsText
    [string[]] $Extentions

    ContentTypeInfo([string] $ContentType) {
        $this.ContentType = $ContentType
        $this.Elements = ($ContentType -split ";").Trim()
        $this.Attributes = $ContentType | New-Hashtable
        $Spec = $Script:Specs[$this.Elements[0]] ?? $Script:Specs[($ContentType.StartsWith("text/")) ? "text/*" : "*/*"]
        $this.Charset = $this.Attributes.charset ?? $Spec.Charset
        $this.AsText = $Spec.AsText
        $this.Extentions = $Spec.Extensions
    }

    [boolean] MatchExtension([string] $Extension) {
        if ($null -eq $Extension -or $Extension -eq "") {
            return $false
        }

        return $this.Extentions -contains "*" -or $this.Extentions -contains $Extension
    }

    [string] GetExtention() {
        return $this.Extentions[0]
    }
}

class UriInfo {
    [Uri] $Uri
    [string] $FileName
    [string] $BaseName
    [string] $Extension

    UriInfo([Uri] $Uri) {
        $this.Uri = $Uri
        $this.FileName = [System.IO.Path]::GetFileName($Uri.LocalPath)
        $this.BaseName = [System.IO.Path]::GetFileNameWithoutExtension($Uri.LocalPath)
        $this.Extension = [System.IO.Path]::GetExtension($Uri.LocalPath)

        if ($this.Extension.StartsWith(".")) {
            $this.Extension = $this.Extension.Substring(1)
        }
    }

    [string] GetFileNameOrAlter([string] $BaseNameWhenEmpty, [ContentTypeInfo] $ContentTypeInfo) {
        if ($ContentTypeInfo.MatchExtension($this.Extension)) {
            return $this.FileName
        }

        [string] $Alternated = ($this.BaseName -ne "") ? $this.BaseName : $BaseNameWhenEmpty
        return $Alternated + "." + $ContentTypeInfo.GetExtention()
    }
}

class SaveInfo {
    [Uri] $RequestUri
    [string] $ContentType
    [boolean] $AsText
    [string] $Charset
    [string] $FileName
}

function Save-WebResponse {
    [OutputType([object])]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)] [BasicHtmlWebResponseObject] $Response,
        [string] $FileName
    )

    Begin {
        [int] $Index = 1
    }    

    Process {
        [SaveInfo] $Info = [SaveInfo]::new()
        $Info.RequestUri = $Response.BaseResponse.RequestMessage.RequestUri
        $Info.ContentType = $Response.Headers["Content-Type"]
        [ContentTypeInfo] $ContentTypeInfo = [ContentTypeInfo]::new($Info.ContentType)
        $Info.AsText = $ContentTypeInfo.AsText
        $Info.Charset = $ContentTypeInfo.Charset

        $Info.FileName = if ($FileName -ne "") {
            $FileName
        } else {
            [UriInfo]::new($Info.RequestUri).GetFileNameOrAlter("response<n>", $ContentTypeInfo)
        }

        if ($Info.FileName.Contains("<n>")) {
            $Info.FileName = $Info.FileName.Replace("<n>", $Index++)
        }

        if ($Info.AsText) {
            $Response.Content `
                | Out-String `
                | ForEach-Object { [System.Text.Encoding]::GetEncoding($Info.Charset).GetBytes($_) }
                | Set-Content -Path $Info.FileName -AsByteStream
        } else {
            $Response.Content `
                | Set-Content -Path $Info.FileName -AsByteStream
        }
    
        return $Info
    }
}

Export-ModuleMember -Function Save-WebResponse
