#!/usr/bin/env pwsh
# SHENZHEN I/O 日本語化MOD インストーラー / アンインストーラー
# Usage: powershell -ExecutionPolicy Bypass -File shenzhen-io-jp-installer.ps1

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# ── 定数 ─────────────────────────────────────────────
$ModDir = Join-Path $PSScriptRoot "mod"
$BackupMarker = ".jp-mod-installed"

# EXEパッチ: 言語ラベル「汉语」→「日本語」
# IL内の暗号化文字列参照オフセットを Chinese → Japanese に変更（1バイト）
$ExePatchOffset = 0x04138A
$ExePatchOrigByte = 0x3A  # → decryptString(1549321018) = "汉语"
$ExePatchNewByte  = 0x2D  # → decryptString(1549321005) = "日本語"

# MODが置き換えるファイル一覧（Content/からの相対パス）
$ModFiles = @(
    "strings.csv"
    # descriptions.zh/
    "descriptions.zh/amplifier.txt"
    "descriptions.zh/animated-sign.txt"
    "descriptions.zh/bartender.txt"
    "descriptions.zh/cat-feeder.txt"
    "descriptions.zh/chronometer.txt"
    "descriptions.zh/cleaning-robot.txt"
    "descriptions.zh/cold-storage.txt"
    "descriptions.zh/comm-badge.txt"
    "descriptions.zh/computer-interface.txt"
    "descriptions.zh/cryptocurrency.txt"
    "descriptions.zh/deep-sea-sensor.txt"
    "descriptions.zh/delay-module.txt"
    "descriptions.zh/electronic-lock.txt"
    "descriptions.zh/food-scale.txt"
    "descriptions.zh/game-controller.txt"
    "descriptions.zh/harvesting-robot-hard.txt"
    "descriptions.zh/harvesting-robot.txt"
    "descriptions.zh/haunted-doll.txt"
    "descriptions.zh/infrared-sensor.txt"
    "descriptions.zh/laser-tag.txt"
    "descriptions.zh/logic-board.txt"
    "descriptions.zh/meat-printer.txt"
    "descriptions.zh/pocket-i-ching.txt"
    "descriptions.zh/practice-target.txt"
    "descriptions.zh/pulse-generator.txt"
    "descriptions.zh/reactor-status.txt"
    "descriptions.zh/remote-kill-switch.txt"
    "descriptions.zh/sandwich-robot-hard.txt"
    "descriptions.zh/sandwich-robot.txt"
    "descriptions.zh/scaffold-printer.txt"
    "descriptions.zh/scorekeeper.txt"
    "descriptions.zh/security-camera.txt"
    "descriptions.zh/shoes.txt"
    "descriptions.zh/sliding-window.txt"
    "descriptions.zh/smart-grid.txt"
    "descriptions.zh/spoiler-blocker.txt"
    "descriptions.zh/sushi-robot.txt"
    "descriptions.zh/targeting-laser.txt"
    "descriptions.zh/token-machine.txt"
    "descriptions.zh/trailer.txt"
    "descriptions.zh/unknown-device.txt"
    "descriptions.zh/vape-pen.txt"
    "descriptions.zh/vehicle-signal.txt"
    "descriptions.zh/virtual-reality-buzzer.txt"
    # messages.zh/
    "messages.zh/amplifier.txt"
    "messages.zh/animated-sign.txt"
    "messages.zh/bartender.txt"
    "messages.zh/carls-letter.txt"
    "messages.zh/cat-feeder.txt"
    "messages.zh/chronometer.txt"
    "messages.zh/cleaning-robot.txt"
    "messages.zh/cold-storage.txt"
    "messages.zh/comm-badge.txt"
    "messages.zh/company-growth.txt"
    "messages.zh/computer-interface.txt"
    "messages.zh/cool-dad.txt"
    "messages.zh/cryptocurrency.txt"
    "messages.zh/custom-specs.txt"
    "messages.zh/deep-sea-sensor.txt"
    "messages.zh/delay-module.txt"
    "messages.zh/electronic-lock.txt"
    "messages.zh/events-calendar.txt"
    "messages.zh/final-step.txt"
    "messages.zh/food-scale.txt"
    "messages.zh/game-controller.txt"
    "messages.zh/getting-started.txt"
    "messages.zh/harvesting-robot.txt"
    "messages.zh/haunted-doll.txt"
    "messages.zh/infrared-sensor.txt"
    "messages.zh/invitation.txt"
    "messages.zh/laser-tag.txt"
    "messages.zh/logic-board.txt"
    "messages.zh/meat-printer.txt"
    "messages.zh/parts-1.txt"
    "messages.zh/parts-5.txt"
    "messages.zh/pocket-i-ching.txt"
    "messages.zh/practice-target.txt"
    "messages.zh/prototyping-area.txt"
    "messages.zh/pulse-generator.txt"
    "messages.zh/reactor-status.txt"
    "messages.zh/read-the-manual.txt"
    "messages.zh/remote-kill-switch.txt"
    "messages.zh/sandwich-robot.txt"
    "messages.zh/scaffold-printer.txt"
    "messages.zh/scorekeeper.txt"
    "messages.zh/security-camera.txt"
    "messages.zh/shenzhen-days-1.txt"
    "messages.zh/shenzhen-days-2.txt"
    "messages.zh/shenzhen-days-3.txt"
    "messages.zh/shenzhen-days-4.txt"
    "messages.zh/shenzhen-days-5.txt"
    "messages.zh/shenzhen-days-6.txt"
    "messages.zh/shoes.txt"
    "messages.zh/sliding-window.txt"
    "messages.zh/smart-grid.txt"
    "messages.zh/solitaire.txt"
    "messages.zh/spam-1.txt"
    "messages.zh/spam-2.txt"
    "messages.zh/spam-3.txt"
    "messages.zh/spam-4.txt"
    "messages.zh/spam-5.txt"
    "messages.zh/spam-6.txt"
    "messages.zh/spam-7.txt"
    "messages.zh/spoiler-blocker.txt"
    "messages.zh/targeting-laser.txt"
    "messages.zh/token-machine.txt"
    "messages.zh/traffic.txt"
    "messages.zh/undocumented-instruction.txt"
    "messages.zh/unknown-device.txt"
    "messages.zh/vape-pen.txt"
    "messages.zh/vehicle-signal.txt"
    "messages.zh/virtual-reality-buzzer.txt"
    "messages.zh/welcome.txt"
    # textures/editor/
    "textures/editor/playback_icon_forward_pressed_zh.png"
    "textures/editor/playback_icon_forward_solid_pressed_zh.png"
    "textures/editor/playback_icon_forward_solid_zh.png"
    "textures/editor/playback_icon_forward_zh.png"
    "textures/editor/playback_icon_pause_pressed_zh.png"
    "textures/editor/playback_icon_pause_zh.png"
    "textures/editor/playback_icon_reset_pressed_zh.png"
    "textures/editor/playback_icon_reset_zh.png"
    "textures/editor/playback_icon_simulate_pressed_zh.png"
    "textures/editor/playback_icon_simulate_zh.png"
)

