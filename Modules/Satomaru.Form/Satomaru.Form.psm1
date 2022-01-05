using namespace System.Management.Automation
using namespace System.Windows.Forms

function Show-MessageBox {
    [OutputType([string])]

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

function Show-Warning {
    [CmdletBinding()]
    [OutputType([void])]

    Param(
        [String] $Warning
    )

    Process {
        [ActionPreference] $Action = $WarningPreference

        if ($Action -eq [ActionPreference]::Inquire) {
            [hashtable] $MessageBox = @{
                Message = @($Warning, "続行しますか？")
                Title = "警告"
                Buttons = [MessageBoxButtons]::OKCancel
                Icon = [MessageBoxIcon]::Warning
            }

            [string] $Result = Show-MessageBox @MessageBox
            $Action = ($Result -eq "OK") ? [ActionPreference]::Continue : [ActionPreference]::Stop
        }

        Write-Warning -Message $Warning -WarningAction $Action
    }
}

function Show-Exception {
    [CmdletBinding()]
    [OutputType([string])]

    Param(
        [Parameter(Mandatory)] [System.Exception] $Exception,
        [switch] $CanRetry
    )

    Process {
        [ActionPreference] $Action = $ErrorActionPreference

        if ($Action -eq [ActionPreference]::Inquire) {
            [string] $Prompt = $CanRetry ? "再試行しますか？" : "続行しますか？"

            [hashtable] $MessageBox = @{
                Message = @($Exception.Message, $Prompt)
                Title = "例外"
                Buttons = $CanRetry ? [MessageBoxButtons]::AbortRetryIgnore : [MessageBoxButtons]::OKCancel
                Icon = [MessageBoxIcon]::Error
            }

            [string] $Result = Show-MessageBox @MessageBox

            $Action = switch ($Result) {
                "Abort"  { [ActionPreference]::Stop }
                "Cancel" { [ActionPreference]::Stop }
                "Ignore" { [ActionPreference]::Ignore }
                default  { [ActionPreference]::Continue }
            }
        }

        Write-Error -Exception $Exception -ErrorAction $Action

        if ($CanRetry) {
            return $Result
        }
    }
}
