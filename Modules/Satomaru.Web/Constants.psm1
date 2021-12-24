[hashtable] $Script:ContentSpec = @{
    "*/*"                          = @{ AsText = $false;                    AnyExts = $true;  Exts = @(".dat") }
    "application/gzip"             = @{ AsText = $false;                    AnyExts = $false; Exts = @(".gz") }
    "application/java-archiver"    = @{ AsText = $false;                    AnyExts = $false; Exts = @(".jar") }
    "application/javascript"       = @{ AsText = $true;  Charset = "UTF-8"; AnyExts = $false; Exts = @(".js") }
    "application/json"             = @{ AsText = $true;  Charset = "UTF-8"; AnyExts = $false; Exts = @(".json") }
    "application/octet-stream"     = @{ AsText = $false;                    AnyExts = $true;  Exts = @(".dat") }
    "application/pdf"              = @{ AsText = $false;                    AnyExts = $false; Exts = @(".pdf") }
    "application/zip"              = @{ AsText = $false;                    AnyExts = $false; Exts = @(".zip") }
    "application/x-gzip"           = @{ AsText = $false;                    AnyExts = $false; Exts = @(".gz") }
    "application/x-zip-compressed" = @{ AsText = $false;                    AnyExts = $false; Exts = @(".zip") }
    "audio/mpeg"                   = @{ AsText = $false;                    AnyExts = $false; Exts = @(".mp3") }
    "audio/wav"                    = @{ AsText = $false;                    AnyExts = $false; Exts = @(".wav") }
    "audio/x-mpeg"                 = @{ AsText = $false;                    AnyExts = $false; Exts = @(".mp3") }
    "audio/x-wav"                  = @{ AsText = $false;                    AnyExts = $false; Exts = @(".wav") }
    "image/bmp"                    = @{ AsText = $false;                    AnyExts = $false; Exts = @(".bmp") }
    "image/gif"                    = @{ AsText = $false;                    AnyExts = $false; Exts = @(".gif") }
    "image/jpeg"                   = @{ AsText = $false;                    AnyExts = $false; Exts = @(".jpg", ".jpeg") }
    "image/png"                    = @{ AsText = $false;                    AnyExts = $false; Exts = @(".png") }
    "image/svg+xml"                = @{ AsText = $true;  Charset = "UTF-8"; AnyExts = $false; Exts = @(".svg") }
    "image/x-bmp"                  = @{ AsText = $false;                    AnyExts = $false; Exts = @(".bmp") }
    "image/x-ms-bmp"               = @{ AsText = $false;                    AnyExts = $false; Exts = @(".bmp") }
    "image/x-png"                  = @{ AsText = $false;                    AnyExts = $false; Exts = @(".png") }
    "text/*"                       = @{ AsText = $true;                     AnyExts = $true;  Exts = @(".txt") }
    "text/css"                     = @{ AsText = $true;                     AnyExts = $false; Exts = @(".css") }
    "text/csv"                     = @{ AsText = $true;                     AnyExts = $false; Exts = @(".csv") }
    "text/html"                    = @{ AsText = $true;  Charset = "UTF-8"; AnyExts = $false; Exts = @(".html", ".htm") }
    "text/javascript"              = @{ AsText = $true;  Charset = "UTF-8"; AnyExts = $false; Exts = @(".js"); }
    "text/plain"                   = @{ AsText = $true;                     AnyExts = $false; Exts = @(".txt") }
    "video/quicktime"              = @{ AsText = $false;                    AnyExts = $false; Exts = @(".mov", ".moov", ".qt") }
    "video/mp4"                    = @{ AsText = $false;                    AnyExts = $false; Exts = @(".mp4") }
    "video/mpeg"                   = @{ AsText = $false;                    AnyExts = $false; Exts = @(".mpeg") }
    "video/x-mpeg"                 = @{ AsText = $false;                    AnyExts = $false; Exts = @(".mpeg", ".mpg", ".mpe", ".mpv") }
    "vide/x-msvideo"               = @{ AsText = $false;                    AnyExts = $false; Exts = @(".avi") }
}

function Get-ContentSpec {
    [OutputType([hashtable])]

    Param(
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [string] $ContentType
    )

    Process {
        [hashtable] $Values = @{}
        [string[]] $Parts = $ContentType | Split-Parameter -Values ([ref] $Values)

        [string] $Type = if ($Script:ContentSpec.Contains($Parts[0])) {
            $Parts[0]
        } elseif ($ContentType.StartsWith("text/")) {
            "text/*"
        } else {
            "*/*"
        }

        [hashtable] $Spec = $Script:ContentSpec[$Type]
        [string] $Charset = if ($Spec.AsText) { $Values.charset ?? $Spec.Charset }

        return @{
            ContentType = $ContentType
            AsText = $Spec.AsText
            Charset = $Charset
            AnyExts = $Spec.AnyExts
            Exts = $Spec.Exts
        }
    }
}
