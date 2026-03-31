# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SHENZHEN I/O（Steam版パズルゲーム）の日本語化MOD。[birdManIkioiShota/SHENZHEN_IO_JP](https://github.com/birdManIkioiShota/SHENZHEN_IO_JP) のフォークで、オリジナルの翻訳データを保持しつつ WiX v6 ベースの MSI インストーラーを追加したもの。

## Build

```bash
cd installer
dotnet build MsiPackage/MsiPackage.wixproj -c Release
```

出力: `installer/MsiPackage/bin/Release/ja-JP/MsiPackage.msi`

必要ツール: .NET SDK, WiX Toolset v6 dotnet tool (`dotnet tool install -g wix`), WixToolset.Dtf.CustomAction NuGet パッケージ

## Architecture

### `installer/CustomAction/` (C# net472 クラスライブラリ)
WiX カスタムアクション DLL。MSI のインストール/アンインストール時に実行されるロジック:
- **FindGameDirectory** (immediate CA): Steam の `libraryfolders.vdf` を解析してゲームディレクトリを自動検出し、`GAMEDIR` / `USERDOCS` プロパティを設定
- **InstallMod** (immediate CA): 埋め込みリソースからMODファイルを展開し、ゲームの Content ディレクトリにコピー。EXE バイナリパッチ（1バイト: オフセット `0x04138A`, `0x3A`→`0x2D`）で言語ラベルを「汉语」→「日本語」に変更。`config.cfg` の Language を English→Chinese に変更
- **UninstallMod** (immediate CA): バックアップ（`Documents/My Games/SHENZHEN IO/.jp-mod-backup/`）から全ファイルを復元し、config を戻す

MODファイル（124個）は `<EmbeddedResource>` としてDLLに同梱。`Assembly.GetManifestResourceStream()` で実行時に抽出。リソース名→ファイルパス変換は `ResourceNameToPath()` で行う。

### `installer/MsiPackage/` (WiX v6 SDK プロジェクト)
MSI パッケージ定義:
- `Package.wxs` — パッケージ定義、カスタムアクションのスケジューリング、WixUI_Minimal
- `Package.ja-JP.wxl` — UI 文字列の日本語ローカライゼーション（ボタン、ダイアログ全て）
- `License.rtf` — 使用許諾（Unicode エスケープで日本語記述）
- perUser スコープ、Codepage 65001（パッケージ）/ 932（ローカライゼーション）

### `mod/` ディレクトリ
ゲームの `Content/` に上書きされる翻訳リソース:
- `strings.csv` — UI文字列の翻訳テーブル
- `descriptions.zh/` — パズルの説明文（44ファイル）
- `messages.zh/` — ゲーム内メッセージ/メール（50+ファイル）
- `textures/editor/` — 日本語化されたエディタUI画像（10ファイル, PNG）

### 日本語化の仕組み
ゲームの中国語（`zh`）ロケールを日本語テキストで上書きする方式。ゲーム側は中国語モードで動作するが、表示される内容は日本語になる。EXEパッチにより設定画面のラベルも「日本語」と正しく表示される。

## Development Notes

- CustomAction は net472 必須（WiX DTF の制約）。`Microsoft.NETFramework.ReferenceAssemblies` NuGet パッケージで .NET Framework SDK 不要でビルド可能
- `CustomAction.config` で .NET 4.0 ランタイムを指定（SfxCA が .NET 2.0 で読み込もうとする問題の回避）
- EXEパッチのオフセットはゲームバージョンに依存するため、Steam更新後に再検証が必要
- MSI の Product Code はビルドごとに自動生成される。UpgradeCode (`8f4e6b2a-3c5d-4e7f-b8a9-1d2e3f4a5b6c`) は固定
