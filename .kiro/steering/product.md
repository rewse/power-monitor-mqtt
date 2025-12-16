# プロダクト概要

## 製品名
Power Monitor MQTT Publisher for macOS

## 目的
macOS用のSAP Power Monitorアプリから電力消費データ（W）を取得し、MQTTブローカーに自動送信するスクリプト。

## 主要機能
- SAP Power Monitorからの電力データ取得
- MQTTブローカーへの自動送信
- テストモード、単発実行モード、継続監視モードの提供
- Home Assistantとの統合サポート

## ターゲットユーザー
- macOSユーザー
- IoT/スマートホーム愛好家
- Home Assistantユーザー
- 電力消費監視を行いたい開発者

## ライセンス
MIT License

## 依存関係
- SAP Power Monitor（macOS用電力監視ツール）
- Homebrew
- mosquitto（MQTTクライアント）
- jq（JSONパーサー）

## 配布方法
- GitHubリポジトリ
- 手動インストール
- Makefileによる自動インストール
