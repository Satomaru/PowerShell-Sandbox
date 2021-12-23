using namespace Microsoft.PowerShell.Commands

class SaveInfo {
    [Uri] $RequestUri
    [string] $ContentType
    [boolean] $AsText
    [System.Text.Encoding] $Encoding
    [string] $FileName
}

function Save-WebResponse {
    [OutputType([object])]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)] [WebResponseObject] $Response,
        [string] $FileName
    )

    Begin {
        [int] $Index = 1
    }    

    Process {
        [ContentTypeInfo] $ContentTypeInfo = [ContentTypeInfo]::new($Response.Headers["Content-Type"])
        [SaveInfo] $Info = [SaveInfo]::new()
        $Info.RequestUri = $Response.BaseResponse.RequestMessage.RequestUri
        $Info.ContentType = $ContentTypeInfo.ContentType
        $Info.AsText = $ContentTypeInfo.AsText
        $Info.Encoding = $ContentTypeInfo.Encoding
        $Info.FileName = ($FileName) ? $FileName : $ContentTypeInfo.GetFileName($Info.RequestUri, "response<n>")

        if ($Info.FileName.Contains("<n>")) {
            $Info.FileName = $Info.FileName.Replace("<n>", $Index++)
        }

        if ($Info.AsText) {
            $Response.Content `
                | Out-String `
                | ForEach-Object { $Info.Encoding.GetBytes($_) } `
                | Set-Content -Path $Info.FileName -AsByteStream
        } else {
            $Response.Content `
                | Set-Content -Path $Info.FileName -AsByteStream
        }

        return $Info
    }
}
