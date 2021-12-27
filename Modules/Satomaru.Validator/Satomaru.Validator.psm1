using namespace System.Management.Automation

[string] $Script:FileNamePattern = [System.IO.Path]::GetInvalidFileNameChars() -join "" | ForEach-Object {
    "^[^{0}]+$" -f [regex]::Escape($_)
}

class ValidateDirectory : ValidateEnumeratedArgumentsAttribute {
    [void] ValidateElement([object] $Element) {
        [string] $Actual = $Element

        try {
            if ($Actual) {
                if (-not (Test-Path -LiteralPath $Actual -PathType Container)) {
                    throw [System.ArgumentException]::new("ディレクトリが存在しません。: $Actual")
                }
            }
        } catch {
            throw [ValidationMetadataException]::new($_.Exception)
        }
    }
}

class ValidateFileName : ValidateEnumeratedArgumentsAttribute {
    [void] ValidateElement([object] $Element) {
        [string] $Actual = $Element

        try {
            if ($Actual) {
                if ($Actual -notmatch $Script:FileNamePattern) {
                    throw [System.ArgumentException]::new("ファイル名に不正な文字が使用されています。: $Actual")
                }
            }
        } catch {
            throw [ValidationMetadataException]::new($_.Exception)
        }
    }
}
