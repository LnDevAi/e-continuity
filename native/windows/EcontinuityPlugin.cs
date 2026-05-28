using System;
using System.IO;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace Econtinuity.Native.Windows
{
    // MethodChannel handler pour Flutter Windows
    // Méthodes exposées au Flutter :
    // - "watchDirectory"  : { path: string } → démarre FileSystemWatcher
    // - "listDirectory"   : { path: string } → retourne arborescence JSON
    // - "getClipboard"    : → retourne contenu presse-papier Windows
    // - "setClipboard"    : { content: string } → met à jour le presse-papier Windows
    // - "lockDevice"      : → verrouille la session Windows
    // - "secureWipe"      : { paths: List<string> } → lance SecureWipe sur les chemins

    public class EcontinuityPlugin : IDisposable
    {
        private FileSystemWatcher? _watcher;
        private Action<string>? _onFileChange;

        public void WatchDirectory(string path, Action<string> onChange)
        {
            _watcher?.Dispose();

            if (!Directory.Exists(path))
                throw new DirectoryNotFoundException($"Répertoire introuvable : {path}");

            _watcher = new FileSystemWatcher(path)
            {
                NotifyFilter = NotifyFilters.FileName
                             | NotifyFilters.DirectoryName
                             | NotifyFilters.LastWrite
                             | NotifyFilters.Size,
                IncludeSubdirectories = true,
                EnableRaisingEvents = true,
            };

            _onFileChange = onChange;
            _watcher.Changed += (s, e) => onChange(e.FullPath);
            _watcher.Created += (s, e) => onChange(e.FullPath);
            _watcher.Deleted += (s, e) => onChange(e.FullPath);
            _watcher.Renamed += (s, e) => onChange(e.FullPath);
        }

        public List<FileSystemEntry> ListDirectory(string path)
        {
            var entries = new List<FileSystemEntry>();

            if (!Directory.Exists(path))
                return entries;

            try
            {
                // Dossiers en premier
                foreach (var dir in Directory.GetDirectories(path))
                {
                    entries.Add(new FileSystemEntry
                    {
                        Name = Path.GetFileName(dir),
                        Path = dir,
                        IsDirectory = true,
                        Size = 0,
                        ModifiedAt = new DirectoryInfo(dir).LastWriteTime,
                    });
                }

                // Fichiers ensuite
                foreach (var file in Directory.GetFiles(path))
                {
                    var info = new FileInfo(file);
                    entries.Add(new FileSystemEntry
                    {
                        Name = info.Name,
                        Path = file,
                        IsDirectory = false,
                        Size = info.Length,
                        ModifiedAt = info.LastWriteTime,
                    });
                }
            }
            catch (UnauthorizedAccessException)
            {
                // Répertoire non accessible — on ignore silencieusement
            }

            return entries;
        }

        public string? GetClipboard()
        {
            // Le presse-papier Windows doit être accédé depuis un thread STA
            string? result = null;
            var thread = new System.Threading.Thread(() =>
            {
                try
                {
                    if (System.Windows.Forms.Clipboard.ContainsText())
                        result = System.Windows.Forms.Clipboard.GetText();
                }
                catch { }
            });
            thread.SetApartmentState(System.Threading.ApartmentState.STA);
            thread.Start();
            thread.Join();
            return result;
        }

        public void SetClipboard(string content)
        {
            var thread = new System.Threading.Thread(() =>
            {
                try
                {
                    System.Windows.Forms.Clipboard.SetText(content);
                }
                catch { }
            });
            thread.SetApartmentState(System.Threading.ApartmentState.STA);
            thread.Start();
            thread.Join();
        }

        public void LockDevice()
        {
            // Verrouille la session Windows via l'API Win32
            NativeMethods.LockWorkStation();
        }

        public void SecureWipe(List<string> paths)
        {
            foreach (var path in paths)
            {
                if (File.Exists(path))
                    SecureWipe.WipeFile(path);
                else if (Directory.Exists(path))
                    SecureWipe.WipeDirectory(path);
            }
        }

        public void Dispose()
        {
            _watcher?.Dispose();
        }
    }

    public class FileSystemEntry
    {
        public string Name { get; set; } = "";
        public string Path { get; set; } = "";
        public bool IsDirectory { get; set; }
        public long Size { get; set; }
        public DateTime? ModifiedAt { get; set; }
    }

    internal static class NativeMethods
    {
        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool LockWorkStation();
    }
}
