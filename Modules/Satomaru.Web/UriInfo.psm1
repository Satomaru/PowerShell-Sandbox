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
        $this.Extension = $this.Extension.StartsWith(".") ? $this.Extension.Substring(1) : $this.Extension
    }

    [string] GetFileNameOrAlter([string] $BaseNameWhenEmpty, [string[]] $Extensions) {
        if ($Extensions -contains $this.Extension) {
            return $this.FileName
        }

        [string] $Alternated = ($this.BaseName -ne "") ? $this.BaseName : $BaseNameWhenEmpty
        return $Alternated + "." + $Extensions[0]
    }
}
