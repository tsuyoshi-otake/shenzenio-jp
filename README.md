# SHENZHEN I/O 日本語化MOD

[birdManIkioiShota](https://github.com/birdManIkioiShota) 氏による [SHENZHEN_IO_JP](https://github.com/birdManIkioiShota/SHENZHEN_IO_JP) のフォークです。

オリジナルの翻訳データを修正し、**MSI インストーラー**を追加しました。

## オリジナルとの違い

| | オリジナル | このフォーク |
|---|---|---|
| インストール | 手動でファイルをコピー | MSI インストーラーで自動 |
| アンインストール | Steamで整合性チェック or 手動削除 | 「プログラムの追加と削除」から自動復元 |
| 言語ラベル | 「汉语」を選択すると日本語 | **「日本語」と表示** (EXEパッチ) |
| 翻訳品質 | オリジナルのまま | 52件の誤訳・タイポ・未翻訳を修正 |

## 使い方

### 必要なもの

- Steam版 SHENZHEN I/O がインストール済み
- Windows 10/11

### ダウンロード

最新版: **[shenzenio-jp.msi をダウンロード](https://github.com/tsuyoshi-otake/shenzenio-jp/releases/latest/download/shenzenio-jp.msi)**

全バージョン: [Releases ページ](https://github.com/tsuyoshi-otake/shenzenio-jp/releases)

### インストール

1. 上のリンクから `shenzenio-jp.msi` をダウンロード
2. **ゲームを終了した状態で** ダウンロードした MSI をダブルクリック
3. 使用許諾に同意し、「インストール」をクリック
4. セットアップ完了画面が表示されたら「完了」をクリック

インストーラーが自動的に以下を行います:
- Steam のゲームディレクトリを自動検出
- オリジナルファイルのバックアップ作成（`ドキュメント\My Games\SHENZHEN IO\.jp-mod-backup\`）
- 日本語化ファイル (124ファイル) のコピー
- config.cfg の言語設定を変更
- EXEパッチで言語ラベルを「日本語」に修正

### アンインストール

1. 「設定」→「アプリ」→ 検索で「SHENZHEN」と入力
2. 「SHENZHEN I/O 日本語化MOD」の「...」→「アンインストール」をクリック
3. ウィザードに従って削除

または、インストールに使った MSI ファイルをダブルクリック → 「Remove」を選択

アンインストール時にオリジナルファイルが完全に復元されます。

> **Note:** Steamのアップデートで Shenzhen.exe が上書きされた場合、再度インストーラーを実行してください。

## MSI のビルド方法

[.NET SDK](https://dotnet.microsoft.com/) と [WiX Toolset v6](https://wixtoolset.org/) (dotnet tool) が必要です。

```bash
cd installer
dotnet build MsiPackage/MsiPackage.wixproj -c Release
```

出力: `installer/MsiPackage/bin/Release/ja-JP/MsiPackage.msi`

## クレジット

### 翻訳

翻訳のベースは [birdManIkioiShota](https://github.com/birdManIkioiShota) 氏の成果です。本フォークで52件の修正を加えています。

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
