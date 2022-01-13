@{
    RootModule = 'Satomaru.Web.psm1'
    ModuleVersion = '1.0.1.3'
    Author = 'Satomaru'
    Description = 'Webアクセスに関する関数群です。'
    PowerShellVersion = '7.2'

    RequiredModules = @(
        'Satomaru.Console',
        'Satomaru.Util',
        'Satomaru.Definition'
    )

    FunctionsToExport = @(
        'Save-WebResponse'
    )
}
