@{
    RootModule = 'Satomaru.Console.psm1'
    ModuleVersion = '1.0.0.0'
    Author = 'Satomaru'
    PowerShellVersion = '7.2'
    RequiredAssemblies = @('System.Windows.Forms.dll')
    RequiredModules = @('Satomaru.Util')
    FunctionsToExport = @('Confirm-Exception', 'Read-Option', 'Show-MessageBox')
}
