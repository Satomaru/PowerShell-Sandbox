Import-Module -Name Satomaru.Util

$Script:Specs = @{
    "image/gif"  = @{ AsText = $false; Extensions = @("gif");         Charset = "ISO-8859-1" }
    "image/jpeg" = @{ AsText = $false; Extensions = @("jpg", "jpeg"); Charset = "ISO-8859-1" }
    "image/png"  = @{ AsText = $false; Extensions = @("png");         Charset = "ISO-8859-1" }
    "text/html"  = @{ AsText = $true;  Extensions = @("html","htm");  Charset = "UTF-8" }
    "text/plain" = @{ AsText = $true;  Extensions = @("txt");         Charset = "ISO-8859-1" }
    "text/*"     = @{ AsText = $true;  Extensions = @("txt");         Charset = "ISO-8859-1" }
    "*/*"        = @{ AsText = $false; Extensions = @("dat");         Charset = "ISO-8859-1" }
}

class ContentTypeInfo {
    [string] $ContentType
    [string[]] $Elements
    [hashtable] $Attributes
    [string] $Charset
    [System.Boolean] $AsText
    [string[]] $Extentions

    ContentTypeInfo([string] $ContentType) {
        $this.ContentType = $ContentType
        $this.Elements = ($ContentType -split ";").Trim()
        $this.Attributes = ConvertTo-Hashtable -Target $ContentType -ED ";" -PS "="
        $Spec = $Script:Specs[$this.Elements[0]] ?? $Script:Specs[($ContentType.StartsWith("text/")) ? "text/*" : "*/*"]
        $this.Charset = $this.Attributes.charset ?? $Spec.Charset
        $this.AsText = $Spec.AsText
        $this.Extentions = $Spec.Extensions
    }
}
