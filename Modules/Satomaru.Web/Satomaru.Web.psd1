@{
    RootModule = 'Satomaru.Web.psm1'
    ModuleVersion = '1.0.1.2'
    Author = 'Satomaru'
    PowerShellVersion = '7.2'
    RequiredModules = @('Satomaru.Console', 'Satomaru.Util', 'Satomaru.Validator')
    FunctionsToExport = @('Save-WebResponse')
}
