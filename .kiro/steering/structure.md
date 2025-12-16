# プロジェクト構造

## ディレクトリ構成

```
power-monitor-mqtt/
├── .git/                    # Gitリポジトリ
├── .kiro/                   # Kiro設定・ステアリング
│   └── steering/            # AIアシスタント用ガイドライン
├── .vscode/                 # Visual Studio Code設定
├── .gitignore               # Git除外ファイル設定
├── LICENSE                  # MITライセンス
├── Makefile                 # ビルド・インストールスクリプト
├── README.md                # プロジェクトドキュメント
├── config.example           # 設定ファイルテンプレート
└── power-monitor-mqtt.sh    # メインスクリプト
```

## ファイル詳細

### メインファイル
- **`power-monitor-mqtt.sh`**: 実行可能なメインスクリプト
  - SAP Power Monitorとの連携
  - MQTTブローカーへのデータ送信
  - 各種実行モード（テスト、単発、継続）

### 設定・ドキュメント
- **`config.example`**: 設定ファイルのテンプレート
  - MQTT接続情報
  - デバイス設定
  - ログ設定
- **`README.md`**: 使用方法・インストール手順
- **`LICENSE`**: MITライセンス条文

### ビルド・開発
- **`Makefile`**: 自動化タスク
  - 依存関係インストール
  - スクリプト配置
  - テスト実行
- **`.gitignore`**: バージョン管理除外設定
  - 設定ファイル（機密情報含む可能性）
  - macOS固有ファイル
  - ログファイル

## インストール後の構造

### ユーザーホームディレクトリ
```
~/.local/bin/
└── power-monitor-mqtt.sh    # インストールされたスクリプト

~/.config/power-monitor-mqtt/
└── config                   # 実際の設定ファイル
```

## 設定ファイル管理
- **開発時**: `config.example`をベースに作成
- **本番時**: `~/.config/power-monitor-mqtt/config`に配置
- **機密情報**: 設定ファイルはGit管理対象外

## ログファイル
- **macOSログシステム**: `/var/log/system.log`等に統合
- **サブシステム**: `jp.rewse.power-monitor`で識別
- **アクセス**: `log`コマンドまたはConsole.appで確認

## 開発時の注意点
- 設定ファイル（`config`）は絶対にコミットしない (MUST NOT)
- 機密情報は`config.example`に含めない (MUST NOT)
- スクリプトは実行権限を持つ (MUST)
- Bashの`set -euo pipefail`でエラーハンドリングを厳密に (SHOULD)

## ファイル命名規則
- **スクリプトファイル**: ハイフン区切り（kebab-case）
- **設定ファイル**: 小文字、拡張子なし
- **ドキュメント**: 大文字始まり（README.md、LICENSE）
- **隠しファイル**: ドット始まり（.gitignore、.vscode/）
