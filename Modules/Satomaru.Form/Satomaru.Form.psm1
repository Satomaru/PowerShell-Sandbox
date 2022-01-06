using namespace System.Management.Automation
using namespace System.Windows.Forms

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

function Confirm-Exception {
    [CmdletBinding()]
    [OutputType([boolean])]

    Param(
        [Parameter(Mandatory)] [System.Exception] $Exception,
        [switch] $Retriable
    )

    Process {
        [ActionPreference] $Action = $ErrorActionPreference

        if ($Action -in @([ActionPreference]::Continue, [ActionPreference]::Inquire)) {
            [DialogResult] $Result = if ($Retriable) {
                Show-MessageBox -Message $Exception.Message,"再試行しますか？" -Title "例外" -Buttons AbortRetryIgnore -Icon Error
            } else {
                Show-MessageBox -Message $Exception.Message,"続行しますか？" -Title "例外" -Buttons OKCancel -Icon Error
            }

            $Action = switch ($Result) {
                ([DialogResult]::Abort)  { [ActionPreference]::Stop }
                ([DialogResult]::Cancel) { [ActionPreference]::Stop }
                ([DialogResult]::Retry)  { return $true }
                default                  { [ActionPreference]::Continue }
            }
        }

        Write-Error -Exception $Exception -ErrorAction $Action
        return $false
    }
}
