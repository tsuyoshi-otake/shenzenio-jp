using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Text.RegularExpressions;
using WixToolset.Dtf.WindowsInstaller;

namespace ShenzenIoJpCA
{
    public class GameModActions
    {
        const int ExePatchOffset = 0x04138A;
        const byte ExePatchOrigByte = 0x3A;
        const byte ExePatchNewByte = 0x2D;
        const string BackupMarkerFile = ".jp-mod-installed";
        const string GameExeName = "Shenzhen.exe";

        static void Log(Session session, string msg)
        {
            try { session.Log(msg); } catch { }
            try
            {
                string logPath = Path.Combine(Path.GetTempPath(), "shenzenio-jp-ca.log");
                File.AppendAllText(logPath, DateTime.Now.ToString("HH:mm:ss") + " " + msg + Environment.NewLine);
            }
            catch { }
        }

        // ── Immediate CA: ゲーム検出 + ユーザーパス取得 ──────────

        [CustomAction]
        public static ActionResult FindGameDirectory(Session session)
        {
            Log(session, "FindGameDirectory: Searching...");

            string gameDir = FindSteamGameDir(session);
            if (gameDir != null)
            {
                session["GAMEDIR"] = gameDir;
                Log(session, "FindGameDirectory: Found at " + gameDir);
            }
            else
            {
                Log(session, "FindGameDirectory: Not found");
            }

            string userDocs = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments);
            session["USERDOCS"] = userDocs;
            Log(session, "FindGameDirectory: UserDocs = " + userDocs);

            return ActionResult.Success;
        }

        // ── Deferred CA: インストール ───────────────────────────

        [CustomAction]
        public static ActionResult InstallMod(Session session)
        {
            try
            {
                Log(session, "InstallMod: Starting");

                string gameDir = session["GAMEDIR"];
                string userDocs = session["USERDOCS"];

                Log(session, "InstallMod: gameDir = " + gameDir);
                Log(session, "InstallMod: userDocs = " + userDocs);

                string contentDir = Path.Combine(gameDir, "Content");
                string backupDir = GetBackupDir(userDocs);

                // 埋め込みリソース取得 - CA では呼び出し元アセンブリを探す
                var modResources = GetModResources();
                Log(session, "InstallMod: " + modResources.Count + " resources found");

                if (modResources.Count == 0)
                {
                    // GetExecutingAssembly でリソースが見つからない場合、
                    // 全ロード済みアセンブリから探す
                    Log(session, "InstallMod: Trying all loaded assemblies...");
                    foreach (var asm in AppDomain.CurrentDomain.GetAssemblies())
                    {
                        var names = asm.GetManifestResourceNames();
                        Log(session, "  Assembly: " + asm.GetName().Name + " resources: " + names.Length);
                        foreach (var n in names.Take(5))
                            Log(session, "    " + n);
                    }
                }

                // [1] バックアップ
                Directory.CreateDirectory(backupDir);
                int backedUp = 0;
                foreach (var kv in modResources)
                {
                    string src = Path.Combine(contentDir, kv.Key);
                    string dst = Path.Combine(backupDir, kv.Key);
                    if (File.Exists(src))
                    {
                        Directory.CreateDirectory(Path.GetDirectoryName(dst));
                        File.Copy(src, dst, true);
                        backedUp++;
                    }
                }
                Log(session, "InstallMod: Backed up " + backedUp + " files");

                // [2] MODファイルコピー
                Assembly resAssembly = FindResourceAssembly();
                int installed = 0;
                foreach (var kv in modResources)
                {
                    string dst = Path.Combine(contentDir, kv.Key);
                    Directory.CreateDirectory(Path.GetDirectoryName(dst));
                    using (var stream = resAssembly.GetManifestResourceStream(kv.Value))
                    {
                        if (stream != null)
                        {
                            using (var fs = File.Create(dst))
                                stream.CopyTo(fs);
                            installed++;
                        }
                    }
                }
                Log(session, "InstallMod: Installed " + installed + " files");

                // [3] EXEパッチ
                bool exePatched = false;
                string exePath = Path.Combine(gameDir, GameExeName);
                string exeBackup = Path.Combine(backupDir, GameExeName);
                try
                {
                    File.Copy(exePath, exeBackup, true);
                    byte[] bytes = File.ReadAllBytes(exePath);
                    if (bytes.Length > ExePatchOffset && bytes[ExePatchOffset] == ExePatchOrigByte)
                    {
                        bytes[ExePatchOffset] = ExePatchNewByte;
                        File.WriteAllBytes(exePath, bytes);
                        exePatched = true;
                        Log(session, "InstallMod: EXE patched");
                    }
                    else
                    {
                        Log(session, "InstallMod: EXE byte mismatch, skip");
                    }
                }
                catch (Exception ex)
                {
                    Log(session, "InstallMod: EXE patch failed: " + ex.Message);
                }

                // [4] config.cfg 更新
                UpdateConfigFiles(userDocs, "English", "Chinese", session);

                // [5] マーカー書き込み
                string marker = string.Format(
                    "{{\n  \"GameDir\": \"{0}\",\n  \"InstalledAt\": \"{1}\",\n  \"FileCount\": {2},\n  \"ExePatched\": {3}\n}}",
                    gameDir.Replace("\\", "\\\\"),
                    DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"),
                    installed,
                    exePatched ? "true" : "false");
                File.WriteAllText(Path.Combine(backupDir, BackupMarkerFile), marker, Encoding.UTF8);

                Log(session, "InstallMod: Complete");
                return ActionResult.Success;
            }
            catch (Exception ex)
            {
                Log(session, "InstallMod: FAILED - " + ex);
                return ActionResult.Failure;
            }
        }

