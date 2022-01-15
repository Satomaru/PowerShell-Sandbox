# PowerShell-Sandbox
ここは、私、さとまるが **PowerShell v7.2** を勉強するための砂場です。

PowerShellの演習で作成したコードを置いているほか、
Wikiに知り得た事柄を書き留めようと思います。

## 演習で作成したモジュール

### Satomaru.Console
コンソールの入出力に関する関数群です。

| 関数名            | 概要                                                   |
| ----------------- | ------------------------------------------------------ |       
| Confirm-Exception | 例外を表示して、再試行またはキャンセルを待ち受けます。 |
| Select-Array      | 配列の要素番号を選択します。                           |
| Select-Dictionary | ディクショナリのキーを選択します。                     |
| Show-MessageBox   | メッセージボックスを表示します。                       |

### Satomaru.Definition
関数の定義に用いることができるクラス群です。

| クラス名              | 概要                                                       |
| --------------------- | ---------------------------------------------------------- |
| ValidateDirectory     | 引数が、実在するディレクトリのパスであることを検証します。 |
| ValidateFileName      | 引数が、ファイル名として妥当であることを検証します。       |
| ValidateSetDevModules | ValidateSetに、./Modules/*ディレクトリ名を設定します。     |
| ValidateSetJaCharset  | ValidateSetに、日本語文字セット名を設定します。            |

### Satomaru.FileSystem
ファイルに関する関数群です。

| 関数名          | 概要                             |
| --------------- | -------------------------------- |
| Get-TextContent | テキストファイルを読み込みます。 |

### Satomaru.Util
全てのモジュールの土台となるユーティリティです。

| 関数名                   | 概要                                     |
| ------------------------ | ---------------------------------------- |
| ConvertTo-Expression     | オブジェクトを式に変換します。           |
| Find-Object              | オブジェクトを抽出します。               |
| Get-FirstItem            | 配列の最初の要素を取得します。           |
| Optimize-String          | 文字列を最適化します。                   |
| Optimize-Void            | $nullをAutomationNullに変換します。      |
| Split-Parameter          | パラメータ文字列を式毎に分割します。     |
| Test-Object              | オブジェクトを検証します。               |

### Satomaru.Web
Webアクセスに関する関数群です。

| 関数名           | 概要                        |
| ---------------- | --------------------------- |
| Save-WebResponse | Webレスポンスを保存します。 |
