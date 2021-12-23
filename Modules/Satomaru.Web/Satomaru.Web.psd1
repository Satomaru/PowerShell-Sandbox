@{
    RootModule = 'Satomaru.Web.psm1'
    ModuleVersion = '0.0.1'
    GUID = 'bd0f1df8-f25c-4cea-a0db-cf157d1acd83'
    Author = 'Satomaru'
    PowerShellVersion = '7.0'
    RequiredModules = @('Satomaru.Util')
    ScriptsToProcess = @('ContentTypeInfo.ps1')
    FunctionsToExport = @('Save-WebResponse')
}
