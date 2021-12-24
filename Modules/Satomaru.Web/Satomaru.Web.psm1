using namespace Microsoft.PowerShell.Commands

function Get-UriLocalName {
    [OutputType([string])]

    Param(
        [Parameter(Mandatory)] [Uri] $Uri,
        [string] $BaseNameWhenEmpty,
        [string[]] $Extensions,
        [boolean] $AllowAnyExts
    )

    Process {
        if (-not $Uri.LocalPath) {
            return $BaseNameWhenEmpty + $Extensions[0]
        }

        [string] $FileName = [System.IO.Path]::GetFileName($Uri.LocalPath)

        if (-not $FileName) {
            return $BaseNameWhenEmpty + $Extensions[0]
        }

        [System.IO.FileInfo] $FileInfo = [System.IO.FileInfo]::new($FileName)

        if (-not $FileInfo.Extension) {
            return $FileInfo.BaseName + $Extensions[0]
        }

        if ($AllowAnyExts -or $Extensions.Contains($FileInfo.Extension)) {
            return $FileInfo.Name
        }

        return $FileInfo.BaseName + $Extensions[0]
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
        [Uri] $Uri = $Response.BaseResponse.RequestMessage.RequestUri
        [string] $ContentType = $Response.Headers["Content-Type"]
        [hashtable] $ContentSpec = Get-ContentSpec -ContentType $ContentType
        [string] $FileName = Get-UriLocalName -Uri $Uri -BaseNameWhenEmpty $BaseNameWhenEmpty -Extensions $ContentSpec.Exts -AllowAnyExts $ContentSpec.AnyExts

        if ($FileName.Contains("<n>")) {
            $FileName = $FileName.Replace("<n>", $ResponseIndex++)
        }

        [string] $Charset = $null

        if ($ContentSpec.AsText) {
            $Charset = $ContentSpec.Charset ?? "ISO-8859-1"
            [System.Text.Encoding] $Encoding = [System.Text.Encoding]::GetEncoding($Charset)

            $Response.Content `
                | Out-String `
                | ForEach-Object { $Encoding.GetBytes($_) } `
                | Set-Content -Path $FileName -AsByteStream
        } else {
            $Response.Content `
                | Set-Content -Path $FileName -AsByteStream
        }

        return @{
            Uri = $Uri
            ContentType = $ContentType
            FileName = $FileName
            AsText = $ContentSpec.AsText
            Charset = $Charset
        }
    }
}
