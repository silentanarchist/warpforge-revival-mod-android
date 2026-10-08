using System;
using System.IO;
using System.Runtime.InteropServices;
using MelonLoader;

[assembly: MelonInfo(typeof(WarpforgeRevival.GraphicsChoice), "Warpforge Revival graphics", "1.0.0", "Warpforge Revival community")]
[assembly: MelonGame("Everguild", "Warpforge")]

namespace WarpforgeRevival
{
    /// <summary>
    /// Chooses how the game draws on a phone: OpenGL ES (default) or Vulkan.
    ///
    /// On some phones (seen on a Pixel 6 Pro) the game sometimes shows a burst of coloured blocks
    /// after signing in and then stays black until it is restarted; it is fine with OpenGL ES.
    /// The game only takes that choice from its start-up command line ("-force-gles"), which an
    /// installed app cannot be given. So this plugin, which the loader runs before the game sets
    /// up its graphics, adds "-force-gles" to the command line the game has already read: the
    /// list the engine (libunity.so) keeps of it. The places are those of this game build
    /// (1.35.0, Unity 6000.2.6f2); each is checked first, and if anything does not match nothing
    /// is changed and the game starts as it always has.
    ///
    /// Setting: "AndroidGraphics" in UserData/WarpforgeRevival.cfg - OpenGL (default) or Vulkan.
    /// </summary>
    public class GraphicsChoice : MelonPlugin
    {
        private const long HasArgv = 0x7fb5dc;      // the engine's "was this given on the command line?" check
        private const long ArgCount = 0x17fcb00;    // int: number of command-line words
        private const long ArgList = 0x17fcb08;     // char**: the words
        private const long ForceGlesText = 0x112138;  // the text "force-gles" the engine asks for

        // first instructions of that check: sub sp,sp,#0x40 / stp x30,x23,[sp,#0x10] / stp x22,x21,[sp,#0x20] / stp x20,x19,[sp,#0x30]
        private static readonly uint[] HasArgvStart = { 0xD10103FF, 0xA9015FFE, 0xA90257F6, 0xA9034FF4 };

        public override void OnPreInitialization()
        {
            try
            {
                var cat = MelonPreferences.CreateCategory("WarpforgeRevival", "Warpforge Revival");
                cat.SetFilePath(Path.Combine(MelonLoader.Utils.MelonEnvironment.UserDataDirectory, "WarpforgeRevival.cfg"), autoload: true);
                var choice = cat.CreateEntry("AndroidGraphics", "OpenGL",
                    description: "Phones only: how the game draws - OpenGL (default; avoids a black screen seen on some phones) or Vulkan (the game's own default)");
                cat.SaveToFile(false);
                string wanted = (choice.Value ?? "").Trim();
                if (wanted.Equals("Vulkan", StringComparison.OrdinalIgnoreCase))
                {
                    LoggerInstance.Msg("graphics: Vulkan (the game's own choice), as set in WarpforgeRevival.cfg");
                    return;
                }
                LoggerInstance.Msg(AddForceGles());
            }
            catch (Exception e) { LoggerInstance.Warning("graphics: could not choose OpenGL ES: " + e.Message); }
        }

        private static unsafe string AddForceGles()
        {
            long baseAddress = EngineBase();
            if (baseAddress == 0) return "graphics: the engine library was not found; the game chooses itself";

            uint* code = (uint*)(baseAddress + HasArgv);
            for (int i = 0; i < HasArgvStart.Length; i++)
                if (code[i] != HasArgvStart[i]) return "graphics: this game build is not the one expected; the game chooses itself";
            if (Marshal.PtrToStringAnsi((IntPtr)(baseAddress + ForceGlesText)) != "force-gles")
                return "graphics: this game build is not the one expected; the game chooses itself";

            int* count = (int*)(baseAddress + ArgCount);
            IntPtr** list = (IntPtr**)(baseAddress + ArgList);
            int n = *count;
            if (n < 0 || n > 256 || (n > 0 && *list == null)) return "graphics: the command line looks wrong; left alone";
            for (int i = 0; i < n; i++)
            {
                string word = Marshal.PtrToStringAnsi((*list)[i]) ?? "";
                if (word.TrimStart('-').StartsWith("force-gles") || word.TrimStart('-') == "force-vulkan")
                    return "graphics: the command line already chooses (" + word + "); left alone";
            }

            // A new, longer list: the old words, then "-force-gles". Neither is ever freed: the engine keeps using them.
            IntPtr* longer = (IntPtr*)Marshal.AllocHGlobal(sizeof(IntPtr) * (n + 2));
            for (int i = 0; i < n; i++) longer[i] = (*list)[i];
            longer[n] = Marshal.StringToHGlobalAnsi("-force-gles");
            longer[n + 1] = IntPtr.Zero;
            *list = longer;
            *count = n + 1;
            return "graphics: OpenGL ES chosen (set AndroidGraphics = \"Vulkan\" in WarpforgeRevival.cfg to go back)";
        }

        private const long JniOnLoad = 0x91d6c0;    // where the engine's exported JNI_OnLoad sits in libunity.so

        /// <summary>Where libunity.so starts in memory, worked out from its exported JNI_OnLoad (0 if not loaded).</summary>
        private static long EngineBase()
        {
            if (System.Runtime.InteropServices.NativeLibrary.TryLoad("libunity.so", out IntPtr lib)
                && System.Runtime.InteropServices.NativeLibrary.TryGetExport(lib, "JNI_OnLoad", out IntPtr entry))
                return (long)entry - JniOnLoad;
            // otherwise from the process's memory map: the part of libunity.so that starts at the file's beginning
            foreach (string line in File.ReadLines("/proc/self/maps"))
            {
                if (!line.EndsWith("/libunity.so")) continue;
                string[] parts = line.Split(' ', StringSplitOptions.RemoveEmptyEntries);
                if (parts.Length >= 6 && parts[2] == "00000000")
                    return Convert.ToInt64(parts[0].Split('-')[0], 16);
            }
            return 0;
        }
    }
}
