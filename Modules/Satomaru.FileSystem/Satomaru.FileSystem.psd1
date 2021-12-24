@{
    RootModule = 'Satomaru.FileSystem.psm1'
    ModuleVersion = '0.0.1.0'
    Author = 'Satomaru'
    PowerShellVersion = '7.0'
    RequiredModules = @('Satomaru.Util')
    FunctionsToExport = @('Find-Item', 'Find-TextItem', 'Get-TextContent')
}
