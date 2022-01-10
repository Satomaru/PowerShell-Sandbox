@{
    RootModule = 'Satomaru.FileSystem.psm1'
    ModuleVersion = '1.0.0.0'
    Author = 'Satomaru'
    Description = 'ファイルに関する関数群です。'
    PowerShellVersion = '7.2'

    RequiredModules = @(
        'Satomaru.Util'
    )

    FunctionsToExport = @(
        'Find-Item',
        'Find-TextItem',
        'Get-TextContent'
    )
}
