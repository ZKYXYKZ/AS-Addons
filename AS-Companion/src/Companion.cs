using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Net;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Web.Script.Serialization;
using System.Windows.Forms;

[assembly: AssemblyTitle("AS Companion")]
[assembly: AssemblyProduct("AS Companion")]
[assembly: AssemblyDescription("Build planner and launcher for Azeroth Survivors")]
[assembly: AssemblyCompany("ZKYXYKZ")]
[assembly: AssemblyCopyright("ZKYXYKZ")]

static class Web2
{
    static string libDir;

    public static void Prepare()
    {
        string version = Assembly.GetExecutingAssembly().GetName().Version.ToString();
        libDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "AS-Companion", "lib", version);
        try
        {
            Directory.CreateDirectory(libDir);
            string arch = (Environment.GetEnvironmentVariable("PROCESSOR_ARCHITECTURE") ?? "").ToUpperInvariant() == "ARM64" ? "arm64" : Environment.Is64BitProcess ? "x64" : "x86";
            Extract("lib/Microsoft.Web.WebView2.Core.dll", "Microsoft.Web.WebView2.Core.dll");
            Extract("lib/Microsoft.Web.WebView2.WinForms.dll", "Microsoft.Web.WebView2.WinForms.dll");
            Extract("lib/" + arch + "/WebView2Loader.dll", "WebView2Loader.dll");
        }
        catch { }
        AppDomain.CurrentDomain.AssemblyResolve += (s, e) =>
        {
            string f = Path.Combine(libDir, new AssemblyName(e.Name).Name + ".dll");
            return File.Exists(f) ? Assembly.LoadFrom(f) : null;
        };
    }

    static void Extract(string resource, string name)
    {
        string target = Path.Combine(libDir, name);
        using (Stream s = Assembly.GetExecutingAssembly().GetManifestResourceStream(resource))
        {
            if (s == null || (File.Exists(target) && new FileInfo(target).Length == s.Length)) return;
            using (FileStream f = File.Create(target)) s.CopyTo(f);
        }
    }

    public static bool Available()
    {
        try { return Check(); } catch { return false; }
    }

    [System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.NoInlining)]
    static bool Check()
    {
        Microsoft.Web.WebView2.Core.CoreWebView2Environment.SetLoaderDllFolderPath(libDir);
        return !string.IsNullOrEmpty(Microsoft.Web.WebView2.Core.CoreWebView2Environment.GetAvailableBrowserVersionString());
    }

    [System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.NoInlining)]
    public static Form Create(string url, string dataDir)
    {
        return new UiWindow(url, dataDir);
    }
}

class UiWindow : Form
{
    readonly Microsoft.Web.WebView2.WinForms.WebView2 view;

    public UiWindow(string url, string dataDir)
    {
        Text = "AS Companion";
        Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath);
        StartPosition = FormStartPosition.CenterScreen;
        Rectangle wa = Screen.PrimaryScreen.WorkingArea;
        Width = Math.Min(1320, wa.Width - 40);
        Height = Math.Min(920, wa.Height - 40);
        MinimumSize = new Size(760, 520);
        BackColor = Color.FromArgb(14, 14, 16);
        view = new Microsoft.Web.WebView2.WinForms.WebView2();
        view.Dock = DockStyle.Fill;
        view.DefaultBackgroundColor = BackColor;
        Controls.Add(view);
        Load += async (s, e) =>
        {
            Microsoft.Web.WebView2.Core.CoreWebView2Environment env = await Microsoft.Web.WebView2.Core.CoreWebView2Environment.CreateAsync(null, dataDir);
            await view.EnsureCoreWebView2Async(env);
            view.CoreWebView2.Settings.IsStatusBarEnabled = false;
            view.CoreWebView2.Settings.AreDevToolsEnabled = false;
            view.CoreWebView2.NewWindowRequested += (o, a) =>
            {
                a.Handled = true;
                if (a.Uri.StartsWith("https://")) Process.Start(a.Uri);
            };
            view.Source = new Uri(url);
        };
    }
}

static class Native
{
    [DllImport("user32.dll")] static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    [DllImport("user32.dll")] static extern uint MapVirtualKey(uint c, uint t);

    public static void Press(IntPtr h, uint vk)
    {
        uint sc = MapVirtualKey(vk, 0);
        PostMessage(h, 0x100, (IntPtr)vk, (IntPtr)(1 | (sc << 16)));
        Thread.Sleep(60);
        PostMessage(h, 0x101, (IntPtr)vk, (IntPtr)(1 | (sc << 16) | (3u << 30)));
    }
}

class Overlay : Form
{
    public Label Text2;

    public Overlay()
    {
        FormBorderStyle = FormBorderStyle.None;
        TopMost = true;
        ShowInTaskbar = false;
        BackColor = Color.FromArgb(20, 20, 24);
        Opacity = 0.9;
        Width = 820;
        Height = 46;
        StartPosition = FormStartPosition.Manual;
        Rectangle scr = Screen.PrimaryScreen.Bounds;
        Left = scr.X + (scr.Width - Width) / 2;
        Top = scr.Y + 110;
        Text2 = new Label();
        Text2.Dock = DockStyle.Fill;
        Text2.TextAlign = ContentAlignment.MiddleCenter;
        Text2.ForeColor = Color.FromArgb(240, 190, 80);
        Text2.Font = new Font("Segoe UI", 15, FontStyle.Bold);
        Controls.Add(Text2);
    }

    protected override bool ShowWithoutActivation { get { return true; } }

    protected override CreateParams CreateParams
    {
        get
        {
            CreateParams cp = base.CreateParams;
            cp.ExStyle |= 0x08000000 | 0x00000080 | 0x00000008;
            return cp;
        }
    }
}

class Companion : Form
{
    static readonly int Port = TestPort();
    static int TestPort() { int p; return int.TryParse(Environment.GetEnvironmentVariable("AS_COMPANION_PORT"), out p) ? p : 47821; }
    static readonly string Url = "http://localhost:" + Port + "/";
    static readonly UTF8Encoding Utf8 = new UTF8Encoding(false);
    static readonly double[] BaseOdds = { 0.58, 0.24, 0.11, 0.05, 0.02 };

