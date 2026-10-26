param(
  [int]$Port = 47821,
  [switch]$NoBrowser
)
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class GameKeys {
  [DllImport("user32.dll")] static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
  [DllImport("user32.dll")] static extern uint MapVirtualKey(uint c, uint t);
  [DllImport("user32.dll")] static extern bool ShowWindow(IntPtr h, int c);
  [DllImport("kernel32.dll")] static extern IntPtr GetConsoleWindow();
  public static void HideConsole() { ShowWindow(GetConsoleWindow(), 0); }
  public static void Press(IntPtr h, uint vk) {
    uint sc = MapVirtualKey(vk, 0);
    PostMessage(h, 0x100, (IntPtr)vk, (IntPtr)(1 | (sc << 16)));
    System.Threading.Thread.Sleep(60);
    PostMessage(h, 0x101, (IntPtr)vk, (IntPtr)(1 | (sc << 16) | (3u << 30)));
  }
}
"@
$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$web = Join-Path $root "web"
$stateFile = Join-Path $root "state.json"
$logFile = Join-Path $root "companion.log"
$utf8 = New-Object System.Text.UTF8Encoding($false)
function Log($m) { [System.IO.File]::AppendAllText($logFile, ("{0:HH:mm:ss} {1}`r`n" -f (Get-Date), $m), $utf8) }

$data = [System.IO.File]::ReadAllText((Join-Path $web "data.json"), $utf8) | ConvertFrom-Json

function DefaultGamePath {
  $local = Join-Path (Split-Path $root) "AzerothSurvivors.exe"
  if (Test-Path $local) { return $local }
  return "$env:USERPROFILE\Downloads\AzerothSurvivors\AzerothSurvivors\AzerothSurvivors.exe"
}
function GameLang {
  $dir = if ($env:WOW_ROGUE_SAVE) { Split-Path $env:WOW_ROGUE_SAVE } else { Join-Path $env:APPDATA "wenilla-rogue" }
  $f = Join-Path $dir "language.txt"
  if (Test-Path $f) { return ([System.IO.File]::ReadAllText($f)).Trim() }
  return "en"
}
function LoadState {
  if (Test-Path $stateFile) { return [System.IO.File]::ReadAllText($stateFile, $utf8) }
  return '{"builds":[],"active":{},"settings":{},"nextId":1}'
}
function StateJson {
  $s = LoadState | ConvertFrom-Json
  if (-not $s.settings) { $s | Add-Member settings ([pscustomobject]@{}) -Force }
  if (-not $s.settings.gamePath) { $s.settings | Add-Member gamePath (DefaultGamePath) -Force }
  $s.settings | Add-Member gameLang (GameLang) -Force
  return ($s | ConvertTo-Json -Depth 20 -Compress)
}

$status = @{ running = $false; advice = ""; error = "" }
$game = $null
$queue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
$run = @{}
$build = $null
$settings = $null
$heroClass = $null
$lang = "en"