# ── 関数 ─────────────────────────────────────────────

function Find-GameDir {
    $candidates = @(
        "C:\Program Files (x86)\Steam\steamapps\common\SHENZHEN IO"
        "C:\Program Files\Steam\steamapps\common\SHENZHEN IO"
        "D:\SteamLibrary\steamapps\common\SHENZHEN IO"
        "E:\SteamLibrary\steamapps\common\SHENZHEN IO"
    )
    # libraryfolders.vdf からも探す
    $vdfPaths = @(
        "C:\Program Files (x86)\Steam\steamapps\libraryfolders.vdf"
        "C:\Program Files\Steam\steamapps\libraryfolders.vdf"
    )
    foreach ($vdf in $vdfPaths) {
        if (Test-Path $vdf) {
            $content = Get-Content $vdf -Raw
            $matches = [regex]::Matches($content, '"path"\s+"([^"]+)"')
            foreach ($m in $matches) {
                $libPath = $m.Groups[1].Value -replace '\\\\', '\'
                $candidate = Join-Path $libPath "steamapps\common\SHENZHEN IO"
                if ($candidate -notin $candidates) {
                    $candidates += $candidate
                }
            }
        }
    }
    foreach ($dir in $candidates) {
        if (Test-Path (Join-Path $dir "Shenzhen.exe")) {
            return $dir
        }
    }
    return $null
}

