@{
    RootModule = 'Satomaru.Console.psm1'
    ModuleVersion = '1.0.0.0'
    Author = 'Satomaru'
    Description = 'コンソールの入出力に関する関数群です。'
    PowerShellVersion = '7.2'

    RequiredModules = @(
        'Satomaru.Util'
    )

    RequiredAssemblies = @(
        'System.Windows.Forms.dll'
    )

    FunctionsToExport = @(
        'Confirm-Exception',
        'Read-ArrayItem',
        'Read-Option',
        'Show-MessageBox'
    )
}
