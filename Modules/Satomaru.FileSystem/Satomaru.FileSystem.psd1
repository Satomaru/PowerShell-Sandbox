@{
    RootModule = 'Satomaru.FileSystem.psm1'
    ModuleVersion = '1.0.0.0'
    Author = 'Satomaru'
    PowerShellVersion = '7.2'
    RequiredModules = @('Satomaru.Util')
    FunctionsToExport = @('Find-Item', 'Find-TextItem', 'Get-TextContent')
}