function Test-ModDir {
    return Test-Path (Join-Path $ModDir "strings.csv")
}

function Get-BackupDir {
    param([string]$GameDir)
    $saveBase = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "My Games\SHENZHEN IO"
    return Join-Path $saveBase ".jp-mod-backup"
}

function Get-ContentDir {
    param([string]$GameDir)
    return Join-Path $GameDir "Content"
}

function Show-Header {
    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "  SHENZHEN I/O 日本語化MOD インストーラー" -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host ""
}

function Test-ModInstalled {
    param([string]$GameDir)
    $backupDir = Get-BackupDir $GameDir
    return Test-Path (Join-Path $backupDir $BackupMarker)
}

function Install-JpMod {
    param([string]$GameDir)

    $contentDir = Get-ContentDir $GameDir
    $backupDir = Get-BackupDir $GameDir

    if (Test-ModInstalled $GameDir) {
        Write-Host "[!] 日本語化MODは既にインストールされています。" -ForegroundColor Yellow
        Write-Host "    アンインストールしてから再インストールしてください。" -ForegroundColor Yellow
        return $false
    }

    Write-Host "[1/4] バックアップを作成中..." -ForegroundColor Green

    # バックアップディレクトリ作成
    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    }

    # 各ファイルのバックアップ
    $backedUp = 0
    foreach ($file in $ModFiles) {
        $src = Join-Path $contentDir $file
        $dst = Join-Path $backupDir $file
        if (Test-Path $src) {
            $dstDir = Split-Path $dst -Parent
            if (-not (Test-Path $dstDir)) {
                New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
            }
            Copy-Item -Path $src -Destination $dst -Force
            $backedUp++
        }
    }
    Write-Host "    $backedUp ファイルをバックアップしました。" -ForegroundColor Gray
    Write-Host "    場所: $backupDir" -ForegroundColor Gray

    Write-Host "[2/4] MODファイルをインストール中..." -ForegroundColor Green

    $installed = 0
    foreach ($file in $ModFiles) {
        $src = Join-Path $ModDir $file
        $dst = Join-Path $contentDir $file
        if (Test-Path $src) {
            $dstDir = Split-Path $dst -Parent
            if (-not (Test-Path $dstDir)) {
                New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
            }
            Copy-Item -Path $src -Destination $dst -Force
            $installed++
        } else {
            Write-Host "    [WARN] MODに見つからないファイル: $file" -ForegroundColor Yellow
        }
    }
    Write-Host "    $installed ファイルをインストールしました。" -ForegroundColor Gray

    Write-Host "[3/4] 言語設定を更新中..." -ForegroundColor Green

    # 全ユーザープロファイルのconfig.cfgを更新
    $saveBase = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "My Games\SHENZHEN IO"
    $configUpdated = 0
    if (Test-Path $saveBase) {
        Get-ChildItem -Path $saveBase -Directory | Where-Object { $_.Name -match '^\d+$' } | ForEach-Object {
            $cfgPath = Join-Path $_.FullName "config.cfg"
            if (Test-Path $cfgPath) {
                $content = Get-Content $cfgPath -Raw
                if ($content -match 'Language\s*=\s*English') {
                    $newContent = $content -replace 'Language\s*=\s*English', 'Language = Chinese'
                    Set-Content -Path $cfgPath -Value $newContent -NoNewline
                    $configUpdated++
                    Write-Host "    config.cfg を更新: $cfgPath" -ForegroundColor Gray
                }
            }
        }
    }

    # EXEパッチ: 言語ラベル「汉语」→「日本語」
    Write-Host "[4/4] EXEパッチを適用中（言語ラベル: 汉语 → 日本語）..." -ForegroundColor Green
    $exePath = Join-Path $GameDir "Shenzhen.exe"
    $exeBackupPath = Join-Path $backupDir "Shenzhen.exe"
    $exePatched = $false
    try {
        # EXEのバックアップ
        Copy-Item -Path $exePath -Destination $exeBackupPath -Force
        Write-Host "    Shenzhen.exe をバックアップしました。" -ForegroundColor Gray

        $exeBytes = [System.IO.File]::ReadAllBytes($exePath)
        if ($exeBytes[$ExePatchOffset] -eq $ExePatchOrigByte) {
            $exeBytes[$ExePatchOffset] = $ExePatchNewByte
            [System.IO.File]::WriteAllBytes($exePath, $exeBytes)
            $exePatched = $true
            Write-Host "    言語ラベルを「日本語」に変更しました。" -ForegroundColor Gray
        } else {
            Write-Host "    [SKIP] EXEが想定と異なります（既にパッチ済み or バージョン違い）。" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "    [WARN] EXEパッチに失敗しました: $_" -ForegroundColor Yellow
        Write-Host "    ゲーム自体は正常に日本語化されています。" -ForegroundColor Yellow
    }

    # マーカーファイル作成
    $marker = @{
        InstalledAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        ModSource   = $ModDir
        FileCount   = $installed
        ExePatched  = $exePatched
    } | ConvertTo-Json
    Set-Content -Path (Join-Path $backupDir $BackupMarker) -Value $marker

    Write-Host ""
    Write-Host "==============================" -ForegroundColor Green
    Write-Host "  インストール完了!" -ForegroundColor Green
    Write-Host "==============================" -ForegroundColor Green
    Write-Host ""
    Write-Host "ゲームを起動すると日本語化されています。" -ForegroundColor White
    if ($exePatched) {
        Write-Host "言語ラベルも「日本語」に変更済みです。" -ForegroundColor White
    } else {
        Write-Host "コントロールパネルで「汉语」を選択してください。" -ForegroundColor White
    }
    Write-Host ""
    return $true
}

