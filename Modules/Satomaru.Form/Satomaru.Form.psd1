@{
    RootModule = 'Satomaru.Form.psm1'
    ModuleVersion = '0.0.1.0'
    Author = 'Satomaru'
    PowerShellVersion = '7.2'
    RequiredAssemblies = @('System.Windows.Forms.dll')
    RequiredModules = @('Satomaru.Util')
    FunctionsToExport = @('Confirm-Exception', 'Read-Option', 'Show-MessageBox')
}
