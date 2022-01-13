using namespace System.Management.Automation

# 引数が実在するディレクトリのパスであることを検証します。
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

# 引数がファイル名として妥当であることを検証します。
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

# ValidateSetで.\Modules\*ディレクトリを指定可能にします。
Class ValidateSetDevModules : IValidateSetValuesGenerator {
    [String[]] GetValidValues() {
        return Get-ChildItem Modules -Directory | ForEach-Object Name
    }
}
