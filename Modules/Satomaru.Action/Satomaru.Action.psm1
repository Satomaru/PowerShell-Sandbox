using namespace System.Management.Automation
using namespace System.Windows.Forms

<#
    .SYNOPSIS
    警告を表示する。

    .DESCRIPTION
    WarningAction パラメータによって挙動が異なる。

    - Continue:   コンソールに警告を出力する。
    - Inquire:    OKCancel ダイアログを表示する。
        - OK:     コンソールに警告を出力する。
        - Cancel: コンソールに警告を出力した後、コマンドを中止する。
    - Stop:       コンソールに警告を出力した後、コマンドを中止する。

    .PARAMETER Message
    表示する警告メッセージ。

    .PARAMETER Title
    OKCancel ダイアログのタイトルに使用される。

    .INPUTS
    表示する警告メッセージ。

    .OUTPUTS
    なし。

    .EXAMPLE
    Show-Warning -Message "同名のファイルが既に存在しています。" -WarningAction Inquire

    「同名のファイルが既に存在しています。続行しますか？」という OKCancel ダイアログを表示する。
    さらに、コンソールに「同名のファイルが既に存在しています。」と出力する。

    .EXAMPLE
    Show-Warning -Message "何も処理されませんでした。" -WarningAction Continue

    コンソールに「何も処理されませんでした。」と出力する。
#>
function Show-Warning {
    [OutputType([void])]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)] [ValidateNotNullOrEmpty()] [String] $Message,
        [String] $Title
    )

    Process {
        if ($WarningPreference -eq [ActionPreference]::Inquire) {
            [string] $Confirm = @($Message, "", "続行しますか？") | Out-String
            [DialogResult] $Result = [MessageBox]::Show($Confirm, $Title, [MessageBoxButtons]::OKCancel, [MessageBoxIcon]::Warning)

            if ($Result -eq [DialogResult]::OK) {
                Write-Warning -Message $Message -WarningAction Continue
            } else {
                Write-Warning -Message $Message -WarningAction Stop
            }
        } else {
            Write-Warning -Message $Message -WarningAction $WarningPreference
        }
    }
}

<#
    .SYNOPSIS
    例外を表示する。

    .DESCRIPTION
    ErrorAction パラメータによって挙動が異なる。

    - Continue:   コンソールにエラーを出力する。
    - Inquire:    AbortRetryIgnore ダイアログ、または OKCancel ダイアログを表示する。
        - Abort:  コンソールにエラーを出力した後、コマンドを中止する。
        - Retry:  リトライを意味する $true を返却する。
        - Ignore: コンソールにエラーを出力する。
        - OK:     コンソールにエラーを出力する。
        - Cancel: コンソールにエラーを出力した後、コマンドを中止する。
    - Stop:       コンソールにエラーを出力した後、コマンドを中止する。

    .PARAMETER Exception
    表示する例外。

    .PARAMETER Title
    AbortRetryIgnore ダイアログ、または OKCancel ダイアログのタイトルに使用される。

    .PARAMETER CanRetry
    これを指定した場合、ErrorAction パラメータに Inquire を指定した時は、
    AbortRetryIgnore ダイアログを表示する。

    .INPUTS
    表示するエラーメッセージ。

    .OUTPUTS
    リトライが選択された場合は $true。

    .EXAMPLE
    Show-Exception -Exception $_.Exception -ErrorAction Inquire -CanRetry

    「<<例外メッセージ>> 再試行しますか？」という AbortRetryIgnore ダイアログを表示する。
    さらに、Retry 以外が選択された場合は、コンソールに例外メッセージを出力する。

    .EXAMPLE
    Show-Exception -Exception $_.Exception -ErrorAction Continue
    コンソールに例外メッセージを出力する。
#>
function Show-Exception {
    [OutputType([boolean])]

    Param(
        [Parameter(Mandatory, ValueFromPipeline)] [ValidateNotNull()] [System.Exception] $Exception,
        [String] $Title,
        [switch] $CanRetry
    )

    Process {
        if ($ErrorActionPreference -eq [ActionPreference]::Inquire) {
            [string] $Prompt = $CanRetry ? "再試行しますか？" : "続行しますか？"
            [string] $Confirm = @($Exception.Message, "", $Prompt) | Out-String
            [MessageBoxButtons] $Buttons = $CanRetry ? [MessageBoxButtons]::AbortRetryIgnore : [MessageBoxButtons]::OKCancel
            [DialogResult] $Result = [MessageBox]::Show($Confirm, $Title, $Buttons, [MessageBoxIcon]::Exclamation)

            switch ($Result) {
                ([DialogResult]::Ignore) {
                    Write-Error -Exception $Exception -ErrorAction Continue
                }

                ([DialogResult]::Retry) {
                    return $true
                }

                ([DialogResult]::OK) {
                    Write-Error -Exception $Exception -ErrorAction Continue
                }

                default {
                    Write-Error -Exception $Exception -ErrorAction Stop
                }
            }
        } else {
            Write-Error -Exception $Exception -ErrorAction $ErrorActionPreference
        }

        return $false
    }
}
