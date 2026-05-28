using System;
using System.IO;
using System.Security.Cryptography;

namespace Econtinuity.Native.Windows
{
    /// <summary>
    /// Suppression sécurisée de fichiers par réécriture des clusters.
    /// Standard DoD 5220.22-M — 3 passes :
    ///   Passe 0 : données aléatoires
    ///   Passe 1 : 0x00 (zéros)
    ///   Passe 2 : 0xFF (uns)
    /// </summary>
    public static class SecureWipe
    {
        private const int Passes = 3;
        private const int BufferSize = 4096;

        public static void WipeFile(string filePath)
        {
            if (!File.Exists(filePath)) return;

            var fileInfo = new FileInfo(filePath);
            long length = fileInfo.Length;

            // Réécriture multi-passes
            using (var stream = new FileStream(
                filePath,
                FileMode.Open,
                FileAccess.Write,
                FileShare.None,
                BufferSize,
                FileOptions.WriteThrough))
            {
                var buffer = new byte[BufferSize];

                for (int pass = 0; pass < Passes; pass++)
                {
                    stream.Seek(0, SeekOrigin.Begin);
                    long remaining = length;

                    while (remaining > 0)
                    {
                        int toWrite = (int)Math.Min(buffer.Length, remaining);

                        switch (pass)
                        {
                            case 0:
                                // Passe 0 : octets aléatoires cryptographiquement sûrs
                                RandomNumberGenerator.Fill(buffer.AsSpan(0, toWrite));
                                break;
                            case 1:
                                // Passe 1 : zéros
                                Array.Fill(buffer, (byte)0x00, 0, toWrite);
                                break;
                            case 2:
                                // Passe 2 : uns
                                Array.Fill(buffer, (byte)0xFF, 0, toWrite);
                                break;
                        }

                        stream.Write(buffer, 0, toWrite);
                        remaining -= toWrite;
                    }

                    // Force l'écriture physique sur le disque entre les passes
                    stream.Flush(flushToDisk: true);
                }
            }

            // Renommer le fichier avant suppression (limite la récupération par métadonnées)
            var randomName = Path.Combine(
                Path.GetDirectoryName(filePath)!,
                Guid.NewGuid().ToString("N"));
            File.Move(filePath, randomName);
            File.Delete(randomName);
        }

        public static void WipeDirectory(string dirPath)
        {
            if (!Directory.Exists(dirPath)) return;

            // Effacer tous les fichiers récursivement
            foreach (var file in Directory.GetFiles(dirPath, "*", SearchOption.AllDirectories))
            {
                try { WipeFile(file); }
                catch { /* Fichier verrouillé ou accès refusé — on continue */ }
            }

            // Supprimer les répertoires vides (du plus profond au plus haut)
            foreach (var dir in Directory.GetDirectories(dirPath, "*", SearchOption.AllDirectories))
            {
                try { Directory.Delete(dir, false); }
                catch { }
            }

            try { Directory.Delete(dirPath, true); }
            catch { }
        }
    }
}
