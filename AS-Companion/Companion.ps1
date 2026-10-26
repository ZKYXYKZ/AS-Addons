param(
  [string]$GamePath = "$env:USERPROFILE\Downloads\AzerothSurvivors\AzerothSurvivors\AzerothSurvivors.exe",
  [string]$BuildFile = "$PSScriptRoot\build.txt",
  [switch]$Auto
)
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class GameKeys {
  [DllImport("user32.dll")] static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
  [DllImport("user32.dll")] static extern uint MapVirtualKey(uint c, uint t);
  public static void Press(IntPtr h, uint vk) {
    uint sc = MapVirtualKey(vk, 0);
    PostMessage(h, 0x100, (IntPtr)vk, (IntPtr)(1 | (sc << 16)));
    System.Threading.Thread.Sleep(60);
    PostMessage(h, 0x101, (IntPtr)vk, (IntPtr)(1 | (sc << 16) | (3u << 30)));
  }
}
"@
$ErrorActionPreference = "Stop"
$log = "$PSScriptRoot\companion.log"
function Log($m) { Add-Content -Path $log -Value ("{0:HH:mm:ss} {1}" -f (Get-Date), $m) -Encoding UTF8 }

$data = Get-Content -Raw -Encoding UTF8 (Join-Path $PSScriptRoot "..\SurvivorsBuilds\Data.lua")
$spells = @{}
foreach ($m in [regex]::Matches($data, '\{ key = "(\w+)", icon = "(\w+)", spell = \d+, name = \{ en = "([^"]*)", fr = "([^"]*)" \}')) {
  $spells[$m.Groups[2].Value] = @{ key = $m.Groups[1].Value; en = $m.Groups[3].Value; fr = $m.Groups[4].Value }
}
$jewels = @{}
foreach ($m in [regex]::Matches($data, '\{ key = "(\w+)", icon = "(\w+)", name = \{ en = "([^"]*)", fr = "([^"]*)" \}')) {
  if (-not $spells.ContainsKey($m.Groups[2].Value)) { $jewels[$m.Groups[2].Value] = $m.Groups[1].Value }
}
$spellByName = @{}
foreach ($s in $spells.Values) { $spellByName[$s.en] = $s.key; $spellByName[$s.fr] = $s.key }

if (-not (Test-Path $BuildFile)) { [System.Windows.Forms.MessageBox]::Show("Collez le texte d'export du build (SurvivorsBuilds > Exporter) dans :`n$BuildFile"); exit }
$f = (Get-Content -Raw $BuildFile).Trim().Split(";")
if ($f[0] -ne "SB1" -or $f.Count -lt 10) { [System.Windows.Forms.MessageBox]::Show("build.txt ne contient pas un build SurvivorsBuilds valide."); exit }
$weights = @{}
foreach ($p in $f[4].Split(",")) { if ($p) { $kv = $p.Split(":"); $weights[$kv[0]] = [double]$kv[1] } }
$bans = @{}; foreach ($k in $f[5].Split(",")) { if ($k) { $bans[$k] = $true } }
$wish = @{}
foreach ($i in 6..8) { $list = $f[$i].Split(","); for ($j = 0; $j -lt $list.Count; $j++) { if ($list[$j]) { $wish[$list[$j]] = $list.Count - $j } } }
$r = $f[9].Split(","); $influence = [double]$r[0] / 100; $reserve = [int]$r[1]; $reroll = [int]$r[2]

