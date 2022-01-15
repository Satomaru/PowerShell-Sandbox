using namespace System.Management.Automation
using namespace System.Collections.Generic

# 引数が、実在するディレクトリのパスであることを検証します。
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

# 引数が、ファイル名として妥当であることを検証します。
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

# ValidateSetに、./Modules/*ディレクトリ名を設定します。
Class ValidateSetDevModules : IValidateSetValuesGenerator {
    [String[]] GetValidValues() {
        return (Get-ChildItem Modules -Directory).Name
    }
}

# ValidateSetに、日本語文字セット名を設定します。
Class ValidateSetJaCharset : IValidateSetValuesGenerator {
    [String[]] GetValidValues() {
        [HashSet[string]] $WebNameSet = [HashSet[string]]::new()
        [void] $WebNameSet.Add([System.Text.Encoding]::Default.WebName)

        foreach ($Charset in "euc-jp", "iso-2022-jp", "shift_jis", "utf-8") {
            try {
                [void] $WebNameSet.Add([System.Text.Encoding]::GetEncoding($Charset).WebName)
            } catch {}
        }

        return $WebNameSet | Sort-Object
    }
}
