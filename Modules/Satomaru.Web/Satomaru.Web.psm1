using module ".\ContentTypeInfo.psm1"
using module ".\UriInfo.psm1"

Import-Module -Name Satomaru.Util

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
        [Parameter(Mandatory, ValueFromPipeline)] [Microsoft.PowerShell.Commands.BasicHtmlWebResponseObject] $Response,
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
            [UriInfo]::new($Info.RequestUri).GetFileNameOrAlter("response<n>", $ContentTypeInfo.Extentions)
        }

        if ($Info.FileName.Contains("<n>")) {
            $Info.FileName = $Info.FileName.Replace("<n>", $Index++)
        }

        if ($Info.AsText) {
            $Response.Content `
                | Out-String `
                | ConvertTo-Bytes -Charset $Info.Charset `
                | Set-Content -Path $Info.FileName -AsByteStream
        } else {
            $Response.Content `
                | Set-Content -Path $Info.FileName -AsByteStream
        }
    
        return $Info
    }
}

Export-ModuleMember -Function Save-WebResponse
