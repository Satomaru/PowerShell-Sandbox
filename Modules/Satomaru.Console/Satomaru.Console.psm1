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
        [String[]] $Message,
        [String] $Title,
        [MessageBoxButtons] $Buttons,
        [MessageBoxIcon] $Icon
    )

    Process {
        return [MessageBox]::Show(($Message | Out-String), $Title, $Buttons, $Icon)
    }
}

<#
    .SYNOPSIS
    コンソールから選択肢の入力を待ち受けます。

    .DESCRIPTION
    待ち受けメッセージと予め決めている選択肢を表示して、入力を待ち受けます。
    予め決めている選択肢以外を入力された場合は、
    再度待ち受けメッセージを表示して入力を待ち受けます。
    
    .PARAMETER Options
    予め決めている選択肢。大文字／小文字は区別しません。
    OrderedDictionaryのキーが選択肢、値が表示名となります。
    
    .PARAMETER Prompt
    待ち受けメッセージの配列。
    配列の各要素の終わりで改行して表示します。
    
    .INPUTS
    なし。

    .OUTPUTS
    [string] 入力された選択肢。

    .EXAMPLE
    Read-Option -Options ([ordered]@{R="再試行"; C="キャンセル"}) -Prompt "処理に失敗しました。"
    
    「処理に失敗しました。」
    「[R]再試行, [C]キャンセル: 」
    という待ち受けメッセージを表示して、"R"または"C"を待ち受けます。
#>
function Read-Option {
    [OutputType([String])]

    Param(
        [Parameter(Mandatory)] [System.Collections.Specialized.OrderedDictionary] $Options,
        [String[]] $Prompt
    )

    Process {
        do {
            $Prompt += ($Options.GetEnumerator() | ForEach-Object { "[{0}]{1}" -f $_.Key,$_.Value }) -join ", "
            [string] $Answer = Read-Host -Prompt ($Prompt | Out-String).Trim("`r","`n")

            foreach ($Key in $Options.Keys) {
                if ($Answer -eq $Key) {
                    return $Key
                }
            }
        } while ($true)
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
                [hashtable] $Option = @{
                    Options = [ordered] @{ R = "etry"; C = "ancel" }
                    Prompt = $Exception.Message
                }

                if ((Read-Option @Option) -eq "R") {
                    return $true
                }
            }
        }

        Write-Error -Exception $Exception -ErrorAction $ErrorActionPreference
        return $false
    }
}
