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

function Read-Option {
    [OutputType([String])]

    Param(
        [Parameter(Mandatory)] [ValidateNotNullOrEmpty()] [string[]] $Options,
        [String[]] $Prompt
    )

    Process {
        do {
            [string] $Answer = Read-Host -Prompt ($Prompt | Out-String).Trim("`r","`n")

            if ($Answer -in $Options) {
                return $Answer
            }
        } while ($true)
    }
}

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
                    Options = "R","C"
                    Prompt = $Exception.Message,"[R]etry or [C]ancel?"
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
