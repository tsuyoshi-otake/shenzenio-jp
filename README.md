# SHENZHEN I/O 日本語化インストーラー

[birdManIkioiShota](https://github.com/birdManIkioiShota) 氏による [SHENZHEN_IO_JP](https://github.com/birdManIkioiShota/SHENZHEN_IO_JP) のフォークです。

オリジナルの翻訳データはそのまま保持し、**インストーラー / アンインストーラー** を追加しました。

## オリジナルとの違い

| | オリジナル | このフォーク |
|---|---|---|
| インストール | 手動でファイルをコピー | インストーラーで自動 |
| アンインストール | Steamで整合性チェック or 手動削除 | アンインストーラーで自動復元 |
| 言語ラベル | 「汉语」を選択すると日本語 | **「日本語」と表示** (EXEパッチ) |

## 使い方

### 必要なもの

- Steam版 SHENZHEN I/O がインストール済み
- PowerShell 5.0 以上（Windows 10/11 標準搭載）

### インストール

1. このリポジトリを [Download ZIP](../../archive/refs/heads/master.zip) またはクローン
2. **ゲームを終了した状態で**、以下を実行:

```powershell
powershell -ExecutionPolicy Bypass -File shenzhen-io-jp-installer.ps1
```

3. メニューで `1` を選択

インストーラーが自動的に以下を行います:
- オリジナルファイルのバックアップ作成
- 日本語化ファイルのコピー
- config.cfg の言語設定を変更
- EXEパッチで言語ラベルを「日本語」に修正

### アンインストール

同じスクリプトを実行し、メニューで `2` を選択するとオリジナルの状態に完全復元されます。

> **Note:** Steamのアップデートで Shenzhen.exe が上書きされた場合、再度インストーラーを実行してください。

## クレジット

### 翻訳

全ての翻訳は [birdManIkioiShota](https://github.com/birdManIkioiShota) 氏の成果です。

### ディベロッパー・パブリッシャーの許諾

オリジナル作者が Zachtronics 様よりメールで日本語化ファイル公開の許諾を得ています:

> **Q:** wanna be allowed to publish Japanese localization file for SHENZHEN I/O
>
> **A:** What you've described here is fine with us.

> **Q:** i need to translate .txt files in Content/descriptions.zh/ and replace some textures in Content/textures/editor too.
>
> **A:** Also fine.

## 注意事項

- 本ファイル導入によるゲームの安定性・安全性を保証できません。自己責任で使用してください。
- 日本語化コミュニティを取り巻く状況は常に変化しています。権利者様の態度や法律の変化によってこのファイルは予告なく変更・削除される可能性があります。

## リンク

- 原作リポジトリ: [birdManIkioiShota/SHENZHEN_IO_JP](https://github.com/birdManIkioiShota/SHENZHEN_IO_JP)
- SHENZHEN I/O 公式: http://www.zachtronics.com/shenzhen-io/
- Steam: https://store.steampowered.com/app/504210/
