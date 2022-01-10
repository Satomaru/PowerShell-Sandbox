@{
    RootModule = 'Satomaru.Util.psm1'
    ModuleVersion = '1.0.0.0'
    Author = 'Satomaru'
    Description = '全てのモジュールの土台となるユーティリティです。'
    PowerShellVersion = '7.2'

    FunctionsToExport = @(
        'Find-Object',
        'Get-FirstItem',
        'Optimize-String',
        'Optimize-Void',
        'Split-Parameter',
        'Test-Array'
    )
}
