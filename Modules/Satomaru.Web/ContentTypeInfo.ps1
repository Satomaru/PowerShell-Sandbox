[hashtable] $Script:Specs = @{
    "*/*"                          = @{ AsText = $false; Extensions = @(".dat", "*") }
    "application/gzip"             = @{ AsText = $false; Extensions = @(".gz") }
    "application/java-archiver"    = @{ AsText = $false; Extensions = @(".jar") }
    "application/javascript"       = @{ AsText = $true;  Extensions = @(".js"); Charset = "UTF-8" }
    "application/json"             = @{ AsText = $true;  Extensions = @(".json"); Charset = "UTF-8" }
    "application/octet-stream"     = @{ AsText = $false; Extensions = @(".dat", "*") }
    "application/pdf"              = @{ AsText = $false; Extensions = @(".pdf") }
    "application/zip"              = @{ AsText = $false; Extensions = @(".zip") }
    "application/x-gzip"           = @{ AsText = $false; Extensions = @(".gz") }
    "application/x-zip-compressed" = @{ AsText = $false; Extensions = @(".zip") }
    "audio/mpeg"                   = @{ AsText = $false; Extensions = @(".mp3") }
    "audio/wav"                    = @{ AsText = $false; Extensions = @(".wav") }
    "audio/x-mpeg"                 = @{ AsText = $false; Extensions = @(".mp3") }
    "audio/x-wav"                  = @{ AsText = $false; Extensions = @(".wav") }
    "image/bmp"                    = @{ AsText = $false; Extensions = @(".bmp") }
    "image/gif"                    = @{ AsText = $false; Extensions = @(".gif") }
    "image/jpeg"                   = @{ AsText = $false; Extensions = @(".jpg", ".jpeg") }
    "image/png"                    = @{ AsText = $false; Extensions = @(".png") }
    "image/svg+xml"                = @{ AsText = $true;  Extensions = @(".svg"); Charset = "UTF-8" }
    "image/x-bmp"                  = @{ AsText = $false; Extensions = @(".bmp") }
    "image/x-ms-bmp"               = @{ AsText = $false; Extensions = @(".bmp") }
    "image/x-png"                  = @{ AsText = $false; Extensions = @(".png") }
    "text/*"                       = @{ AsText = $true;  Extensions = @(".txt", "*") }
    "text/css"                     = @{ AsText = $true;  Extensions = @(".css") }
    "text/csv"                     = @{ AsText = $true;  Extensions = @(".csv") }
    "text/html"                    = @{ AsText = $true;  Extensions = @(".html", ".htm"); Charset = "UTF-8" }
    "text/javascript"              = @{ AsText = $true;  Extensions = @(".js"); }
    "text/plain"                   = @{ AsText = $true;  Extensions = @(".txt") }
    "video/quicktime"              = @{ AsText = $false; Extensions = @(".mov", ".moov", ".qt") }
    "video/mp4"                    = @{ AsText = $false; Extensions = @(".mp4") }
    "video/mpeg"                   = @{ AsText = $false; Extensions = @(".mpeg") }
    "video/x-mpeg"                 = @{ AsText = $false; Extensions = @(".mpeg", ".mpg", ".mpe", ".mpv") }
    "vide/x-msvideo"               = @{ AsText = $false; Extensions = @(".avi") }
}

class ContentTypeInfo {
    [string] $ContentType
    [boolean] $AsText
    [string[]] $Extentions
    [System.Text.Encoding] $Encoding

    ContentTypeInfo([string] $ContentType) {
        [string[]] $Elements = $ContentType -split ";" | ForEach-Object { $_.Trim() }
        [hashtable] $Spec = $Script:Specs[$Elements[0]] ?? $Script:Specs[$ContentType.StartsWith("text/") ? "text/*" : "*/*"]
        [hashtable] $Attributes = $ContentType | New-Hashtable
        $this.ContentType = $ContentType
        $this.AsText = $Spec.AsText
        $this.Extentions = $Spec.Extensions

        if ($Spec.AsText) {
            $this.Encoding = [System.Text.Encoding]::GetEncoding($Attributes.charset ?? $Spec.Charset ?? "ISO-8859-1")
        }
    }

    [String] GetFileName([Uri] $Uri, [string] $BaseNameWhenEmpty) {
        if ($Uri.LocalPath -eq "") {
            return $BaseNameWhenEmpty + $this.Extentions[0]
        }

        [string] $FileName = [System.IO.Path]::GetFileName($Uri.LocalPath)

        if ($FileName -eq "") {
            return $BaseNameWhenEmpty + $this.Extentions[0]
        }

        [System.IO.FileInfo] $FileInfo = [System.IO.FileInfo]::new($FileName)

        if ($this.Extentions -contains "*" -or $this.Extentions -contains $FileInfo.Extension) {
            return $FileName
        } else {
            return $FileInfo.BaseName + $this.Extentions[0]
        }
    }
}