function CardKey($c) {
  if ($c.kind -in @("new", "upgrade") -and $spells.ContainsKey($c.icon)) { return $spells[$c.icon].key }
  if ($jewels.ContainsKey($c.icon)) { return $jewels[$c.icon] }
  foreach ($n in $spellByName.Keys) { if ($c.title -and $c.title.Contains($n)) { return "leg:" + $spellByName[$n] } }
  return $null
}
function Advise($j) {
  $best = $null; $bestScore = 0; $ban = $null; $i = 0
  foreach ($c in $j.choices) {
    $i++
    $k = CardKey $c
    $base = if ($k -and $weights.ContainsKey($k)) { $weights[$k] } elseif ($k -and $wish.ContainsKey($k)) { $wish[$k] } else { 0 }
    if ($k -and $bans.ContainsKey($k)) { $base = 0; if (-not $ban) { $ban = $i } }
    $score = $base * (1 + $influence * [double]$c.rarity)
    if ($score -gt $bestScore) { $bestScore = $score; $best = $i }
  }
  if ($best) { $c = $j.choices[$best - 1]; return @{ text = "Prendre $best : $($c.title) ($($c.rarityName))"; key = "$best" } }
  if ($ban -and [int]$j.banishes -gt 0) { return @{ text = "Bannir la carte $ban : $($j.choices[$ban - 1].title)"; key = $null } }
  if ($reroll -eq 1 -and [int]$j.rerolls -gt $reserve) { return @{ text = "Rien du build : relancer (R), $($j.rerolls) restantes"; key = "r" } }
  if ($j.skip -eq $true) { return @{ text = "Rien du build : skip (+$($j.skipGold) or)"; key = $null } }
  $pick = $null; $pr = -1; $i = 0
  foreach ($c in $j.choices) {
    $i++
    $k = CardKey $c
    if ($k -and $bans.ContainsKey($k)) { continue }
    if ([int]$c.rarity -gt $pr) { $pr = [int]$c.rarity; $pick = $i }
  }
  if (-not $pick) { $pick = 1 }
  return @{ text = "Rien du build, pas de skip : prendre $pick : $($j.choices[$pick - 1].title)"; key = "$pick" }
}

$form = New-Object System.Windows.Forms.Form
$form.FormBorderStyle = "None"; $form.TopMost = $true; $form.ShowInTaskbar = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 24); $form.Opacity = 0.9
$form.Width = 760; $form.Height = 46; $form.StartPosition = "Manual"
$scr = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$form.Left = $scr.X + ($scr.Width - $form.Width) / 2; $form.Top = $scr.Y + 110
$label = New-Object System.Windows.Forms.Label
$label.Dock = "Fill"; $label.TextAlign = "MiddleCenter"; $label.ForeColor = [System.Drawing.Color]::FromArgb(240, 190, 80)
$label.Font = New-Object System.Drawing.Font("Segoe UI", 15, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($label)
$form.Show(); $form.Hide()

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $GamePath; $psi.WorkingDirectory = Split-Path $GamePath
$psi.UseShellExecute = $false; $psi.RedirectStandardOutput = $true
$psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
$game = [System.Diagnostics.Process]::Start($psi)
$queue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
Register-ObjectEvent -InputObject $game -EventName OutputDataReceived -Action { if ($EventArgs.Data) { $Event.MessageData.Enqueue($EventArgs.Data) } } -MessageData $queue | Out-Null
$game.BeginOutputReadLine()
Log "game started, build $($f[2]), auto=$Auto"

while (-not $game.HasExited) {
  $line = $null
  while ($queue.TryDequeue([ref]$line)) {
    if (-not $line.StartsWith("rogue: {")) { continue }
    try { $j = $line.Substring(7) | ConvertFrom-Json } catch { continue }
    if ($j.type -eq "choices") {
      $a = Advise $j
      $label.Text = $a.text
      $form.Show()
      Log "$($j.why) lvl $($j.level): $($a.text)"
      if ($Auto -and $a.key) {
        Start-Sleep -Milliseconds 600
        $game.Refresh()
        $vk = if ($a.key -eq "r") { 0x52 } else { 0x30 + [int]$a.key }
        [GameKeys]::Press($game.MainWindowHandle, [uint32]$vk)
        Log "sent key $($a.key)"
      }
    } elseif ($j.type -in @("resume", "start", "defeat", "victory")) {
      $form.Hide()
    }
  }
  [System.Windows.Forms.Application]::DoEvents()
  Start-Sleep -Milliseconds 50
}
$form.Close()
