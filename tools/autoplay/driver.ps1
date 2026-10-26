param([int]$seconds = 600)
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System; using System.Runtime.InteropServices;
public static class K { [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l); }
"@
$keys = @( @(1, 0x57, 0x11), @(2, 0x53, 0x1F), @(4, 0x41, 0x1E), @(8, 0x44, 0x20), @(16, 0x51, 0x10), @(32, 0x26, 0x148), @(64, 0x25, 0x14B), @(128, 0x27, 0x14D) )
$bmp = New-Object Drawing.Bitmap(1, 1); $g = [Drawing.Graphics]::FromImage($bmp)
$held = 0; $end = (Get-Date).AddSeconds($seconds); $last = -1
while ((Get-Date) -lt $end) {
  $p = Get-Process AzerothSurvivors -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $p) { Start-Sleep -Milliseconds 500; continue }
  $h = $p.MainWindowHandle
  $g.CopyFromScreen(4, 4, 0, 0, (New-Object Drawing.Size(1, 1)))
  $c = $bmp.GetPixel(0, 0)
  $want = 0
  if ($c.G -gt 200) { $want = [Math]::Floor($c.R / 16) + 16 * [Math]::Floor($c.B / 16) }
  if ($want -ne $last) { Write-Output ("{0} mask {1} rgb {2},{3},{4}" -f (Get-Date).ToString("HH:mm:ss.f"), $want, $c.R, $c.G, $c.B); $last = $want }
  foreach ($k in $keys) {
    $bit = $k[0]; $vk = $k[1]; $sc = $k[2]
    $on = ($want -band $bit) -ne 0; $was = ($held -band $bit) -ne 0
    if ($on -and -not $was) { [K]::PostMessage($h, 0x100, [IntPtr]$vk, [IntPtr](1 -bor ($sc -shl 16))) | Out-Null }
    if ($was -and -not $on) { [K]::PostMessage($h, 0x101, [IntPtr]$vk, [IntPtr](1 -bor ($sc -shl 16) -bor 0xC0000000)) | Out-Null }
  }
  $held = $want
  Start-Sleep -Milliseconds 80
}
