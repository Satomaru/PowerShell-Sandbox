@{
    RootModule = 'Satomaru.Web.psm1'
    ModuleVersion = '0.0.1.0'
    Author = 'Satomaru'
    PowerShellVersion = '7.0'
    RequiredModules = @('Satomaru.Util')
    NestedModules = @('Constants.psm1')
    FunctionsToExport = @('Save-WebResponse')
}