$form = New-Object System.Windows.Forms.Form
$form.FormBorderStyle = "None"; $form.TopMost = $true; $form.ShowInTaskbar = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 24); $form.Opacity = 0.9
$form.Width = 820; $form.Height = 46; $form.StartPosition = "Manual"
$scr = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$form.Left = $scr.X + ($scr.Width - $form.Width) / 2; $form.Top = $scr.Y + 110
$label = New-Object System.Windows.Forms.Label
$label.Dock = "Fill"; $label.TextAlign = "MiddleCenter"; $label.ForeColor = [System.Drawing.Color]::FromArgb(240, 190, 80)
$label.Font = New-Object System.Drawing.Font("Segoe UI", 15, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($label)
$form.Show(); $form.Hide()

function ClassByName($name) {
  foreach ($c in $data.classes) { if ($c.key -eq $name -or $c.name.en -eq $name -or $c.name.fr -eq $name) { return $c } }
  return $null
}
function LuaStr($s) { return '"' + ([string]$s).Replace('\', '\\').Replace('"', '\"').Replace("`n", '\n').Replace("`r", '') + '"' }
function Loc($o) { if ($o -and $o.$lang) { return $o.$lang } elseif ($o) { return $o.en } else { return "" } }

function WriteGateway($s, $gameDir) {
  $cfgHome = if ($env:BENILLA_HOME) { $env:BENILLA_HOME } else { Join-Path $gameDir "benilla-config" }
  $dir = Join-Path $cfgHome "saved"
  New-Item -ItemType Directory -Force $dir | Out-Null
  $L = New-Object System.Collections.Generic.List[string]
  $L.Add("SurvivorsBuildsDB = {")
  $L.Add("  link = {")
  $L.Add("    launched = " + [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() + ",")
  $L.Add("    autoPick = " + $(if ($s.settings.autoPick) { "true" } else { "false" }) + ",")
  $L.Add("    lang = " + (LuaStr $lang) + ",")
  $L.Add("    builds = {")
  foreach ($c in $data.classes) {
    $id = $s.active.($c.key)
    $b = $s.builds | Where-Object { $_.class -eq $c.key -and ($_.id -eq $id -or -not $id) } | Select-Object -First 1
    if (-not $b) { continue }
    $L.Add("      " + $c.key + " = {")
    $L.Add("        name = " + (LuaStr $b.name) + ",")
    $L.Add("        spells = {")
    foreach ($sp in $b.spells) {
      $d = $c.spells | Where-Object { $_.key -eq $sp.key } | Select-Object -First 1
      if ($d) { $L.Add("          { key = " + (LuaStr $sp.key) + ", name = " + (LuaStr (Loc $d.name)) + ", w = " + [int]$sp.w + " },") }
    }
    $L.Add("        },")
    $L.Add("        names = {")
    foreach ($d in $c.spells) { $L.Add("          " + $d.key + " = " + (LuaStr (Loc $d.name)) + ",") }
    $L.Add("        },")
    $bans = @()
    foreach ($k in $b.ban.PSObject.Properties.Name) { $bans += (JewelName $c $k) }
    $L.Add("        bans = { " + (($bans | ForEach-Object { LuaStr $_ }) -join ", ") + " },")
    $jw = @()
    foreach ($cat in @("rings", "trinkets", "amulets")) { if ($b.$cat -and $b.$cat.Count -gt 0) { $jw += (JewelName $c $b.$cat[0]) } }
    $L.Add("        jewels = { " + (($jw | ForEach-Object { LuaStr $_ }) -join ", ") + " },")
    $L.Add("        reserve = " + [int]$b.rules.reserve + ", banishes = " + [int]$b.rules.banishes + ", reroll = " + [int]$b.rules.reroll + ",")
    $L.Add("      },")
  }
  $L.Add("    },")
  $L.Add("  },")
  $L.Add("}")
  [System.IO.File]::WriteAllText((Join-Path $dir "SurvivorsBuilds.lua"), ($L -join "`n") + "`n", $utf8)
}
function JewelName($c, $k) {
  if ($k.StartsWith("leg:")) {
    $sk = $k.Substring(4)
    $l = $data.legendaries.$sk
    $d = $c.spells | Where-Object { $_.key -eq $sk } | Select-Object -First 1
    if ($l -and $d) { return (Loc $l.family) + " : " + (Loc $d.name) }
    return $k
  }
  foreach ($cat in @("rings", "trinkets", "amulets")) { foreach ($j in $data.$cat) { if ($j.key -eq $k) { return (Loc $j.name) } } }
  foreach ($d in $c.spells) { if ($d.key -eq $k) { return (Loc $d.name) } }
  return $k
}

function Launch {
  $s = [System.IO.File]::ReadAllText($stateFile, $utf8) | ConvertFrom-Json
  $script:settings = $s.settings
  $path = if ($s.settings.gamePath) { $s.settings.gamePath } else { DefaultGamePath }
  if (-not (Test-Path $path)) { $status.error = "Jeu introuvable : $path"; return }
  $script:lang = if ($s.settings.lang -and $s.settings.lang -ne "auto") { $s.settings.lang } else { $(if ((GameLang) -like "fr*") { "fr" } else { "en" }) }
  WriteGateway $s (Split-Path $path)
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $path; $psi.WorkingDirectory = Split-Path $path
  $psi.UseShellExecute = $false; $psi.RedirectStandardOutput = $true
  $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
  $script:game = [System.Diagnostics.Process]::Start($psi)
  Register-ObjectEvent -InputObject $script:game -EventName OutputDataReceived -Action { if ($EventArgs.Data) { $Event.MessageData.Enqueue($EventArgs.Data) } } -MessageData $queue | Out-Null
  $script:game.BeginOutputReadLine()
  $script:state = $s
  $status.running = $true; $status.error = ""; $status.advice = ""
  Log "game started: $path, autoPick=$($s.settings.autoPick)"
}

function SelectBuild($cls) {
  $c = ClassByName $cls
  if (-not $c) { return $null }
  $id = $script:state.active.($c.key)
  $b = $script:state.builds | Where-Object { $_.class -eq $c.key -and ($_.id -eq $id -or -not $id) } | Select-Object -First 1
  $script:heroClass = $c
  return $b
}

function CardInfo($card) {
  $c = $script:heroClass
  if ($card.kind -in @("new", "upgrade")) {
    foreach ($s in $c.spells) { if ($s.icon -eq $card.icon -or $s.name.en -eq $card.name -or $s.name.fr -eq $card.name) { return @{ type = "spell"; key = $s.key } } }
    return @{ type = "spell"; key = $null }
  }
  $cat = switch ($card.kind) { "ring" { "rings" } "trinket" { "trinkets" } default { "amulets" } }
  foreach ($s in $c.spells) {
    if ($card.title -and ($card.title.Contains($s.name.fr) -or $card.title.Contains($s.name.en)) -and $data.legendaries.($s.key) -and $card.icon -eq $data.legendaries.($s.key).icon) { return @{ type = "jewel"; cat = "amulets"; key = "leg:" + $s.key; spell = $s.key } }
  }
  foreach ($j in $data.$cat) { if ($j.icon -eq $card.icon -or $j.name.en -eq $card.name -or $j.name.fr -eq $card.name) { return @{ type = "jewel"; cat = $cat; key = $j.key } } }
  return @{ type = "jewel"; cat = $cat; key = $null }
}

function SpellWeight($key) {
  $b = $script:build
  $w = 0
  $i = 0
  foreach ($s in $b.spells) {
    if ($s.key -eq $key) { $w = [double]$s.w; if ($i -ge 6) { $w = $w * 0.5 } }
    $i++
  }
  if ($b.rules.adapt -ne 0) {
    if ($run.owned.ContainsKey($key)) { $w = [math]::Max($w, 1) * 1.25 }
    if ($run.amulet -eq ("leg:" + $key)) { $w = [math]::Max($w, 2) * [double]$(if ($b.rules.boost) { $b.rules.boost } else { 2 }) }
  }
  return $w
}

function Advise($j) {
  $b = $script:build
  $infl = [double]$b.rules.rarity / 100
  $lvl = [int]$j.level
  $best = 0; $bestScore = 0; $ban = 0; $i = 0
  foreach ($card in $j.choices) {
    $i++
    $info = CardInfo $card
    if ($card.replacesIcon -and $info.cat -eq "amulets") {
      foreach ($a in $data.amulets) { if ($a.icon -eq $card.replacesIcon) { $run.amulet = $a.key } }
      foreach ($s in $script:heroClass.spells) { if ($data.legendaries.($s.key) -and $data.legendaries.($s.key).icon -eq $card.replacesIcon -and $card.replacesText -and ($card.replacesText.Contains($s.name.fr) -or $card.replacesText.Contains($s.name.en))) { $run.amulet = "leg:" + $s.key } }
    }
    if ($info.type -eq "spell" -and $card.kind -eq "upgrade" -and $info.key) { $run.owned[$info.key] = [int]$card.rank - 1 }
    if ($info.key -and $b.ban.PSObject.Properties.Name -contains $info.key) { if (-not $ban) { $ban = $i }; continue }
    $base = 0
    if ($info.type -eq "spell" -and $info.key) {
      $base = SpellWeight $info.key
    } elseif ($info.key) {
      $want = if ($info.cat -eq "amulets") { 1 } else { 2 }
      $list = @($b.($info.cat))
      $idx = [array]::IndexOf($list, $info.key)
      if ($idx -ge 0 -and $idx -lt $want) { $base = 10 - $idx }
      elseif ($idx -ge $want) {
        if ($info.cat -eq "amulets" -or $lvl -ge [int]$b.rules.fallbackLevel) { $base = [math]::Max(1, 5 - ($idx - $want)) }
      }
      if ($info.cat -eq "amulets" -and $run.amulet) {
        $worn = [array]::IndexOf($list, $run.amulet)
        if ($worn -ge 0 -and ($idx -lt 0 -or $worn -le $idx)) { $base = 0 }
      }
      if ($base -eq 0 -and $info.spell -and $b.rules.adapt -ne 0) {
        $sw = SpellWeight $info.spell
        if ($sw -gt 0 -and -not ($run.amulet -and [array]::IndexOf($list, $run.amulet) -ge 0)) { $base = $sw * [double]$(if ($b.rules.boost) { $b.rules.boost } else { 2 }) }
      }
    }
    $score = $base * (1 + $infl * [double]$card.rarity)
    if ($score -gt $bestScore) { $bestScore = $score; $best = $i }
  }
  $fr = $lang -eq "fr"
  if ($best) {
    $c = $j.choices[$best - 1]
    return @{ text = $(if ($fr) { "Prendre $best : $($c.title) ($($c.rarityName))" } else { "Take ${best}: $($c.title) ($($c.rarityName))" }); key = "$best"; pick = $c }
  }
  if ($ban -and [int]$j.banishes -gt 0) { return @{ text = $(if ($fr) { "Bannir la carte $ban : $($j.choices[$ban - 1].title)" } else { "Banish card ${ban}: $($j.choices[$ban - 1].title)" }); key = $null } }
  if ([int]$b.rules.reroll -eq 1 -and [int]$j.rerolls -gt [int]$b.rules.reserve) { return @{ text = $(if ($fr) { "Rien du build : relancer (R), $($j.rerolls) restantes" } else { "Nothing from the build: reroll (R), $($j.rerolls) left" }); key = "r" } }
  if ($j.skip -eq $true) { return @{ text = $(if ($fr) { "Rien du build : skip (+$($j.skipGold) or)" } else { "Nothing from the build: skip (+$($j.skipGold) gold)" }); key = $null } }
  $pick = 1; $pr = -1; $i = 0
  foreach ($card in $j.choices) {
    $i++
    $info = CardInfo $card
    if ($info.key -and $b.ban.PSObject.Properties.Name -contains $info.key) { continue }
    if ([int]$card.rarity -gt $pr) { $pr = [int]$card.rarity; $pick = $i }
  }
  return @{ text = $(if ($fr) { "Rien du build, pas de skip : prendre $pick : $($j.choices[$pick - 1].title)" } else { "Nothing from the build, no skip: take ${pick}: $($j.choices[$pick - 1].title)" }); key = "$pick"; pick = $j.choices[$pick - 1] }
}

function OnGameLine($line) {
  if (-not $line.StartsWith("rogue: {")) { return }
  try { $j = $line.Substring(7) | ConvertFrom-Json } catch { return }
  switch ($j.type) {
    "ready" {
      $script:build = SelectBuild $j.class
      $script:run = @{ owned = @{}; amulet = $null }
      if (-not $script:build) {
        $status.advice = $(if ($lang -eq "fr") { "Aucun build pour $($j.class) dans le compagnon" } else { "No build for $($j.class) in the companion" })
        $label.Text = $status.advice
        if ($settings.overlay -ne 0) { $form.Show() }
      }
      Log "hero $($j.class), build $($script:build.name)"
    }
    "choices" {
      if (-not $script:build) { return }
      $a = Advise $j
      $status.advice = $a.text
      $label.Text = $a.text
      if ($settings.overlay -ne 0) { $form.Show() }
      Log "$($j.why) lvl $($j.level): $($a.text)"
      if ($settings.autoPick -and $a.key) {
        Start-Sleep -Milliseconds 600
        $game.Refresh()
        $vk = if ($a.key -eq "r") { 0x52 } else { 0x30 + [int]$a.key }
        [GameKeys]::Press($game.MainWindowHandle, [uint32]$vk)
        if ($a.pick) {
          $info = CardInfo $a.pick
          if ($info.type -eq "spell" -and $info.key) { $run.owned[$info.key] = $(if ($a.pick.rank) { [int]$a.pick.rank } else { 1 }) }
          if ($info.cat -eq "amulets" -and $info.key) { $run.amulet = $info.key }
        }
        Log "sent key $($a.key)"
      }
    }
    { $_ -in @("resume", "start", "defeat", "victory") } {
      if ($script:build) { $form.Hide() }
    }
  }
}

function Respond($ctx, $code, $type, [byte[]]$bytes) {
  $ctx.Response.StatusCode = $code
  $ctx.Response.ContentType = $type
  $ctx.Response.Headers.Add("Cache-Control", "no-store")
  $ctx.Response.ContentLength64 = $bytes.Length
  $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
  $ctx.Response.OutputStream.Close()
}
function Handle($ctx) {
  $path = $ctx.Request.Url.AbsolutePath
  $method = $ctx.Request.HttpMethod
  try {
    if ($path -eq "/api/state" -and $method -eq "GET") { Respond $ctx 200 "application/json" $utf8.GetBytes((StateJson)); return }
    if ($path -eq "/api/state" -and $method -eq "POST") {
      $body = (New-Object System.IO.StreamReader($ctx.Request.InputStream, $utf8)).ReadToEnd()
      $null = $body | ConvertFrom-Json
      [System.IO.File]::WriteAllText($stateFile, $body, $utf8)
      Respond $ctx 200 "application/json" $utf8.GetBytes('{"ok":true}'); return
    }
    if ($path -eq "/api/launch" -and $method -eq "POST") {
      if (-not $status.running) { Launch }
      Respond $ctx 200 "application/json" $utf8.GetBytes('{"ok":true}'); return
    }
    if ($path -eq "/api/status") { Respond $ctx 200 "application/json" $utf8.GetBytes(($status | ConvertTo-Json -Compress)); return }
    $file = if ($path -eq "/") { "index.html" } else { $path.TrimStart("/") }
    $full = [System.IO.Path]::GetFullPath((Join-Path $web $file))
    if (-not $full.StartsWith($web) -or -not (Test-Path $full -PathType Leaf)) { Respond $ctx 404 "text/plain" $utf8.GetBytes("not found"); return }
    $type = switch ([System.IO.Path]::GetExtension($full)) { ".html" { "text/html; charset=utf-8" } ".js" { "application/javascript; charset=utf-8" } ".css" { "text/css; charset=utf-8" } ".json" { "application/json" } ".jpg" { "image/jpeg" } ".png" { "image/png" } default { "application/octet-stream" } }
    Respond $ctx 200 $type ([System.IO.File]::ReadAllBytes($full))
  } catch {
    Log "http error $path : $($_.Exception.Message)"
    try { Respond $ctx 500 "text/plain" $utf8.GetBytes($_.Exception.Message) } catch {}
  }
}

$url = "http://localhost:$Port/"
$uiDir = Join-Path $root ".ui"
function OpenUi {
  $edge = @("${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe", "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
  if (-not $edge) { Start-Process $url; return $null }
  return Start-Process $edge -ArgumentList "--app=$url", "--user-data-dir=`"$uiDir`"", "--window-size=1280,880", "--no-first-run", "--no-default-browser-check" -PassThru
}
function UiAlive {
  return [bool](Get-CimInstance Win32_Process -Filter "Name='msedge.exe'" | Where-Object { $_.CommandLine -like "*$uiDir*" } | Select-Object -First 1)
}
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($url)
try { $listener.Start() } catch {
  if (-not $NoBrowser) { [void](OpenUi) }
  exit
}
Log "server started on $url"
$ui = $null
if (-not $NoBrowser) { $ui = OpenUi; if ($ui) { [GameKeys]::HideConsole() } }
$uiCheck = [DateTime]::Now
$pending = $listener.GetContextAsync()
while ($listener.IsListening) {
  if ($pending.Wait(40)) {
    Handle $pending.Result
    $pending = $listener.GetContextAsync()
  }
  $line = $null
  while ($queue.TryDequeue([ref]$line)) { OnGameLine $line }
  if ($status.running -and $game -and $game.HasExited) {
    $status.running = $false; $status.advice = ""
    $form.Hide()
    Log "game exited"
  }
  if ($ui -and $ui.HasExited -and -not $status.running -and [DateTime]::Now -gt $uiCheck) {
    $uiCheck = [DateTime]::Now.AddSeconds(2)
    if (-not (UiAlive)) { Log "ui closed"; break }
  }
  [System.Windows.Forms.Application]::DoEvents()
}
$listener.Stop()
