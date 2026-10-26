param([int]$vk = 13)
Add-Type @"
using System; using System.Runtime.InteropServices;
public static class K { [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l); }
"@
$p = Get-Process AzerothSurvivors -ErrorAction SilentlyContinue | Select-Object -First 1
if ($p) { [K]::PostMessage($p.MainWindowHandle, 0x100, [IntPtr]$vk, [IntPtr]0) | Out-Null; Start-Sleep -Milliseconds 80; [K]::PostMessage($p.MainWindowHandle, 0x101, [IntPtr]$vk, [IntPtr]0) | Out-Null; "sent $vk" }
