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
[assembly: AssemblyVersion("1.0.0.0")]
[assembly: AssemblyFileVersion("1.0.0.0")]

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
    const int Port = 47821;
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
        using (Mutex m = new Mutex(true, "AS-Companion-ZKYXYKZ", out first))
        {
            if (!first)
            {
                OpenUi();
                return;
            }
            Application.EnableVisualStyles();
            Application.Run(new Companion(args.Contains("-NoBrowser")));
        }
    }

    Companion(bool noBrowser)
    {
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
        menu.MenuItems.Add("Builder", delegate { ui = OpenUi(); });
        menu.MenuItems.Add("Quitter / Quit", delegate { Close(); });
        tray.ContextMenu = menu;
        tray.DoubleClick += delegate { ui = OpenUi(); };
        listener = new HttpListener();
        listener.Prefixes.Add(Url);
        listener.Start();
        listener.BeginGetContext(OnContext, null);
        Log("server started on " + Url);
        if (!noBrowser) ui = OpenUi();
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

    static Process OpenUi()
    {
        string[] candidates = {
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86), @"Microsoft\Edge\Application\msedge.exe"),
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), @"Microsoft\Edge\Application\msedge.exe"),
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
            using (System.Management.ManagementObjectSearcher q = new System.Management.ManagementObjectSearcher("SELECT CommandLine FROM Win32_Process WHERE Name = 'msedge.exe'"))
                foreach (System.Management.ManagementObject o in q.Get())
                {
                    string cmd = o["CommandLine"] as string;
                    if (cmd != null && cmd.IndexOf(uiDir, StringComparison.OrdinalIgnoreCase) >= 0) return true;
                }
            return false;
        }
        catch { return true; }
    }

    void OnTick(object sender, EventArgs e)
    {
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
        if (ui != null && !running && DateTime.Now > uiCheck)
        {
            uiCheck = DateTime.Now.AddSeconds(2);
            if (ui.HasExited && !UiAlive()) { Log("ui closed"); Close(); }
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
            if (path == "/api/status")
            {
                Respond(ctx, 200, "application/json", Utf8.GetBytes(json.Serialize(new Dictionary<string, object> { { "running", running }, { "advice", advice }, { "error", error } })));
                return;
            }
            if (path == "/api/browse" && method == "POST")
            {
                string picked = Browse(new StreamReader(ctx.Request.InputStream, Utf8).ReadToEnd());
                Respond(ctx, 200, "application/json", Utf8.GetBytes(json.Serialize(new Dictionary<string, object> { { "path", picked } })));
                return;
            }
            if (path == "/api/open" && method == "POST")
            {
                string target = new StreamReader(ctx.Request.InputStream, Utf8).ReadToEnd();
                if (target.StartsWith("https://x.com/") || target.StartsWith("https://github.com/")) Process.Start(target);
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

    string DefaultGamePath()
    {
        foreach (string p in new[] { Path.Combine(exeDir, "AzerothSurvivors.exe"), Path.Combine(Path.GetDirectoryName(exeDir.TrimEnd('\\')), "AzerothSurvivors.exe") })
            if (File.Exists(p)) return p;
        return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), @"Downloads\AzerothSurvivors\AzerothSurvivors\AzerothSurvivors.exe");
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
        if (string.IsNullOrEmpty(S(G(st, "gamePath")))) st["gamePath"] = DefaultGamePath();
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
        string path = S(G(settings, "gamePath"));
        if (string.IsNullOrEmpty(path)) path = DefaultGamePath();
        if (!File.Exists(path)) { error = (GameLang().StartsWith("fr") ? "Jeu introuvable : " : "Game not found: ") + path; return; }
        string l = S(G(settings, "lang"));
        lang = !string.IsNullOrEmpty(l) && l != "auto" ? l : GameLang().StartsWith("fr") ? "fr" : "en";
        WriteGateway(s, Path.GetDirectoryName(path));
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
                build = SelectBuild(S(G(j, "class")));
                owned = new Dictionary<string, int>();
                amulet = null;
                jewels = new Dictionary<string, string>();
                runLuck = 0;
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
            case "defeat":
            case "victory":
                if (build != null) overlay.Hide();
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
        if (key.StartsWith("leg:")) w = Math.Max(w, BuildWeight(key.Substring(4)) * Boost());
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
