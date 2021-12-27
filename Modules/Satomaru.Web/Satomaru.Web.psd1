@{
    RootModule = 'Satomaru.Web.psm1'
    ModuleVersion = '1.0.1.0'
    Author = 'Satomaru'
    PowerShellVersion = '7.2'
    RequiredModules = @('Satomaru.Util', 'Satomaru.Validator')
    FunctionsToExport = @('Save-WebResponse')
}
