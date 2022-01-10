using namespace System.Management.Automation
using namespace System.Windows.Forms

<#
    .SYNOPSIS
    メッセージボックスを表示します。

    .DESCRIPTION
    System.Windows.Forms.MessageBoxを表示して、クリックされたボタンを返却します。
    メッセージは配列で指定し、各要素の終わりで改行して表示します。
    
    .PARAMETER Message
    メッセージボックスに表示するメッセージ。
    配列の各要素の終わりで改行して表示します。

    .PARAMETER Title
    メッセージボックスのタイトル。

    .PARAMETER Buttons
    メッセージボックスのボタン。

    .PARAMETER Icon
    メッセージボックスのアイコン。

    .INPUTS
    なし。

    .OUTPUTS
    [System.Windows.Forms.DialogResult] クリックされたボタン。

    .EXAMPLE
    Show-MessageBox -Message "以下のファイルを更新します。",".\work\foo.txt" -Title "確認" -Buttons OKCancel -Icon Question

    「？」アイコン、OKボタン、Cancelボタンのメッセージボックスを表示します。
#>
function Show-MessageBox {
    [OutputType([System.Windows.Forms.DialogResult])]

    Param(
        [String[]] $Message = "",
        [String] $Title = "",
        [MessageBoxButtons] $Buttons = [MessageBoxButtons]::OK,
        [MessageBoxIcon] $Icon = [MessageBoxIcon]::None
    )

    Process {
        return [MessageBox]::Show(($Message | Out-String), $Title, $Buttons, $Icon)
    }
}

<#
    .SYNOPSIS
    配列の要素番号を選択します。

    .DESCRIPTION
    コンソールに配列を表示した後、配列の要素番号を待ち受けます。
    正しい要素番号が入力された時は、その要素番号を返却します。

    .PARAMETER Array
    配列。

    .PARAMETER Oneline
    配列を1行で表示します。

    .PARAMETER AbortWhenNot
    存在しない要素番号が入力された場合は中断します。
    
    .INPUTS
    なし。

    .OUTPUTS
    [int] 選択された要素番号。

    .EXAMPLE
    Select-Array @('foo', 'bar', 'baz')

    配列の要素番号(0..2)を待ち受けます。
#>
function Select-Array {
    [OutputType([int])]

    Param(
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [object[]] $Array,
        [switch] $Oneline,
        [switch] $AbortWhenNot
    )

    Process {
        do {
            [string] $Choose = if ($Oneline) {
                [string[]] $Entries = for ([int] $Index = 0; $Index -lt $Array.Length; $Index++) {
                    "[{0}]{1}" -f $Index, $Array[$Index]
                }

                Read-Host -Prompt ($Entries -join ", ")
            } else {
                [object[]] $Entries = for ([int] $Index = 0; $Index -lt $Array.Length; $Index++) {
                    [PSCustomObject] @{ Index = $Index; Value = $Array[$Index] }
                }

                $Entries | Format-Table -Property Index, Value | Out-Host
                Read-Host -Prompt "Input Index"
            }

            if ($Choose -match "^\d+$") {
                [int] $Index = $Choose

                if ($Index -lt $Array.Length) {
                    return $Index
                }
            }
        } while (-not $AbortWhenNot)
    }
}

<#
    .SYNOPSIS
    ディクショナリのキーを選択します。

    .DESCRIPTION
    コンソールにディクショナリを表示した後、
    ディクショナリのキーを待ち受けます。
    正しいキーが入力された時は、そのキーを返却します。

    .PARAMETER Dictionary
    ディクショナリ。

    .PARAMETER Oneline
    ディクショナリを1行で表示します。

    .PARAMETER AbortWhenNot
    存在しないキーが入力された場合は中断します。

    .INPUTS
    なし。

    .OUTPUTS
    [string] 選択されたキー。

    .EXAMPLE
    Select-Dictionary ([ordered]@{R="再試行"; C="キャンセル"}) -Oneline
    
    "R"または"C"を待ち受けます。
#>
function Select-Dictionary {
    [OutputType([string])]

    Param(
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [System.Collections.Specialized.OrderedDictionary] $Dictionary,
        [switch] $Oneline,
        [switch] $AbortWhenNot
    )

    Process {
        do {
            [string] $Choose = if ($Oneline) {
                [string[]] $Entries = $Dictionary.GetEnumerator() | ForEach-Object { "[{0}]{1}" -f $_.Key, $_.Value }
                Read-Host -Prompt ($Entries -join ", ")
            } else {
                $Dictionary | Out-Host
                Read-Host -Prompt "Input Name"
            }

            if ($Dictionary.Contains($Choose)) {
                return $Choose
            }
        } while (-not $AbortWhenNot)
    }
}

<#
    .SYNOPSIS
    例外メッセージを表示して、再試行するかキャンセルするかを待ち受けます。

    .DESCRIPTION
    ErrorActionパラメータがContinueの時は、
    コンソール（Guiパラメータ指定時はメッセージボックス）に例外メッセージを表示して、
    再試行またはキャンセルの選択を待ち受けます。
    再試行が選択された場合は$trueを返却します。
    キャンセルが選択された場合は、Write-Errorを実行した後、$falseを返却します。

    ErrorActionパラメータがContinue以外の時は、
    再試行またはキャンセルの選択は待ち受けずに、
    指定されたエラーアクションでWrite-Errorを実行し、$falseを返却します。

    .PARAMETER Exception
    再試行またはキャンセルを待ち受ける時に表示する例外。

    .PARAMETER Gui
    指定した場合はメッセージボックスを使用します。
    通常はコンソールを使用します。
    
    .INPUTS
    なし。

    .OUTPUTS
    [boolean] 再試行が選択された場合は$true。

    .EXAMPLE
    Confirm-Exception -Exception $_.Exception
    
    例外のメッセージをコンソールに表示して、
    再試行またはキャンセルの選択を待ち受けます。
#>
function Confirm-Exception {
    [CmdletBinding()]
    [OutputType([boolean])]

    Param(
        [Parameter(Mandatory)] [System.Exception] $Exception,
        [switch] $Gui
    )

    Process {
        if ($ErrorActionPreference -eq [ActionPreference]::Continue) {
            if ($Gui) {
                [hashtable] $MessageBox = @{
                    Message = $Exception.Message,"Do you want to retry?"
                    Title = "Exception"
                    Buttons = [MessageBoxButtons]::RetryCancel
                    Icon = [MessageBoxIcon]::Error
                }

                if ((Show-MessageBox @MessageBox) -eq [DialogResult]::Retry) {
                    return $true
                }
            } else {
                $Dictionary = [ordered] @{ R = "etry"; C = "ancel" }
                Write-Host $Exception.Message

                if ((Select-Dictionary $Dictionary -Oneline) -eq "R") {
                    return $true
                }
            }
        }

        Write-Error -Exception $Exception -ErrorAction $ErrorActionPreference
        return $false
    }
}
