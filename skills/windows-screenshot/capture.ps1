# capture.ps1 - DPI-correct full-content window screenshot.
#
# Finds a top-level window whose title contains the given match string,
# restores it if minimized, brings it forward, captures it via PrintWindow
# with PW_RENDERFULLCONTENT (flag 2), and writes a PNG to
# $env:TEMP\gsd-screenshots\<sanitized-title>_<timestamp>.png.
#
# Emits ONLY the absolute output path on the final stdout line so the
# calling agent can capture it deterministically. Diagnostics go to stderr.

param(
  [Parameter(Mandatory = $true)]
  [string]$Match,
  [string]$OutDir = "$env:TEMP\gsd-screenshots",
  [int]$WaitMs = 250
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

# P/Invoke surface: window enum, geometry, restore, PrintWindow, DPI.
$signature = @'
using System;
using System.Runtime.InteropServices;
using System.Text;

public static class Win32 {
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern int GetWindowTextLength(IntPtr hWnd);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool IsIconic(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

    [DllImport("user32.dll")]
    public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdcBlt, uint nFlags);

    [DllImport("user32.dll")]
    public static extern IntPtr SetProcessDpiAwarenessContext(IntPtr value);

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
}
'@

if (-not ('Win32' -as [type])) {
    Add-Type -TypeDefinition $signature -Language CSharp
}

# Must run before GetWindowRect so we get physical pixels on HiDPI displays.
[void][Win32]::SetProcessDpiAwarenessContext([IntPtr]::new(-4))

# Enumerate top-level windows and collect matches.
$candidates = New-Object System.Collections.Generic.List[object]
$enumProc = [Win32+EnumWindowsProc]{
    param([IntPtr]$hWnd, [IntPtr]$lParam)
    if (-not [Win32]::IsWindowVisible($hWnd)) { return $true }
    $len = [Win32]::GetWindowTextLength($hWnd)
    if ($len -eq 0) { return $true }
    $sb = New-Object System.Text.StringBuilder ($len + 1)
    [void][Win32]::GetWindowText($hWnd, $sb, $sb.Capacity)
    $title = $sb.ToString()
    if ($title -and $title.ToLowerInvariant().Contains($Match.ToLowerInvariant())) {
        $candidates.Add([pscustomobject]@{ Handle = $hWnd; Title = $title })
    }
    return $true
}
[void][Win32]::EnumWindows($enumProc, [IntPtr]::Zero)

if ($candidates.Count -eq 0) {
    Write-Error "No visible window title contains '$Match'."
    exit 2
}
if ($candidates.Count -gt 1) {
    Write-Host "WARN: $($candidates.Count) windows matched; using the first:" -ForegroundColor Yellow
    $candidates | ForEach-Object { Write-Host "  - $($_.Title)" }
}

$target = $candidates[0]
$hwnd = $target.Handle
$rawTitle = $target.Title
Write-Host "MATCH: $rawTitle" -ForegroundColor Cyan

# Restore if minimized; bring forward; give the WM a moment to repaint.
if ([Win32]::IsIconic($hwnd)) {
    [void][Win32]::ShowWindow($hwnd, 9)   # SW_RESTORE
    Start-Sleep -Milliseconds $WaitMs
}
[void][Win32]::SetForegroundWindow($hwnd)
Start-Sleep -Milliseconds $WaitMs

# Get physical-pixel bounds.
$rect = New-Object Win32+RECT
if (-not [Win32]::GetWindowRect($hwnd, [ref]$rect)) {
    Write-Error "GetWindowRect failed for '$rawTitle'."
    exit 3
}
$width  = $rect.Right  - $rect.Left
$height = $rect.Bottom - $rect.Top
if ($width -le 0 -or $height -le 0) {
    Write-Error "Window has non-positive size: ${width}x${height}."
    exit 4
}
Write-Host "BOUNDS: ${width}x${height}" -ForegroundColor Cyan

# PrintWindow with flag 2 = PW_RENDERFULLCONTENT.
$bmp = New-Object System.Drawing.Bitmap $width, $height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$gfx = [System.Drawing.Graphics]::FromImage($bmp)
$hdc = $gfx.GetHdc()
try {
    $ok = [Win32]::PrintWindow($hwnd, $hdc, 2)
    if (-not $ok) {
        Write-Error "PrintWindow returned false for '$rawTitle'."
        exit 5
    }
} finally {
    $gfx.ReleaseHdc($hdc)
    $gfx.Dispose()
}

# Build deterministic filename: sanitized-title + sortable timestamp.
$sanitized = ($rawTitle -replace '[^A-Za-z0-9._-]+', '_').Trim('_')
if ([string]::IsNullOrWhiteSpace($sanitized)) { $sanitized = 'window' }
if ($sanitized.Length -gt 80) { $sanitized = $sanitized.Substring(0, 80) }
$timestamp = (Get-Date).ToString('yyyy-MM-dd_HH-mm-ss')

if (-not (Test-Path -LiteralPath $OutDir)) {
    [void](New-Item -ItemType Directory -Path $OutDir -Force)
}
$outPath = Join-Path $OutDir ("{0}_{1}.png" -f $sanitized, $timestamp)
$bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

Write-Host "SAVED: $outPath" -ForegroundColor Green

# Final line is just the path.
Write-Output $outPath