    readonly string exeDir = AppDomain.CurrentDomain.BaseDirectory;
    readonly string dataDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "AS-Companion");
    readonly string uiDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "AS-Companion", "ui");
    string stateFile, logFile;

    readonly JavaScriptSerializer json = new JavaScriptSerializer { MaxJsonLength = int.MaxValue, RecursionLimit = 200 };
    Dictionary<string, object> data;
    HttpListener listener;
    Overlay overlay;
    NotifyIcon tray;
    System.Windows.Forms.Timer tick;

    Process game;
    Process ui;
    bool running;
    string advice = "", error = "";
    string lang = "en";
    Dictionary<string, object> state, settings, build, heroClass;
    Dictionary<string, int> owned = new Dictionary<string, int>();
    string amulet;
    Dictionary<string, string> jewels = new Dictionary<string, string>();
    int screenRerolls;
    double runLuck, amuletLuck;
    int amuletUps;
    Dictionary<string, double> jewelLuck = new Dictionary<string, double>();
    uint pendingKey;
    DateTime pendingAt;
    int pendingTries;
    DateTime uiCheck = DateTime.Now;
    DateTime lastKey = DateTime.MinValue;

    [STAThread]
    static void Main(string[] args)
    {
        bool first;
        bool after = args.Contains("--after-update");
        Mutex m = new Mutex(true, "AS-Companion-ZKYXYKZ-" + Port, out first);
        for (int i = 0; !first && after && i < 50; i++)
        {
            Thread.Sleep(200);
            m.Dispose();
            m = new Mutex(true, "AS-Companion-ZKYXYKZ-" + Port, out first);
        }
        using (m)
        {
            if (!first)
            {
                try { using (WebClient w = new WebClient()) w.UploadString(Url + "api/show", ""); } catch { OpenUi(); }
                return;
            }
            Web2.Prepare();
            Application.SetUnhandledExceptionMode(UnhandledExceptionMode.CatchException);
            Application.ThreadException += (s, e) => CrashLog(e.Exception);
            AppDomain.CurrentDomain.UnhandledException += (s, e) => CrashLog(e.ExceptionObject as Exception);
            Application.EnableVisualStyles();
            Companion app;
            try { app = new Companion(args.Contains("-NoBrowser"), after); }
            catch (Exception ex)
            {
                CrashLog(ex);
                MessageBox.Show("AS Companion: " + ex.Message, "AS Companion", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }
            Application.Run(app);
        }
    }

    static void CrashLog(Exception ex)
    {
        try
        {
            string dir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "AS-Companion");
            Directory.CreateDirectory(dir);
            File.AppendAllText(Path.Combine(dir, "companion.log"), DateTime.Now.ToString("HH:mm:ss") + " error: " + ex + "\r\n");
        }
        catch { }
    }

    Companion(bool noBrowser, bool afterUpdate)
    {
        try { File.Delete(Path.Combine(exeDir, "ASCompanion.old.exe")); } catch { }
        ShowInTaskbar = false;
        WindowState = FormWindowState.Minimized;
        FormBorderStyle = FormBorderStyle.FixedToolWindow;
        Opacity = 0;
        CreateHandle();
        Directory.CreateDirectory(dataDir);
        stateFile = Path.Combine(dataDir, "state.json");
        logFile = Path.Combine(dataDir, "companion.log");
        Migrate();
        data = (Dictionary<string, object>)json.DeserializeObject(Utf8.GetString(Resource("data.json")));
        overlay = new Overlay();
        tray = new NotifyIcon();
        tray.Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath);
        tray.Text = "AS Companion";
        tray.Visible = true;
        ContextMenu menu = new ContextMenu();
        menu.MenuItems.Add("Builder", delegate { ShowUi(); });
        menu.MenuItems.Add("Quitter / Quit", delegate { Close(); });
        tray.ContextMenu = menu;
        tray.DoubleClick += delegate { ShowUi(); };
        listener = new HttpListener();
        listener.Prefixes.Add(Url);
        for (int i = 0; ; i++)
        {
            try { listener.Start(); break; }
            catch (HttpListenerException) { if (i >= 50) throw; Thread.Sleep(200); listener = new HttpListener(); listener.Prefixes.Add(Url); }
        }
        listener.BeginGetContext(OnContext, null);
        Log("server started on " + Url);
        if (!noBrowser) ShowUi();
        ThreadPool.QueueUserWorkItem(delegate { CheckUpdate(); });
        ThreadPool.QueueUserWorkItem(delegate { try { FindGame(); FirstRunAddons(); } catch (Exception ex) { Log("find game: " + ex.Message); } });
        tick = new System.Windows.Forms.Timer { Interval = 200 };
        tick.Tick += OnTick;
        tick.Start();
    }

    protected override void SetVisibleCore(bool value) { base.SetVisibleCore(false); }

    protected override void OnFormClosed(FormClosedEventArgs e)
    {
        tray.Visible = false;
        try { listener.Stop(); } catch { }
        base.OnFormClosed(e);
    }

    const string Repo = "ZKYXYKZ/Azeroth-Survivor-Companion";
    bool watchUi;
    volatile bool updating;
    volatile string latestTag, latestZip, latestSums, updateError = "";

    static string CurrentVersion
    {
        get { Version v = Assembly.GetExecutingAssembly().GetName().Version; return v.Major + "." + v.Minor + "." + v.Build; }
    }

    static WebClient Web()
    {
        ServicePointManager.SecurityProtocol = (SecurityProtocolType)3072;
        WebClient w = new WebClient();
        w.Headers.Add("User-Agent", "AS-Companion/" + CurrentVersion);
        return w;
    }

    void CheckUpdate()
    {
        try
        {
            string body;
            string api = Environment.GetEnvironmentVariable("AS_COMPANION_RELEASE_URL");
            using (WebClient w = Web()) body = w.DownloadString(string.IsNullOrEmpty(api) ? "https://api.github.com/repos/" + Repo + "/releases/latest" : api);
            Dictionary<string, object> rel = D(json.DeserializeObject(body));
            string tag = S(G(rel, "tag_name"));
            Dictionary<string, string> assets = new Dictionary<string, string>();
            foreach (object a in A(G(rel, "assets"))) assets[S(G(a, "name"))] = S(G(a, "browser_download_url"));
            releaseAssets = assets;
            assets.TryGetValue("AzerothSurvivors-Addons.zip", out latestZip);
            assets.TryGetValue("SHA256SUMS.txt", out latestSums);
            string manifest;
            if (assets.TryGetValue("addons.json", out manifest))
                using (WebClient w = Web()) remoteAddons = A(json.DeserializeObject(Utf8.GetString(w.DownloadData(manifest)))).Select(D).Where(x => x != null).ToList();
            FirstRunAddons();
            AutoUpdateAddons();
            Version remote, local = new Version(CurrentVersion);
            if (tag == null || !Version.TryParse(tag.TrimStart('v', 'V'), out remote) || remote <= local || latestZip == null) { latestTag = null; return; }
            latestTag = tag;
            Log("update available: " + tag);
        }
        catch (Exception ex) { Log("update check failed: " + ex.Message); }
    }

    void ApplyUpdate()
    {
        try
        {
            byte[] zip;
            string sums = null;
            using (WebClient w = Web())
            {
                zip = w.DownloadData(latestZip);
                if (latestSums != null) sums = w.DownloadString(latestSums);
            }
            string hash;
            using (System.Security.Cryptography.SHA256 sha = System.Security.Cryptography.SHA256.Create())
                hash = BitConverter.ToString(sha.ComputeHash(zip)).Replace("-", "").ToLowerInvariant();
            if (sums == null || !sums.ToLowerInvariant().Contains(hash + "  azerothsurvivors-addons.zip"))
                throw new Exception("SHA-256 mismatch");
            Dictionary<string, object> st = D(LoadState()["settings"]);
            string gamePath = GamePath();
            if (gamePath == null) throw new Exception("game not found");
            string gameDir = Path.GetDirectoryName(gamePath);
            string home = Environment.GetEnvironmentVariable("BENILLA_HOME");
            string addons = Path.Combine(string.IsNullOrEmpty(home) ? Path.Combine(gameDir, "benilla-config") : home, "AddOns");
            string newExe = Path.Combine(exeDir, "ASCompanion.new.exe");
            using (MemoryStream ms = new MemoryStream(zip))
            using (System.IO.Compression.ZipArchive za = new System.IO.Compression.ZipArchive(ms))
            {
                foreach (System.IO.Compression.ZipArchiveEntry e in za.Entries)
                {
                    string n = e.FullName.Replace('\\', '/');
                    if (n.EndsWith("/")) continue;
                    string target = null;
                    if (n == "ASCompanion.exe") target = newExe;
                    else if (n.StartsWith("benilla-config/AddOns/") && !n.Contains(".."))
                    {
                        string rel = n.Substring("benilla-config/AddOns/".Length);
                        string folder = rel.Split('/')[0];
                        if (!Directory.Exists(Path.Combine(addons, folder))) continue;
                        target = Path.Combine(addons, rel.Replace('/', '\\'));
                    }
                    if (target == null) continue;
                    Directory.CreateDirectory(Path.GetDirectoryName(target));
                    using (Stream src = e.Open())
                    using (FileStream dst = File.Create(target)) src.CopyTo(dst);
                }
            }
            Log("update " + latestTag + " extracted");
            BeginInvoke((MethodInvoker)delegate
            {
                string self = Application.ExecutablePath;
                string old = Path.Combine(exeDir, "ASCompanion.old.exe");
                try { File.Delete(old); } catch { }
                File.Move(self, old);
                File.Move(newExe, self);
                Process.Start(self, "--after-update");
                Close();
            });
        }
        catch (Exception ex)
        {
            updateError = ex.Message;
            updating = false;
            Log("update failed: " + ex.Message);
        }
    }

    volatile Dictionary<string, string> releaseAssets = new Dictionary<string, string>();
    volatile List<Dictionary<string, object>> remoteAddons = new List<Dictionary<string, object>>();

    string AddonsDir()
    {
        Dictionary<string, object> st = D(LoadState()["settings"]);
        string gamePath = GamePath() ?? Path.Combine(exeDir, "AzerothSurvivors.exe");
        string home = Environment.GetEnvironmentVariable("BENILLA_HOME");
        return Path.Combine(string.IsNullOrEmpty(home) ? Path.Combine(Path.GetDirectoryName(gamePath), "benilla-config") : home, "AddOns");
    }

    static Dictionary<string, string> Toc(string dir, string name)
    {
        Dictionary<string, string> t = new Dictionary<string, string>();
        string f = Path.Combine(dir, name, name + ".toc");
        if (!File.Exists(f)) return null;
        foreach (string line in File.ReadAllLines(f, Utf8))
        {
            Match m = Regex.Match(line, @"^##\s*([\w-]+)\s*:\s*(.*)$");
            if (m.Success) t[m.Groups[1].Value] = m.Groups[2].Value.Trim();
        }
        return t;
    }

    Dictionary<string, bool> EnabledMap(string dir)
    {
        Dictionary<string, bool> map = new Dictionary<string, bool>();
        string f = Path.Combine(dir, "account.txt");
        if (File.Exists(f))
            foreach (string line in File.ReadAllLines(f))
            {
                Match m = Regex.Match(line, @"^\s*([^:]+?)\s*:\s*(enabled|disabled)\s*$", RegexOptions.IgnoreCase);
                if (m.Success) map[m.Groups[1].Value] = m.Groups[2].Value.ToLowerInvariant() == "enabled";
            }
        return map;
    }

    string AddonsJson()
    {
        string dir = AddonsDir();
        Dictionary<string, bool> enabled = EnabledMap(dir);
        List<string> names = remoteAddons.Select(r => S(G(r, "name"))).Where(n => n != null).ToList();
        if (Directory.Exists(dir))
            foreach (string d in Directory.GetDirectories(dir))
            {
                string n = Path.GetFileName(d);
                if (!names.Contains(n) && Toc(dir, n) != null) names.Add(n);
            }
        List<object> list = new List<object>();
        foreach (string n in names)
        {
            Dictionary<string, object> remote = remoteAddons.FirstOrDefault(r => S(G(r, "name")) == n);
            Dictionary<string, string> toc = Toc(dir, n);
            string v;
            Dictionary<string, object> o = new Dictionary<string, object>();
            o["name"] = n;
            o["title"] = remote != null ? S(G(remote, "title")) : toc != null && toc.TryGetValue("Title", out v) ? v : n;
            o["notes"] = remote != null ? S(G(remote, "notes")) : toc != null && toc.TryGetValue("Notes", out v) ? v : "";
            o["notesFr"] = remote != null ? S(G(remote, "notesFr")) : toc != null && toc.TryGetValue("Notes-frFR", out v) ? v : "";
            o["installed"] = toc != null;
            o["version"] = toc != null && toc.TryGetValue("Version", out v) ? v : null;
            o["latest"] = remote != null ? S(G(remote, "version")) : null;
            o["ours"] = remote != null;
            bool en;
            o["enabled"] = !enabled.TryGetValue(n, out en) || en;
            list.Add(o);
        }
        return json.Serialize(new Dictionary<string, object> { { "addons", list }, { "running", running }, { "dir", dir } });
    }

    string AddonAction(string name, string action)
    {
        if (running) return GameLang().StartsWith("fr") ? "Fermez le jeu d'abord" : "Close the game first";
        if (string.IsNullOrEmpty(name) || name.Contains("..") || name.Contains("\\") || name.Contains("/")) return "bad name";
        string dir = AddonsDir();
        string path = Path.Combine(dir, name);
        if (action == "uninstall")
        {
            if (Directory.Exists(path)) Microsoft.VisualBasic.FileIO.FileSystem.DeleteDirectory(path, Microsoft.VisualBasic.FileIO.UIOption.OnlyErrorDialogs, Microsoft.VisualBasic.FileIO.RecycleOption.SendToRecycleBin);
            Log("addon removed: " + name);
            return "";
        }
        if (action == "enable" || action == "disable")
        {
            string f = Path.Combine(dir, "account.txt");
            List<string> lines = File.Exists(f) ? File.ReadAllLines(f).ToList() : new List<string>();
            lines.RemoveAll(l => Regex.IsMatch(l, @"^\s*" + Regex.Escape(name) + @"\s*:"));
            lines.Add(name + ": " + (action == "enable" ? "enabled" : "disabled"));
            File.WriteAllLines(f, lines);
            Log("addon " + action + "d: " + name);
            return "";
        }
        if (action == "install")
        {
            Dictionary<string, object> remote = remoteAddons.FirstOrDefault(r => S(G(r, "name")) == name);
            string file = S(G(remote, "file")), url;
            if (file == null || !releaseAssets.TryGetValue(file, out url)) return "not in the release";
            byte[] zip;
            string sums;
            using (WebClient w = Web())
            {
                zip = w.DownloadData(url);
                sums = latestSums != null ? w.DownloadString(latestSums) : "";
            }
            string hash;
            using (System.Security.Cryptography.SHA256 sha = System.Security.Cryptography.SHA256.Create())
                hash = BitConverter.ToString(sha.ComputeHash(zip)).Replace("-", "").ToLowerInvariant();
            if (!sums.ToLowerInvariant().Contains(hash + "  " + file.ToLowerInvariant())) return "SHA-256 mismatch";
            using (MemoryStream ms = new MemoryStream(zip))
            using (System.IO.Compression.ZipArchive za = new System.IO.Compression.ZipArchive(ms))
                foreach (System.IO.Compression.ZipArchiveEntry e in za.Entries)
                {
                    string n = e.FullName.Replace('\\', '/');
                    if (n.EndsWith("/") || n.Contains("..") || !n.StartsWith(name + "/")) continue;
                    string target = Path.Combine(dir, n.Replace('/', '\\'));
                    Directory.CreateDirectory(Path.GetDirectoryName(target));
                    using (Stream src = e.Open())
                    using (FileStream dst = File.Create(target)) src.CopyTo(dst);
                }
            Log("addon installed: " + name + " " + S(G(remote, "version")));
            return "";
        }
        return "unknown action";
    }

    volatile string addonsUpdated = "";
    DateTime nextCheck = DateTime.Now.AddMinutes(30);

    static Version ParseVersion(string v)
    {
        Version r;
        return Version.TryParse((v ?? "").Trim().TrimStart('v', 'V'), out r) ? r : new Version(0, 0, 0);
    }

    void AutoUpdateAddons()
    {
        if (running || updating || N(G(D(LoadState()["settings"]), "autoAddons"), 1) == 0) return;
        string dir = AddonsDir();
        List<string> done = new List<string>();
        foreach (Dictionary<string, object> r in remoteAddons)
        {
            string name = S(G(r, "name"));
            Dictionary<string, string> toc = name == null ? null : Toc(dir, name);
            if (toc == null) continue;
            string installed;
            toc.TryGetValue("Version", out installed);
            if (ParseVersion(S(G(r, "version"))) <= ParseVersion(installed)) continue;
            string err;
            try { err = AddonAction(name, "install"); } catch (Exception ex) { err = ex.Message; }
            if (string.IsNullOrEmpty(err)) done.Add(name + " " + S(G(r, "version")));
            else Log("addon auto-update failed: " + name + ": " + err);
        }
        if (done.Count > 0)
        {
            addonsUpdated = string.Join(", ", done);
            Log("addons auto-updated: " + addonsUpdated);
        }
    }

    void Migrate()
    {
        if (File.Exists(stateFile)) return;
        foreach (string p in new[] { Path.Combine(exeDir, "AS-Companion", "state.json"), Path.Combine(exeDir, "state.json") })
        {
            if (File.Exists(p)) { File.Copy(p, stateFile); return; }
        }
    }

    void Log(string m)
    {
        try { File.AppendAllText(logFile, DateTime.Now.ToString("HH:mm:ss") + " " + m + "\r\n", Utf8); } catch { }
    }

    static byte[] Resource(string name)
    {
        using (Stream s = Assembly.GetExecutingAssembly().GetManifestResourceStream("web/" + name))
        {
            if (s == null) return null;
            MemoryStream ms = new MemoryStream();
            s.CopyTo(ms);
            return ms.ToArray();
        }
    }

    Form uiForm;
    bool askedRuntime;

    void ShowUi()
    {
        if (uiForm != null && !uiForm.IsDisposed)
        {
            uiForm.Show();
            if (uiForm.WindowState == FormWindowState.Minimized) uiForm.WindowState = FormWindowState.Normal;
            uiForm.Activate();
            return;
        }
        if (Web2.Available())
        {
            try
            {
                uiForm = Web2.Create(Url, Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "AS-Companion", "webview"));
                uiForm.FormClosing += OnUiClosing;
                uiForm.Show();
                watchUi = false;
                return;
            }
            catch (Exception ex) { Log("webview error: " + ex.Message); uiForm = null; }
        }
        else if (!askedRuntime)
        {
            askedRuntime = true;
            bool fr = GameLang().StartsWith("fr");
            DialogResult r = MessageBox.Show(fr
                ? "AS Companion a besoin du composant Microsoft WebView2 pour afficher sa fenêtre.\n\nLe télécharger et l'installer maintenant (environ 2 Mo, gratuit, de Microsoft) ?\nEn attendant, l'interface s'ouvre dans votre navigateur."
                : "AS Companion needs the Microsoft WebView2 component to show its window.\n\nDownload and install it now (about 2 MB, free, from Microsoft)?\nMeanwhile, the interface opens in your browser.",
                "AS Companion", MessageBoxButtons.YesNo, MessageBoxIcon.Information);
            if (r == DialogResult.Yes) ThreadPool.QueueUserWorkItem(delegate { InstallWebView2(); });
        }
        ui = OpenUi();
        watchUi = ui != null;
        if (ui == null) Log("opened the default browser; quit from the tray icon");
    }

    void OnUiClosing(object sender, FormClosingEventArgs e)
    {
        if (e.CloseReason == CloseReason.WindowsShutDown || e.CloseReason == CloseReason.ApplicationExitCall || e.CloseReason == CloseReason.TaskManagerClosing) return;
        if (running)
        {
            e.Cancel = true;
            uiForm.Hide();
            tray.ShowBalloonTip(4000, "AS Companion", GameLang().StartsWith("fr") ? "Le compagnon reste actif pendant la partie." : "The companion stays on while the game runs.", ToolTipIcon.Info);
            return;
        }
        Log("ui closed");
        BeginInvoke((MethodInvoker)delegate { Close(); });
    }

    void InstallWebView2()
    {
        try
        {
            string setup = Path.Combine(Path.GetTempPath(), "MicrosoftEdgeWebview2Setup.exe");
            using (WebClient w = Web()) w.DownloadFile("https://go.microsoft.com/fwlink/p/?LinkId=2124703", setup);
            Log("installing WebView2");
            Process p = Process.Start(setup, "/silent /install");
            p.WaitForExit();
            Log("WebView2 setup exit " + p.ExitCode);
            BeginInvoke((MethodInvoker)delegate
            {
                if (!Web2.Available()) { MessageBox.Show(GameLang().StartsWith("fr") ? "L'installation de WebView2 a échoué. L'interface reste dans votre navigateur." : "WebView2 setup failed. The interface stays in your browser.", "AS Companion"); return; }
                watchUi = false;
                ShowUi();
            });
        }
        catch (Exception ex) { Log("WebView2 install failed: " + ex.Message); }
    }

    static Process OpenUi()
    {
        string pf86 = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86);
        string pf = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles);
        string local = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        string[] candidates = {
            Path.Combine(pf86, @"Microsoft\Edge\Application\msedge.exe"),
            Path.Combine(pf, @"Microsoft\Edge\Application\msedge.exe"),
            Path.Combine(local, @"Microsoft\Edge\Application\msedge.exe"),
            Path.Combine(pf, @"Google\Chrome\Application\chrome.exe"),
            Path.Combine(pf86, @"Google\Chrome\Application\chrome.exe"),
            Path.Combine(local, @"Google\Chrome\Application\chrome.exe"),
        };
        string edge = candidates.FirstOrDefault(File.Exists);
        if (edge == null)
        {
            Process.Start(Url);
            return null;
        }
        string dir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "AS-Companion", "ui");
        return Process.Start(edge, "--app=" + Url + " --user-data-dir=\"" + dir + "\" --window-size=1280,900 --no-first-run --no-default-browser-check");
    }

    bool UiAlive()
    {
        try
        {
            using (System.Management.ManagementObjectSearcher q = new System.Management.ManagementObjectSearcher("SELECT CommandLine FROM Win32_Process WHERE Name = 'msedge.exe' OR Name = 'chrome.exe'"))
                foreach (System.Management.ManagementObject o in q.Get())
                {
                    string cmd = o["CommandLine"] as string;
                    if (cmd != null && cmd.IndexOf(uiDir, StringComparison.OrdinalIgnoreCase) >= 0) return true;
                }
            return false;
        }
        catch { return true; }
    }

    string combatLog;
    long combatPos;
    DateTime combatRead = DateTime.MinValue;
    Dictionary<string, double> spellDmg = new Dictionary<string, double>();
    double totalDmg;
    static readonly Regex HitLine = new Regex(@"^\S+ \S+\s+Your (.+?) (?:hits|crits) .+? for (\d+)", RegexOptions.Compiled);
    static readonly Regex TickLine = new Regex(@"^\S+ \S+\s+.+? suffers (\d+) .*?from your (.+?)\.", RegexOptions.Compiled);
    static readonly Regex MeleeLine = new Regex(@"^\S+ \S+\s+You (?:hit|crit) .+? for (\d+)", RegexOptions.Compiled);

    void ReadCombat()
    {
        if (combatLog == null || !File.Exists(combatLog)) return;
        try
        {
            using (FileStream fs = new FileStream(combatLog, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
            {
                if (fs.Length < combatPos) combatPos = 0;
                if (fs.Length == combatPos) return;
                fs.Seek(combatPos, SeekOrigin.Begin);
                byte[] buf = new byte[fs.Length - combatPos];
                int n = fs.Read(buf, 0, buf.Length);
                int last = Array.LastIndexOf(buf, (byte)'\n', n - 1);
                if (last < 0) return;
                combatPos += last + 1;
                foreach (string line in Utf8.GetString(buf, 0, last + 1).Split('\n'))
                {
                    Match m = HitLine.Match(line);
                    if (m.Success) { AddDmg(m.Groups[1].Value, double.Parse(m.Groups[2].Value)); continue; }
                    m = TickLine.Match(line);
                    if (m.Success) { AddDmg(m.Groups[2].Value, double.Parse(m.Groups[1].Value)); continue; }
                    m = MeleeLine.Match(line);
                    if (m.Success) AddDmg("Attack", double.Parse(m.Groups[1].Value));
                }
            }
        }
        catch (IOException) { }
        if (totalDmg > 0 && DateTime.Now > dpsLog)
        {
            dpsLog = DateTime.Now.AddSeconds(60);
            Log("dps " + string.Join(", ", spellDmg.OrderByDescending(kv => kv.Value).Take(6).Select(kv => kv.Key + " " + Math.Round(100 * kv.Value / totalDmg) + "%")));
        }
    }

    DateTime dpsLog = DateTime.MinValue;

    void AddDmg(string spellName, double dmg)
    {
        string key = spellName;
        if (heroClass != null)
            foreach (object sp in A(G(heroClass, "spells")))
                if (S(G(G(sp, "name"), "en")) == spellName) { key = S(G(sp, "key")); break; }
        double v;
        spellDmg.TryGetValue(key, out v);
        spellDmg[key] = v + dmg;
        totalDmg += dmg;
    }

    double DmgShare(string key)
    {
        double v;
        return totalDmg > 0 && spellDmg.TryGetValue(key, out v) ? v / totalDmg : 0;
    }

    double DmgFactor(string key)
    {
        if (totalDmg < 20000) return 1;
        return Math.Max(0.3, Math.Min(2, 0.3 + 3 * DmgShare(key)));
    }

    void OnTick(object sender, EventArgs e)
    {
        if (running && DateTime.Now > combatRead) { combatRead = DateTime.Now.AddSeconds(1); ReadCombat(); }
        if (running && game != null && game.HasExited)
        {
            running = false;
            advice = "";
            pendingKey = 0;
            overlay.Hide();
            Log("game exited");
        }
        if (pendingKey != 0 && running && (DateTime.Now - pendingAt).TotalMilliseconds > 1500)
        {
            if (pendingTries >= 4) { Log("key not taken by the game"); pendingKey = 0; }
            else { SendKey(pendingKey); pendingTries++; Log("key resent (" + pendingTries + ")"); }
        }
        if (!running && !updating && DateTime.Now > nextCheck)
        {
            nextCheck = DateTime.Now.AddMinutes(30);
            ThreadPool.QueueUserWorkItem(delegate { CheckUpdate(); });
        }
        if (watchUi && !running && !updating && DateTime.Now > uiCheck)
        {
            uiCheck = DateTime.Now.AddSeconds(2);
            if ((ui == null || ui.HasExited) && !UiAlive()) { Log("ui closed"); Close(); }
        }
    }

    void SendKey(uint vk)
    {
        pendingAt = DateTime.Now;
        game.Refresh();
        Native.Press(game.MainWindowHandle, vk);
    }

    void OnContext(IAsyncResult ar)
    {
        HttpListenerContext ctx;
        try { ctx = listener.EndGetContext(ar); } catch { return; }
        try { listener.BeginGetContext(OnContext, null); } catch { }
        try { Invoke((MethodInvoker)delegate { Serve(ctx); }); } catch { }
    }

    static void Respond(HttpListenerContext ctx, int code, string type, byte[] bytes)
    {
        ctx.Response.StatusCode = code;
        ctx.Response.ContentType = type;
        ctx.Response.Headers.Add("Cache-Control", "no-store");
        ctx.Response.ContentLength64 = bytes.Length;
        ctx.Response.OutputStream.Write(bytes, 0, bytes.Length);
        ctx.Response.OutputStream.Close();
    }

    void Serve(HttpListenerContext ctx)
    {
        string path = ctx.Request.Url.AbsolutePath;
        string method = ctx.Request.HttpMethod;
        try
        {
            if (path == "/api/state" && method == "GET") { Respond(ctx, 200, "application/json", Utf8.GetBytes(StateJson())); return; }
            if (path == "/api/state" && method == "POST")
            {
                string body = new StreamReader(ctx.Request.InputStream, Utf8).ReadToEnd();
                json.DeserializeObject(body);
                File.WriteAllText(stateFile, body, Utf8);
                Respond(ctx, 200, "application/json", Utf8.GetBytes("{\"ok\":true}"));
                return;
            }
            if (path == "/api/launch" && method == "POST")
            {
                if (!running) Launch();
                Respond(ctx, 200, "application/json", Utf8.GetBytes("{\"ok\":true}"));
                return;
            }
            if (path == "/api/runs")
            {
                string rf = Path.Combine(dataDir, "runs.json");
                Respond(ctx, 200, "application/json", File.Exists(rf) ? File.ReadAllBytes(rf) : Utf8.GetBytes("[]"));
                return;
            }
            if (path == "/api/status")
            {
                Respond(ctx, 200, "application/json", Utf8.GetBytes(json.Serialize(new Dictionary<string, object> { { "running", running }, { "advice", advice }, { "error", error }, { "version", CurrentVersion }, { "update", latestTag }, { "updating", updating }, { "updateError", updateError }, { "addonsUpdated", addonsUpdated }, { "game", GamePath() } })));
                return;
            }
            if (path == "/api/browse" && method == "POST")
            {
                string picked = Browse(new StreamReader(ctx.Request.InputStream, Utf8).ReadToEnd());
                Respond(ctx, 200, "application/json", Utf8.GetBytes(json.Serialize(new Dictionary<string, object> { { "path", picked } })));
                return;
            }
            if (path == "/api/update" && method == "POST")
            {
                if (running) updateError = GameLang().StartsWith("fr") ? "Fermez le jeu avant de mettre à jour" : "Close the game before updating";
                else if (!updating && latestZip != null) { updating = true; updateError = ""; ThreadPool.QueueUserWorkItem(delegate { ApplyUpdate(); }); }
                Respond(ctx, 200, "application/json", Utf8.GetBytes("{\"ok\":true}"));
                return;
            }
            if (path == "/api/check" && method == "POST")
            {
                CheckUpdate();
                Respond(ctx, 200, "application/json", Utf8.GetBytes(json.Serialize(new Dictionary<string, object> { { "version", CurrentVersion }, { "update", latestTag }, { "updateError", updateError } })));
                return;
            }
            if (path == "/api/addons" && method == "GET")
            {
                Respond(ctx, 200, "application/json", Utf8.GetBytes(AddonsJson()));
                return;
            }
            if (path == "/api/addons" && method == "POST")
            {
                Dictionary<string, object> req = D(json.DeserializeObject(new StreamReader(ctx.Request.InputStream, Utf8).ReadToEnd()));
                string err;
                try { err = AddonAction(S(G(req, "name")), S(G(req, "action"))); } catch (Exception ex) { err = ex.Message; }
                Respond(ctx, 200, "application/json", Utf8.GetBytes(json.Serialize(new Dictionary<string, object> { { "error", err } })));
                return;
            }
            if (path == "/api/show" && method == "POST")
            {
                ShowUi();
                Respond(ctx, 200, "application/json", Utf8.GetBytes("{}"));
                return;
            }
            if (path == "/api/open" && method == "POST")
            {
                string target = new StreamReader(ctx.Request.InputStream, Utf8).ReadToEnd();
                if (target.StartsWith("https://x.com/") || target.StartsWith("https://github.com/") || target.StartsWith("https://www.buymeacoffee.com/")) Process.Start(target);
                Respond(ctx, 200, "application/json", Utf8.GetBytes("{\"ok\":true}"));
                return;
            }
            string file = path == "/" ? "index.html" : path.TrimStart('/');
            byte[] bytes = file.Contains("..") ? null : Resource(file);
            if (bytes == null) { Respond(ctx, 404, "text/plain", Utf8.GetBytes("not found")); return; }
            string ext = Path.GetExtension(file);
            string type = ext == ".html" ? "text/html; charset=utf-8" : ext == ".js" ? "application/javascript; charset=utf-8" : ext == ".css" ? "text/css; charset=utf-8"
                : ext == ".json" ? "application/json" : ext == ".jpg" ? "image/jpeg" : ext == ".png" ? "image/png" : ext == ".ico" ? "image/x-icon" : "application/octet-stream";
            Respond(ctx, 200, type, bytes);
        }
        catch (Exception ex)
        {
            Log("http error " + path + " : " + ex.Message);
            try { Respond(ctx, 500, "text/plain", Utf8.GetBytes(ex.Message)); } catch { }
        }
    }

    string Browse(string current)
    {
        using (Form owner = new Form { TopMost = true, ShowInTaskbar = false, StartPosition = FormStartPosition.CenterScreen, Width = 1, Height = 1, FormBorderStyle = FormBorderStyle.None, Opacity = 0 })
        using (OpenFileDialog dlg = new OpenFileDialog())
        {
            owner.Show();
            owner.Activate();
            dlg.Title = "AzerothSurvivors.exe";
            dlg.Filter = "AzerothSurvivors.exe|AzerothSurvivors.exe|*.exe|*.exe";
            if (!string.IsNullOrEmpty(current) && File.Exists(current)) { dlg.InitialDirectory = Path.GetDirectoryName(current); dlg.FileName = Path.GetFileName(current); }
            return dlg.ShowDialog(owner) == DialogResult.OK ? dlg.FileName : null;
        }
    }

    static Dictionary<string, object> D(object o) { return o as Dictionary<string, object>; }
    static object G(object o, string k) { Dictionary<string, object> d = D(o); object v; return d != null && d.TryGetValue(k, out v) ? v : null; }
    static string S(object o) { return o == null ? null : Convert.ToString(o, System.Globalization.CultureInfo.InvariantCulture); }
    static double N(object o, double def) { if (o == null) return def; try { return Convert.ToDouble(o, System.Globalization.CultureInfo.InvariantCulture); } catch { return def; } }
    static bool B(object o) { return o is bool ? (bool)o : N(o, 0) != 0; }
    static IEnumerable<object> A(object o) { IEnumerable e = o as IEnumerable; return e == null || o is string ? new object[0] : e.Cast<object>(); }
    string Loc(object o) { return S(G(o, lang)) ?? S(G(o, "en")) ?? ""; }

    const string GameExe = "AzerothSurvivors.exe";
    volatile string detectedGame;

    string GamePath()
    {
        string saved = S(G(D(LoadState()["settings"]), "gamePath"));
        if (!string.IsNullOrEmpty(saved) && File.Exists(saved)) return saved;
        string d = detectedGame;
        if (d != null && File.Exists(d)) return d;
        d = QuickFind();
        if (d != null) detectedGame = d;
        return d;
    }

    string QuickFind()
    {
        foreach (Process proc in Process.GetProcessesByName("AzerothSurvivors"))
            try { return proc.MainModule.FileName; } catch { }
        string home = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
        List<string> dirs = new List<string> { exeDir, Path.GetDirectoryName(exeDir.TrimEnd('\\')) };
        foreach (string b in new[] { Path.Combine(home, "Downloads"), Environment.GetFolderPath(Environment.SpecialFolder.Desktop), Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), home, @"C:\Games", @"D:\Games" })
        {
            dirs.Add(Path.Combine(b, "AzerothSurvivors"));
            dirs.Add(Path.Combine(b, @"AzerothSurvivors\AzerothSurvivors"));
            dirs.Add(Path.Combine(b, "Azeroth Survivors"));
        }
        foreach (string dir in dirs)
            if (!string.IsNullOrEmpty(dir) && File.Exists(Path.Combine(dir, GameExe))) return Path.Combine(dir, GameExe);
        return null;
    }

    void FindGame()
    {
        if (GamePath() != null) return;
        string home = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
        List<string> roots = new List<string> { home };
        foreach (DriveInfo dv in DriveInfo.GetDrives())
            try { if (dv.IsReady && dv.DriveType == DriveType.Fixed) roots.Add(dv.RootDirectory.FullName); } catch { }
        HashSet<string> skip = new HashSet<string>(StringComparer.OrdinalIgnoreCase) { "Windows", "$Recycle.Bin", "System Volume Information", "AppData", "ProgramData", "node_modules", ".git", "WindowsApps", "Recovery", "PerfLogs", "$WinREAgent" };
        HashSet<string> seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        int visited = 0;
        foreach (string root in roots)
        {
            Queue<KeyValuePair<string, int>> q = new Queue<KeyValuePair<string, int>>();
            q.Enqueue(new KeyValuePair<string, int>(root, 0));
            while (q.Count > 0 && visited < 300000)
            {
                KeyValuePair<string, int> cur = q.Dequeue();
                if (!seen.Add(cur.Key)) continue;
                visited++;
                string f = Path.Combine(cur.Key, GameExe);
                if (File.Exists(f))
                {
                    detectedGame = f;
                    Log("game found: " + f);
                    return;
                }
                if (cur.Value >= 5) continue;
                try
                {
                    foreach (string sub in Directory.GetDirectories(cur.Key))
                        if (!skip.Contains(Path.GetFileName(sub)) && (new DirectoryInfo(sub).Attributes & FileAttributes.ReparsePoint) == 0)
                            q.Enqueue(new KeyValuePair<string, int>(sub, cur.Value + 1));
                }
                catch { }
            }
        }
        Log("game not found after " + visited + " folders");
    }

    void FirstRunAddons()
    {
        string marker = Path.Combine(dataDir, "setup.json");
        if (File.Exists(marker) || running || remoteAddons.Count == 0 || GamePath() == null) return;
        string dir = AddonsDir();
        bool any = remoteAddons.Any(r => Directory.Exists(Path.Combine(dir, S(G(r, "name")) ?? "")));
        if (!any)
        {
            List<string> done = new List<string>();
            foreach (Dictionary<string, object> r in remoteAddons)
            {
                string name = S(G(r, "name")), err;
                try { err = AddonAction(name, "install"); } catch (Exception ex) { err = ex.Message; }
                if (string.IsNullOrEmpty(err)) done.Add(name); else Log("first install failed: " + name + ": " + err);
            }
            if (done.Count > 0) { addonsUpdated = string.Join(", ", done); Log("addons installed on first run: " + addonsUpdated); }
        }
        File.WriteAllText(marker, "{\"addons\":true}");
    }

    static string GameLang()
    {
        string save = Environment.GetEnvironmentVariable("WOW_ROGUE_SAVE");
        string dir = !string.IsNullOrEmpty(save) ? Path.GetDirectoryName(save) : Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "wenilla-rogue");
        string f = Path.Combine(dir, "language.txt");
        return File.Exists(f) ? File.ReadAllText(f).Trim() : "en";
    }

    Dictionary<string, object> LoadState()
    {
        string raw = File.Exists(stateFile) ? File.ReadAllText(stateFile, Utf8) : "{\"builds\":[],\"active\":{},\"settings\":{},\"nextId\":1}";
        Dictionary<string, object> s = D(json.DeserializeObject(raw)) ?? new Dictionary<string, object>();
        if (D(G(s, "settings")) == null) s["settings"] = new Dictionary<string, object>();
        if (G(s, "builds") == null) s["builds"] = new object[0];
        if (D(G(s, "active")) == null) s["active"] = new Dictionary<string, object>();
        return s;
    }

    string StateJson()
    {
        Dictionary<string, object> s = LoadState();
        Dictionary<string, object> st = D(s["settings"]);
        string saved = S(G(st, "gamePath"));
        if (string.IsNullOrEmpty(saved) || !File.Exists(saved)) st["gamePath"] = GamePath() ?? "";
        st["gameLang"] = GameLang();
        return json.Serialize(s);
    }

    static string LuaStr(string s)
    {
        return "\"" + (s ?? "").Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\n", "\\n").Replace("\r", "") + "\"";
    }

    Dictionary<string, object> ActiveBuild(Dictionary<string, object> s, string classKey)
    {
        string id = S(G(G(s, "active"), classKey));
        return A(G(s, "builds")).Select(D).FirstOrDefault(b => S(G(b, "class")) == classKey && (id == null || S(G(b, "id")) == id));
    }

    string JewelName(Dictionary<string, object> c, string k)
    {
        if (k.StartsWith("leg:"))
        {
            string sk = k.Substring(4);
            object l = G(G(data, "legendaries"), sk);
            object d = A(G(c, "spells")).FirstOrDefault(x => S(G(x, "key")) == sk);
            return l != null && d != null ? Loc(G(l, "family")) + " : " + Loc(G(d, "name")) : k;
        }
        foreach (string cat in new[] { "rings", "trinkets", "amulets" })
            foreach (object j in A(G(data, cat)))
                if (S(G(j, "key")) == k) return Loc(G(j, "name"));
        foreach (object d in A(G(c, "spells")))
            if (S(G(d, "key")) == k) return Loc(G(d, "name"));
        return k;
    }

    Dictionary<string, double> measuredLuck = new Dictionary<string, double>();

    void ReadLuck(string file)
    {
        if (!File.Exists(file)) return;
        Match block = Regex.Match(File.ReadAllText(file, Utf8), @"\[""luck""\]\s*=\s*\{([^}]*)\}|\bluck\s*=\s*\{([^}]*)\}");
        if (!block.Success) return;
        string body = block.Groups[1].Success ? block.Groups[1].Value : block.Groups[2].Value;
        foreach (Match m in Regex.Matches(body, @"\[?""?(\w+)""?\]?\s*=\s*([-\d.]+)"))
            measuredLuck[m.Groups[1].Value] = double.Parse(m.Groups[2].Value, System.Globalization.CultureInfo.InvariantCulture);
    }

    string[] JewelTarget(Dictionary<string, object> c, string cat, string k)
    {
        if (k.StartsWith("leg:"))
        {
            object l = G(G(data, "legendaries"), k.Substring(4));
            return new[] { JewelName(c, k), l != null ? Loc(G(l, "family")) : k, l != null ? S(G(l, "icon")) : "" };
        }
        object j = A(G(data, cat)).FirstOrDefault(x => S(G(x, "key")) == k);
        string n = j != null ? Loc(G(j, "name")) : k;
        return new[] { n, n, j != null ? S(G(j, "icon")) : "" };
    }

    void WriteGateway(Dictionary<string, object> s, string gameDir)
    {
        string home = Environment.GetEnvironmentVariable("BENILLA_HOME");
        string dir = Path.Combine(string.IsNullOrEmpty(home) ? Path.Combine(gameDir, "benilla-config") : home, "saved");
        Directory.CreateDirectory(dir);
        ReadLuck(Path.Combine(dir, "SurvivorsBuilds.lua"));
        StringBuilder L = new StringBuilder();
        L.Append("SurvivorsBuildsDB = {\n  luck = { " + string.Join(", ", measuredLuck.Select(kv => kv.Key + " = " + kv.Value.ToString(System.Globalization.CultureInfo.InvariantCulture))) + " },\n  link = {\n");
        L.Append("    launched = " + (long)(DateTime.UtcNow - new DateTime(1970, 1, 1)).TotalSeconds + ",\n");
        L.Append("    autoPick = " + (B(G(settings, "autoPick")) ? "true" : "false") + ",\n");
        L.Append("    lang = " + LuaStr(lang) + ",\n    builds = {\n");
        foreach (Dictionary<string, object> c in A(G(data, "classes")).Select(D))
        {
            string ck = S(c["key"]);
            Dictionary<string, object> b = ActiveBuild(s, ck);
            if (b == null) continue;
            Dictionary<string, object> rules = D(G(b, "rules")) ?? new Dictionary<string, object>();
            L.Append("      " + ck + " = {\n        name = " + LuaStr(S(G(b, "name"))) + ",\n        spells = {\n");
            foreach (object sp in A(G(b, "spells")))
            {
                object d = A(G(c, "spells")).FirstOrDefault(x => S(G(x, "key")) == S(G(sp, "key")));
                if (d != null) L.Append("          { key = " + LuaStr(S(G(sp, "key"))) + ", name = " + LuaStr(Loc(G(d, "name"))) + ", w = " + (int)N(G(sp, "w"), 3) + ", icon = " + LuaStr(S(G(d, "icon"))) + " },\n");
            }
            L.Append("        },\n        names = {\n");
            foreach (object d in A(G(c, "spells"))) L.Append("          " + S(G(d, "key")) + " = " + LuaStr(Loc(G(d, "name"))) + ",\n");
            L.Append("        },\n");
            Dictionary<string, object> ban = D(G(b, "ban")) ?? new Dictionary<string, object>();
            L.Append("        bans = { " + string.Join(", ", ban.Keys.Select(k => LuaStr(JewelName(c, k)))) + " },\n");
            List<string> jw = new List<string>();
            foreach (string cat in new[] { "rings", "trinkets", "amulets" })
            {
                object f = A(G(b, cat)).FirstOrDefault();
                if (f != null) jw.Add(LuaStr(JewelName(c, S(f))));
            }
            L.Append("        jewels = { " + string.Join(", ", jw) + " },\n");
            L.Append("        targets = {\n");
            foreach (string cat in new[] { "rings", "trinkets", "amulets" })
                foreach (object k in A(G(b, cat)).Take(cat == "amulets" ? 1 : 2))
                {
                    string[] t = JewelTarget(c, cat, S(k));
                    L.Append("          { cat = " + LuaStr(cat) + ", name = " + LuaStr(t[0]) + ", item = " + LuaStr(t[1]) + ", icon = " + LuaStr(t[2]) + " },\n");
                }
            L.Append("        },\n");
            L.Append("        reserve = " + (int)N(G(rules, "reserve"), 1) + ", banishes = " + (int)N(G(rules, "banishes"), 3) + ", reroll = " + (int)N(G(rules, "reroll"), 1) + ",\n      },\n");
        }
        L.Append("    },\n  },\n}\n");
        File.WriteAllText(Path.Combine(dir, "SurvivorsBuilds.lua"), L.ToString(), Utf8);
    }

    void Launch()
    {
        Dictionary<string, object> s = LoadState();
        settings = D(s["settings"]);
        string path = GamePath();
        if (path == null) { error = GameLang().StartsWith("fr") ? "Jeu introuvable : indiquez où se trouve AzerothSurvivors.exe" : "Game not found: show where AzerothSurvivors.exe is"; return; }
        string l = S(G(settings, "lang"));
        lang = !string.IsNullOrEmpty(l) && l != "auto" ? l : GameLang().StartsWith("fr") ? "fr" : "en";
        WriteGateway(s, Path.GetDirectoryName(path));
        string home = Environment.GetEnvironmentVariable("BENILLA_HOME");
        combatLog = Path.Combine(string.IsNullOrEmpty(home) ? Path.Combine(Path.GetDirectoryName(path), "benilla-config") : home, "Logs", "WoWCombatLog.txt");
        combatPos = File.Exists(combatLog) ? new FileInfo(combatLog).Length : 0;
        spellDmg = new Dictionary<string, double>();
        totalDmg = 0;
        ProcessStartInfo psi = new ProcessStartInfo(path);
        psi.WorkingDirectory = Path.GetDirectoryName(path);
        psi.UseShellExecute = false;
        psi.RedirectStandardOutput = true;
        psi.StandardOutputEncoding = Encoding.UTF8;
        game = Process.Start(psi);
        game.OutputDataReceived += (o, e) =>
        {
            if (e.Data == null) return;
            string line = e.Data;
            try { BeginInvoke((MethodInvoker)delegate { OnGameLine(line); }); } catch { }
        };
        game.BeginOutputReadLine();
        state = s;
        running = true;
        error = "";
        advice = "";
        Log("game started: " + path + ", autoPick=" + B(G(settings, "autoPick")));
    }

    void ShowAdvice(string text)
    {
        advice = text;
        overlay.Text2.Text = text;
        if (N(G(settings, "overlay"), 1) != 0 && !overlay.Visible) overlay.Show();
    }

    void OnGameLine(string line)
    {
        if (!line.StartsWith("rogue: {")) return;
        Dictionary<string, object> j;
        try { j = D(json.DeserializeObject(line.Substring(7))); } catch { return; }
        if (j == null) return;
        string type = S(G(j, "type"));
        if (type == "picked" || type == "resume" || type == "choices" || type == "defeat" || type == "victory" || type == "start") pendingKey = 0;
        if (type == "picked" || type == "resume") screenRerolls = 0;
        switch (type)
        {
            case "ready":
                recordedIndex = -1;
                build = SelectBuild(S(G(j, "class")));
                owned = new Dictionary<string, int>();
                amulet = null;
                jewels = new Dictionary<string, string>();
                runLuck = 0;
                spellDmg = new Dictionary<string, double>();
                totalDmg = 0;
                jewelLuck = new Dictionary<string, double>();
                amuletLuck = 0;
                amuletUps = 0;
                if (build == null) ShowAdvice(lang == "fr" ? "Aucun build pour " + S(G(j, "class")) + " dans le compagnon" : "No build for " + S(G(j, "class")) + " in the companion");
                Log("hero " + S(G(j, "class")) + ", build " + S(G(build, "name")));
                break;
            case "choices":
                if (build == null) return;
                Advice a = Advise(j);
                if (a.Key == "r") screenRerolls++;
                ShowAdvice(a.Text);
                Log(S(G(j, "why")) + " lvl " + S(G(j, "level")) + ": " + a.Text);
                if (B(G(settings, "autoPick")) && a.Key != null)
                {
                    uint vk = a.Key == "r" ? 0x52u : (uint)(0x30 + int.Parse(a.Key));
                    System.Windows.Forms.Timer t = new System.Windows.Forms.Timer { Interval = (DateTime.Now - lastKey).TotalMilliseconds < 2500 ? 1500 : 600 };
                    lastKey = DateTime.Now;
                    t.Tick += delegate
                    {
                        t.Stop();
                        t.Dispose();
                        if (!running) return;
                        pendingKey = vk;
                        pendingTries = 0;
                        SendKey(vk);
                        Log("sent key " + a.Key);
                    };
                    t.Start();
                    if (a.Pick != null) Took(a.Pick);
                }
                break;
            case "resume":
            case "start":
                if (build != null) overlay.Hide();
                break;
            case "defeat":
            case "victory":
                if (build != null) overlay.Hide();
                try { RecordRun(j); } catch (Exception ex) { Log("stats error: " + ex.Message); }
                break;
        }
    }

    void Took(object card)
    {
        CardInfo info = Info(card);
        if (info.Type == "spell" && info.Key != null) owned[info.Key] = (int)N(G(card, "rank"), 1);
        if (info.Cat == "amulets" && info.Key != null) { amuletUps = info.Key == amulet ? amuletUps + 1 : 0; amulet = info.Key; }
        if (info.Type == "jewel" && info.Key != null && info.Cat != "amulets") jewels[info.Key] = info.Cat;
        if (info.Type == "jewel")
        {
            double cl = CardLuck(card);
            if (info.Cat == "amulets") amuletLuck = cl;
            else if (info.Key != null) { jewelLuck[info.Key] = cl; runLuck = jewelLuck.Values.Sum(); }
            Log("took " + S(G(card, "title")) + " (" + S(G(card, "rarityName")) + "): " + (S(G(card, "lines")) ?? "").Replace("\n", " / "));
        }
    }

    static double CardLuck(object card)
    {
        Match m = Regex.Match((S(G(card, "lines")) ?? "") + " " + (S(G(card, "text")) ?? ""), @"(?:\+?[\d.,]+\s*%\s*»\s*)?\+?([\d.,]+)\s*%\s*(de chance|luck)");
        return m.Success ? double.Parse(m.Groups[1].Value.Replace(",", "."), System.Globalization.CultureInfo.InvariantCulture) : 0;
    }

    Dictionary<string, object> SelectBuild(string cls)
    {
        heroClass = A(G(data, "classes")).Select(D).FirstOrDefault(c => S(c["key"]) == cls || S(G(c["name"], "en")) == cls || S(G(c["name"], "fr")) == cls);
        return heroClass == null ? null : ActiveBuild(state, S(heroClass["key"]));
    }

    class CardInfo { public string Type, Cat, Key, Spell; }

    CardInfo Info(object card)
    {
        string kind = S(G(card, "kind")), icon = S(G(card, "icon")), name = S(G(card, "name")), title = S(G(card, "title")) ?? "";
        if (kind == "new" || kind == "upgrade")
        {
            foreach (object s in A(G(heroClass, "spells")))
                if (S(G(s, "icon")) == icon || S(G(G(s, "name"), "en")) == name || S(G(G(s, "name"), "fr")) == name)
                    return new CardInfo { Type = "spell", Key = S(G(s, "key")) };
            return new CardInfo { Type = "spell" };
        }
        string cat = kind == "ring" ? "rings" : kind == "trinket" ? "trinkets" : "amulets";
        foreach (object s in A(G(heroClass, "spells")))
        {
            string sk = S(G(s, "key"));
            object leg = G(G(data, "legendaries"), sk);
            if (leg != null && icon == S(G(leg, "icon")) && (title.Contains(S(G(G(s, "name"), "fr"))) || title.Contains(S(G(G(s, "name"), "en")))))
                return new CardInfo { Type = "jewel", Cat = "amulets", Key = "leg:" + sk, Spell = sk };
        }
        if (cat == "amulets" && amulet != null && amulet.StartsWith("leg:"))
        {
            object worn = G(G(data, "legendaries"), amulet.Substring(4));
            if (worn != null && icon == S(G(worn, "icon"))) return new CardInfo { Type = "jewel", Cat = "amulets", Key = amulet, Spell = amulet.Substring(4) };
        }
        foreach (object jw in A(G(data, cat)))
            if (S(G(jw, "icon")) == icon || S(G(G(jw, "name"), "en")) == name || S(G(G(jw, "name"), "fr")) == name)
                return new CardInfo { Type = "jewel", Cat = cat, Key = S(G(jw, "key")) };
        return new CardInfo { Type = "jewel", Cat = cat };
    }

    double JewelLuck(string cat, string key)
    {
        object jw = A(G(data, cat)).FirstOrDefault(x => S(G(x, "key")) == key);
        double sum = 0;
        foreach (object line in A(G(G(jw, "desc"), "en")))
        {
            Match m = Regex.Match(S(line), @"^\+([\d.]+)% luck$");
            if (m.Success) sum += double.Parse(m.Groups[1].Value, System.Globalization.CultureInfo.InvariantCulture);
        }
        return sum;
    }

    double Luck()
    {
        double l = runLuck, measured;
        if (heroClass != null && measuredLuck.TryGetValue(S(heroClass["key"]), out measured)) l += measured;
        else
        {
            Dictionary<string, object> tal = D(G(build, "talents"));
            foreach (object tree in A(G(heroClass, "trees")))
                foreach (object t in A(G(tree, "talents")))
                    if (Regex.IsMatch(S(G(G(t, "desc"), "en")) ?? "", "your luck by \\{v\\}%") && tal != null && tal.ContainsKey(S(G(t, "key"))))
                        l += N(G(t, "v"), 0) * N(tal[S(G(t, "key"))], 0);
        }
        l += amuletLuck;
        return l;
    }

    double ExpectedRarity(double luck, double infl)
    {
        double total = 0, sum = 0;
        for (int r = 0; r < 5; r++)
        {
            double w = BaseOdds[r] * Math.Pow(1 + luck / 100, r);
            total += w;
            sum += w * (1 + infl * r);
        }
        return sum / total;
    }

    double Boost() { return N(G(G(build, "rules"), "boost"), 2); }


    int recordedIndex = -1;
    double victoryTime;

    void RecordRun(Dictionary<string, object> j)
    {
        ReadCombat();
        string rf = Path.Combine(dataDir, "runs.json");
        List<object> runs = File.Exists(rf) ? A(json.DeserializeObject(File.ReadAllText(rf, Utf8))).ToList() : new List<object>();
        Dictionary<string, object> r = new Dictionary<string, object>();
        foreach (string k in new[] { "time", "level", "kills", "elites", "guardians", "bosses", "damage", "taken", "gold", "chests", "hero", "race", "bg" })
            r[k] = G(j, k);
        r["result"] = S(G(j, "type"));
        r["left"] = G(j, "left");
        r["date"] = DateTime.Now.ToString("yyyy-MM-ddTHH:mm:ss");
        r["class"] = heroClass != null ? S(heroClass["key"]) : S(G(j, "class"));
        r["build"] = S(G(build, "name"));
        string specKey = null;
        Dictionary<string, object> tal = D(G(build, "talents"));
        if (heroClass != null && tal != null)
        {
            double best = 0;
            int ti = 0;
            foreach (object tree in A(G(heroClass, "trees")))
            {
                double pts = A(G(tree, "talents")).Sum(t => tal.ContainsKey(S(G(t, "key"))) ? N(tal[S(G(t, "key"))], 0) : 0);
                if (pts > best) { best = pts; specKey = S(heroClass["key"]) + "-" + ti; }
                ti++;
            }
        }
        r["spec"] = specKey;
        double time = N(G(j, "time"), 0);
        r["dps"] = time > 0 ? Math.Round(N(G(j, "damage"), 0) / time, 1) : 0;
        r["spells"] = owned.ToDictionary(kv => kv.Key, kv => (object)kv.Value);
        r["jewels"] = jewels.Keys.Concat(amulet != null ? new[] { amulet } : new string[0]).ToArray();
        r["luck"] = Math.Round(Luck());
        r["dmg"] = spellDmg.OrderByDescending(kv => kv.Value).ToDictionary(kv => kv.Key, kv => (object)Math.Round(kv.Value));
        if (recordedIndex >= 0 && recordedIndex < runs.Count && S(G(runs[recordedIndex], "result")) == "victory")
        {
            r["result"] = "victory";
            r["endless"] = true;
            r["endlessTime"] = Math.Round(time - victoryTime, 1);
            runs[recordedIndex] = r;
        }
        else
        {
            runs.Add(r);
            recordedIndex = runs.Count - 1;
            if (S(r["result"]) == "victory") victoryTime = time;
        }
        File.WriteAllText(rf, json.Serialize(runs), Utf8);
        Log("run recorded: " + r["result"] + " lvl " + r["level"] + " " + Math.Round(time) + "s dps " + r["dps"]);
    }

    double BuildWeight(string key)
    {
        List<object> sp = A(G(build, "spells")).ToList();
        int i = sp.FindIndex(x => S(G(x, "key")) == key);
        return i < 0 ? 0 : N(G(sp[i], "w"), 3) * (i >= 6 ? 0.5 : 1);
    }

    double JewelWeight(string cat, string key)
    {
        List<string> list = A(G(build, cat)).Select(S).ToList();
        int idx = list.IndexOf(key);
        double set = N(G(G(build, "jw"), key), 0);
        double w = idx >= 0 ? (set > 0 ? set : idx < (cat == "amulets" ? 1 : 2) ? 5 : 3) * 2 : 0;
        if (key.StartsWith("leg:"))
        {
            string sk = key.Substring(4);
            w = Math.Max(w, BuildWeight(sk) * Boost()) * DmgFactor(sk);
        }
        return w;
    }

    double SpellWeight(string key)
    {
        double w = 0;
        int i = 0;
        foreach (object s in A(G(build, "spells")))
        {
            if (S(G(s, "key")) == key) { w = N(G(s, "w"), 3); if (i >= 6) w *= 0.5; }
            i++;
        }
        if (N(G(G(build, "rules"), "adapt"), 1) != 0)
        {
            if (owned.ContainsKey(key)) w = Math.Max(w, 1) * 1.25;
            if (amulet == "leg:" + key) w = Math.Max(w, 2) * Boost();
        }
        return w;
    }

    class Advice { public string Text, Key; public object Pick; }

    Advice Advise(Dictionary<string, object> j)
    {
        Dictionary<string, object> rules = D(G(build, "rules")) ?? new Dictionary<string, object>();
        Dictionary<string, object> ban = D(G(build, "ban")) ?? new Dictionary<string, object>();
        double infl = N(G(rules, "rarity"), 50) / 100;
        int lvl = (int)N(G(j, "level"), 1);
        int rerolls = (int)N(G(j, "rerolls"), 0), reserve = (int)N(G(rules, "reserve"), 1);
        bool jewelScreen = S(G(j, "why")) != "levelup";
        bool reroll = N(G(rules, "reroll"), 1) == 1 && !(jewelScreen && lvl < N(G(rules, "fallbackLevel"), 10) && screenRerolls >= 2);
        bool fr = lang == "fr";
        List<object> cards = A(G(j, "choices")).ToList();
        int best = 0, banIdx = 0;
        double bestScore = 0;
        bool bestTarget = false;
        for (int i = 1; i <= cards.Count; i++)
        {
            object card = cards[i - 1];
            CardInfo info = Info(card);
            string replIcon = S(G(card, "replacesIcon")), replText = S(G(card, "replacesText")) ?? "";
            if (replIcon != null && info.Cat == "amulets")
            {
                foreach (object a in A(G(data, "amulets"))) if (S(G(a, "icon")) == replIcon) amulet = S(G(a, "key"));
                foreach (object s in A(G(heroClass, "spells")))
                {
                    object leg = G(G(data, "legendaries"), S(G(s, "key")));
                    if (leg != null && S(G(leg, "icon")) == replIcon && (replText.Contains(S(G(G(s, "name"), "fr"))) || replText.Contains(S(G(G(s, "name"), "en"))))) amulet = "leg:" + S(G(s, "key"));
                }
            }
            if (info.Type == "spell" && S(G(card, "kind")) == "upgrade" && info.Key != null) owned[info.Key] = (int)N(G(card, "rank"), 2) - 1;
            if (info.Key != null && ban.ContainsKey(info.Key)) { if (banIdx == 0) banIdx = i; continue; }
            double baseW = 0;
            bool target = false;
            if (info.Type == "spell" && info.Key != null)
            {
                baseW = SpellWeight(info.Key);
                List<object> sp = A(G(build, "spells")).ToList();
                int idx = sp.FindIndex(x => S(G(x, "key")) == info.Key);
                target = idx >= 0 && idx < 6;
            }
            else if (info.Key != null)
            {
                int want = info.Cat == "amulets" ? 1 : 2;
                List<string> list = A(G(build, info.Cat)).Select(S).ToList();
                int idx = list.IndexOf(info.Key);
                double w = JewelWeight(info.Cat, info.Key);
                bool upgrade = info.Cat == "amulets" ? info.Key == amulet : jewels.ContainsKey(info.Key);
                if (upgrade)
                {
                    baseW = Math.Max(w, 4);
                    target = true;
                }
                else if (info.Cat == "amulets")
                {
                    double wornW = amulet != null ? JewelWeight("amulets", amulet) * (1 + 0.25 * amuletUps) : 0;
                    if (w > wornW) { baseW = w; target = idx == 0 || info.Spell != null; }
                }
                else if (jewels.Values.Count(v => v == info.Cat) < 2)
                {
                    if (idx >= 0 && idx < want) { baseW = w; target = true; }
                    else if (idx >= want && lvl >= N(G(rules, "fallbackLevel"), 10)) baseW = w;
                }
            }
            double score = baseW * (1 + infl * N(G(card, "rarity"), 0));
            if (score > bestScore) { bestScore = score; best = i; bestTarget = target; }
        }
        double luck = Luck();
        string luckTxt = luck > 0 ? (fr ? " · chance " : " · luck ") + Math.Round(luck) + " %" : "";
        if (best > 0 && !bestTarget && reroll && rerolls > reserve)
        {
            double top = A(G(build, "spells")).Take(6).Select(x => N(G(x, "w"), 3)).DefaultIfEmpty(3).Max();
            if (bestScore < 0.4 * top * ExpectedRarity(luck, infl))
                return new Advice { Text = (fr ? "Carte moyenne, relancer (R) : " + rerolls + " restantes" : "Average card, reroll (R): " + rerolls + " left") + luckTxt, Key = "r" };
        }
        if (best > 0)
        {
            object c = cards[best - 1];
            return new Advice { Text = (fr ? "Prendre " + best + " : " : "Take " + best + ": ") + S(G(c, "title")) + " (" + S(G(c, "rarityName")) + ")", Key = best.ToString(), Pick = c };
        }
        bool canBanish = banIdx > 0 && N(G(j, "banishes"), 0) > 0;
        bool auto = B(G(settings, "autoPick"));
        if (canBanish && !(auto && reroll && rerolls > reserve))
            return new Advice { Text = fr ? "Bannir la carte " + banIdx + " : " + S(G(cards[banIdx - 1], "title")) + " (rafraîchit les cartes)" : "Banish card " + banIdx + ": " + S(G(cards[banIdx - 1], "title")) + " (refreshes the cards)" };
        if (reroll && rerolls > reserve)
            return new Advice { Text = (fr ? "Rien du build : relancer (R), " + rerolls + " restantes" : "Nothing from the build: reroll (R), " + rerolls + " left") + luckTxt, Key = "r" };
        if (canBanish)
            return new Advice { Text = fr ? "Bannir la carte " + banIdx + " : " + S(G(cards[banIdx - 1], "title")) + " (rafraîchit les cartes)" : "Banish card " + banIdx + ": " + S(G(cards[banIdx - 1], "title")) + " (refreshes the cards)" };
        if (B(G(j, "skip")))
            return new Advice { Text = fr ? "Rien du build : skip (+" + S(G(j, "skipGold")) + " or)" : "Nothing from the build: skip (+" + S(G(j, "skipGold")) + " gold)" };
        int pick = 1, pr = -1;
        for (int i = 1; i <= cards.Count; i++)
        {
            CardInfo info = Info(cards[i - 1]);
            if (info.Key != null && ban.ContainsKey(info.Key)) continue;
            int r = (int)N(G(cards[i - 1], "rarity"), 0);
            if (r > pr) { pr = r; pick = i; }
        }
        return new Advice { Text = (fr ? "Rien du build, pas de skip : prendre " + pick + " : " : "Nothing from the build, no skip: take " + pick + ": ") + S(G(cards[pick - 1], "title")), Key = pick.ToString(), Pick = cards[pick - 1] };
    }
}