        // ── Deferred CA: アンインストール ───────────────────────

        [CustomAction]
        public static ActionResult UninstallMod(Session session)
        {
            try
            {
                Log(session, "UninstallMod: Starting");

                // アンインストール時は FindGameDirectory が走らない場合があるため
                // USERDOCS を直接取得する
                string userDocs;
                try { userDocs = session["USERDOCS"]; } catch { userDocs = null; }
                if (string.IsNullOrEmpty(userDocs))
                    userDocs = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments);

                string backupDir = GetBackupDir(userDocs);
                string markerPath = Path.Combine(backupDir, BackupMarkerFile);

                if (!File.Exists(markerPath))
                {
                    Log(session, "UninstallMod: No marker, skip");
                    return ActionResult.Success;
                }

                string markerContent = File.ReadAllText(markerPath);
                var match = Regex.Match(markerContent, "\"GameDir\"\\s*:\\s*\"([^\"]+)\"");
                if (!match.Success)
                {
                    Log(session, "UninstallMod: Cannot parse GameDir");
                    return ActionResult.Success;
                }

                string gameDir = match.Groups[1].Value.Replace("\\\\", "\\");
                string contentDir = Path.Combine(gameDir, "Content");

                int restored = 0;
                if (Directory.Exists(backupDir))
                {
                    foreach (string backupFile in Directory.GetFiles(backupDir, "*", SearchOption.AllDirectories))
                    {
                        string fileName = Path.GetFileName(backupFile);
                        if (fileName == BackupMarkerFile ||
                            fileName.Equals(GameExeName, StringComparison.OrdinalIgnoreCase))
                            continue;

                        string rel = backupFile.Substring(backupDir.Length + 1);
                        string dst = Path.Combine(contentDir, rel);
                        try
                        {
                            Directory.CreateDirectory(Path.GetDirectoryName(dst));
                            File.Copy(backupFile, dst, true);
                            restored++;
                        }
                        catch (Exception ex)
                        {
                            Log(session, "UninstallMod: Restore failed: " + rel + " - " + ex.Message);
                        }
                    }
                }
                Log(session, "UninstallMod: Restored " + restored + " files");

                string exeBackup = Path.Combine(backupDir, GameExeName);
                if (File.Exists(exeBackup))
                {
                    try
                    {
                        File.Copy(exeBackup, Path.Combine(gameDir, GameExeName), true);
                    }
                    catch { }
                }

                UpdateConfigFiles(userDocs, "Chinese", "English", session);
                try { Directory.Delete(backupDir, true); } catch { }

                Log(session, "UninstallMod: Complete");
                return ActionResult.Success;
            }
            catch (Exception ex)
            {
                Log(session, "UninstallMod: FAILED - " + ex);
                return ActionResult.Failure;
            }
        }

        // ── ヘルパー ─────────────────────────────────────────

        static string GetBackupDir(string userDocs)
        {
            return Path.Combine(userDocs, "My Games", "SHENZHEN IO", ".jp-mod-backup");
        }

        static Dictionary<string, string> ParseData(string data)
        {
            var result = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            if (string.IsNullOrEmpty(data)) return result;
            foreach (string pair in data.Split(';'))
            {
                int eq = pair.IndexOf('=');
                if (eq > 0)
                    result[pair.Substring(0, eq).Trim()] = pair.Substring(eq + 1).Trim();
            }
            return result;
        }

        static string FindSteamGameDir(Session session)
        {
            var candidates = new List<string>
            {
                @"C:\Program Files (x86)\Steam\steamapps\common\SHENZHEN IO",
                @"C:\Program Files\Steam\steamapps\common\SHENZHEN IO",
                @"D:\SteamLibrary\steamapps\common\SHENZHEN IO",
                @"E:\SteamLibrary\steamapps\common\SHENZHEN IO",
            };

            var vdfPaths = new[]
            {
                @"C:\Program Files (x86)\Steam\steamapps\libraryfolders.vdf",
                @"C:\Program Files\Steam\steamapps\libraryfolders.vdf",
            };

            foreach (string vdf in vdfPaths)
            {
                if (!File.Exists(vdf)) continue;
                try
                {
                    string content = File.ReadAllText(vdf);
                    foreach (Match m in Regex.Matches(content, "\"path\"\\s+\"([^\"]+)\""))
                    {
                        string libPath = m.Groups[1].Value.Replace("\\\\", "\\");
                        string candidate = Path.Combine(libPath, "steamapps", "common", "SHENZHEN IO");
                        if (!candidates.Contains(candidate))
                            candidates.Add(candidate);
                    }
                }
                catch (Exception ex)
                {
                    Log(session, "vdf parse error: " + ex.Message);
                }
            }

            foreach (string dir in candidates)
            {
                if (File.Exists(Path.Combine(dir, GameExeName)))
                    return dir;
            }
            return null;
        }

        static Assembly FindResourceAssembly()
        {
            // まず GetExecutingAssembly を試す
            var asm = Assembly.GetExecutingAssembly();
            if (asm.GetManifestResourceNames().Any(n => n.Contains(".mod.")))
                return asm;

            // 次に全ロード済みアセンブリから探す
            foreach (var a in AppDomain.CurrentDomain.GetAssemblies())
            {
                if (a.GetManifestResourceNames().Any(n => n.Contains(".mod.")))
                    return a;
            }
            return asm;
        }

        static List<KeyValuePair<string, string>> GetModResources()
        {
            var assembly = FindResourceAssembly();
            var result = new List<KeyValuePair<string, string>>();

            foreach (string name in assembly.GetManifestResourceNames())
            {
                // 任意のプレフィックスに対応
                int modIdx = name.IndexOf(".mod.");
                if (modIdx < 0) continue;
                string suffix = name.Substring(modIdx + ".mod.".Length);
                string path = ResourceNameToPath(suffix);
                if (path != null)
                    result.Add(new KeyValuePair<string, string>(path, name));
            }
            return result;
        }

        static string ResourceNameToPath(string suffix)
        {
            if (suffix == "strings.csv")
                return "strings.csv";

            if (suffix.StartsWith("descriptions.zh.") && suffix.EndsWith(".txt"))
                return Path.Combine("descriptions.zh", suffix.Substring("descriptions.zh.".Length));

            if (suffix.StartsWith("messages.zh.") && suffix.EndsWith(".txt"))
                return Path.Combine("messages.zh", suffix.Substring("messages.zh.".Length));

            if (suffix.StartsWith("textures.editor.") && suffix.EndsWith(".png"))
                return Path.Combine("textures", "editor", suffix.Substring("textures.editor.".Length));

            return null;
        }

        static void UpdateConfigFiles(string userDocs, string fromLang, string toLang, Session session)
        {
            string saveBase = Path.Combine(userDocs, "My Games", "SHENZHEN IO");
            if (!Directory.Exists(saveBase)) return;

            foreach (string userDir in Directory.GetDirectories(saveBase))
            {
                if (!Regex.IsMatch(Path.GetFileName(userDir), @"^\d+$")) continue;
                string cfgPath = Path.Combine(userDir, "config.cfg");
                if (!File.Exists(cfgPath)) continue;
                try
                {
                    string content = File.ReadAllText(cfgPath);
                    string pattern = "Language\\s*=\\s*" + fromLang;
                    if (Regex.IsMatch(content, pattern))
                    {
                        File.WriteAllText(cfgPath, Regex.Replace(content, pattern, "Language = " + toLang));
                        Log(session, "UpdateConfig: " + cfgPath);
                    }
                }
                catch { }
            }
        }
    }
}