function Uninstall-JpMod {
    param([string]$GameDir)

    $contentDir = Get-ContentDir $GameDir
    $backupDir = Get-BackupDir $GameDir

    if (-not (Test-ModInstalled $GameDir)) {
        Write-Host "[!] 日本語化MODはインストールされていません。" -ForegroundColor Yellow
        return $false
    }

    Write-Host "[1/4] バックアップからファイルを復元中..." -ForegroundColor Green

    $restored = 0
    foreach ($file in $ModFiles) {
        $src = Join-Path $backupDir $file
        $dst = Join-Path $contentDir $file
        if (Test-Path $src) {
            Copy-Item -Path $src -Destination $dst -Force
            $restored++
        }
    }
    Write-Host "    $restored ファイルを復元しました。" -ForegroundColor Gray

    Write-Host "[2/4] EXEを復元中..." -ForegroundColor Green
    $exeBackupPath = Join-Path $backupDir "Shenzhen.exe"
    $exePath = Join-Path $GameDir "Shenzhen.exe"
    if (Test-Path $exeBackupPath) {
        try {
            Copy-Item -Path $exeBackupPath -Destination $exePath -Force
            Write-Host "    Shenzhen.exe を復元しました。" -ForegroundColor Gray
        } catch {
            Write-Host "    [WARN] EXE復元に失敗: $_" -ForegroundColor Yellow
            Write-Host "    Steamの「ゲームファイルの整合性を確認」で復元できます。" -ForegroundColor Yellow
        }
    }

    Write-Host "[3/4] 言語設定を復元中..." -ForegroundColor Green

    $saveBase = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "My Games\SHENZHEN IO"
    if (Test-Path $saveBase) {
        Get-ChildItem -Path $saveBase -Directory | Where-Object { $_.Name -match '^\d+$' } | ForEach-Object {
            $cfgPath = Join-Path $_.FullName "config.cfg"
            if (Test-Path $cfgPath) {
                $content = Get-Content $cfgPath -Raw
                if ($content -match 'Language\s*=\s*Chinese') {
                    $newContent = $content -replace 'Language\s*=\s*Chinese', 'Language = English'
                    Set-Content -Path $cfgPath -Value $newContent -NoNewline
                    Write-Host "    config.cfg を復元: $cfgPath" -ForegroundColor Gray
                }
            }
        }
    }

    Write-Host "[4/4] バックアップを削除中..." -ForegroundColor Green

    Remove-Item -Path $backupDir -Recurse -Force
    Write-Host "    バックアップを削除しました。" -ForegroundColor Gray

    Write-Host ""
    Write-Host "==============================" -ForegroundColor Green
    Write-Host "  アンインストール完了!" -ForegroundColor Green
    Write-Host "==============================" -ForegroundColor Green
    Write-Host ""
    Write-Host "オリジナルの中国語ファイルが復元されました。" -ForegroundColor White
    Write-Host ""
    return $true
}

