using namespace System.Management.Automation

class ValidateDirectory : ValidateEnumeratedArgumentsAttribute {
    [void] ValidateElement([object] $Element) {
        [string] $Actual = $Element

        try {
            if ($Actual) {
                if (-not (Test-Path -LiteralPath $Actual -PathType Container)) {
                    throw [System.ArgumentException]::new("ディレクトリが存在しません。: $Element")
                }
            }
        } catch {
            throw [ValidationMetadataException]::new($_.Exception)
        }
    }
}

class ValidateFileName : ValidateEnumeratedArgumentsAttribute {
    [void] ValidateElement([object] $Element) {
        [char[]] $Actual = $Element

        try {
            if ($Actual) {
                [char[]] $Invalids = [System.IO.Path]::GetInvalidFileNameChars()

                foreach ($Char in $Actual) {
                    if ($Char -in $Invalids) {
                        throw [System.ArgumentException]::new("ファイル名に不正な文字が使用されています。: $Element")
                    }
                }
            }
        } catch {
            throw [ValidationMetadataException]::new($_.Exception)
        }
    }
}
