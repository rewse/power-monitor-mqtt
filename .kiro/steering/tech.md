# 技術スタック

## 言語・技術
- **メイン言語**: Bash (shell script)
- **設定ファイル**: プレーンテキスト（環境変数形式）
- **データ形式**: JSON
- **プロトコル**: MQTT

## 依存関係・ツール
- **SAP Power Monitor**: 電力データ取得元
- **mosquitto**: MQTTクライアント（`mosquitto_pub`コマンド）
- **jq**: JSONパーサー・プロセッサ
- **Homebrew**: パッケージマネージャー（依存関係インストール用）

## ビルドシステム
- **Makefile**: インストール・セットアップ・テスト用
- 依存関係の自動インストール
- 設定ファイルの自動配置
- スクリプトの`~/.local/bin`への配置

## 共通コマンド

### 開発・テスト
```bash
# 依存関係インストール
make deps

# テストモード実行
make test
./power-monitor-mqtt.sh --test

# 単発実行
./power-monitor-mqtt.sh --once

# 設定確認
./power-monitor-mqtt.sh --config
```

### インストール・セットアップ
```bash
# 自動インストール（推奨）
make install

# 手動設定作成
make setup-config

# アンインストール
make uninstall

# 設定削除
make clean
```

### ログ確認
```bash
# 過去1時間のログ表示
log show --predicate 'subsystem == "jp.rewse.power-monitor"' --last 1h

# リアルタイムログ監視
log stream --predicate 'subsystem == "jp.rewse.power-monitor"'

# デバッグレベル含むログ
log show --predicate 'subsystem == "jp.rewse.power-monitor"' --level debug --last 1h
```

## 設定管理
- **設定ファイル**: `~/.config/power-monitor-mqtt/config`
- **環境変数**: `POWER_MONITOR_MQTT_CONFIG`で設定ファイルパス変更可能
- **設定例**: `config.example`ファイルを参照

## ログシステム
- **macOSログシステム**: `log`コマンド使用
- **サブシステム**: `jp.rewse.power-monitor`
- **カテゴリ**: `mqtt`
- **ログレベル**: info, error, debug

## MQTTトピック構造
```
{TOPIC_PREFIX}/{DEVICE_NAME}/power/current  # 現在の電力消費
{TOPIC_PREFIX}/{DEVICE_NAME}/power/average  # 平均電力消費
{TOPIC_PREFIX}/{DEVICE_NAME}/status         # ステータス情報
```

## エラーハンドリング
- **リトライ機能**: MQTT送信失敗時の指数バックオフ
- **依存関係チェック**: 実行前の必要コマンド確認
- **設定ファイル検証**: 起動時の設定値確認