function Show-Status {
    param([string]$GameDir)
    $isInstalled = Test-ModInstalled $GameDir
    if ($isInstalled) {
        $markerPath = Join-Path (Get-BackupDir $GameDir) $BackupMarker
        $info = Get-Content $markerPath -Raw | ConvertFrom-Json
        Write-Host "  状態: インストール済み" -ForegroundColor Green
        Write-Host "  日時: $($info.InstalledAt)" -ForegroundColor Gray
    } else {
        Write-Host "  状態: 未インストール" -ForegroundColor Yellow
    }
}

# ── メイン ────────────────────────────────────────────

Show-Header

# ゲームディレクトリ検出
$gameDir = Find-GameDir
if (-not $gameDir) {
    Write-Host "[ERROR] SHENZHEN I/O のインストール先が見つかりません。" -ForegroundColor Red
    Write-Host "Steamでゲームがインストールされているか確認してください。" -ForegroundColor Red
    Read-Host "Enterキーで終了"
    exit 1
}
Write-Host "  ゲーム: $gameDir" -ForegroundColor Gray
Show-Status $gameDir

# ゲーム実行チェック
$gameProc = Get-Process -Name "Shenzhen" -ErrorAction SilentlyContinue
if ($gameProc) {
    Write-Host ""
    Write-Host "  [!] SHENZHEN I/O が実行中です。" -ForegroundColor Red
    Write-Host "      ゲームを終了してから再実行してください。" -ForegroundColor Red
    Read-Host "Enterキーで終了"
    exit 1
}
Write-Host ""

# メニュー
Write-Host "  [1] インストール（日本語化）"
Write-Host "  [2] アンインストール（元に戻す）"
Write-Host "  [3] 終了"
Write-Host ""
$choice = Read-Host "選択してください (1/2/3)"

switch ($choice) {
    "1" {
        Write-Host ""
        if (-not (Test-ModDir)) {
            Write-Host "[ERROR] mod/ ディレクトリが見つかりません。" -ForegroundColor Red
            Write-Host "        スクリプトと同じフォルダに mod/ を配置してください。" -ForegroundColor Red
            Read-Host "Enterキーで終了"
            exit 1
        }
        Install-JpMod $gameDir
    }
    "2" {
        Write-Host ""
        Uninstall-JpMod $gameDir
    }
    "3" {
        Write-Host "終了します。"
        exit 0
    }
    default {
        Write-Host "無効な選択です。" -ForegroundColor Red
    }
}

Read-Host "Enterキーで終了"
