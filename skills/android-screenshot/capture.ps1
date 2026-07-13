# capture.ps1 - Android screenshot via ADB
#
# Auto-detects the first connected device (or uses -DeviceId), wakes the device,
# detects current foreground app, captures screenshot on device, pulls to local
# temp directory, and prints only the absolute output path on the final line.

[CmdletBinding()]
param(
  [string]$DeviceId,
  [string]$OutDir = "$env:TEMP\gsd-screenshots"
)

$ErrorActionPreference = 'Stop'

$script:AdbExe = $null

function Exit-WithCode {
  param(
    [int]$Code,
    [string]$Message
  )
  Write-Error $Message
  exit $Code
}

function Invoke-Adb {
  param(
    [Parameter(Mandatory = $true)] [string[]]$Args,
    [switch]$IgnoreExit
  )

  $output = & $script:AdbExe @Args 2>&1
  $exitCode = $LASTEXITCODE
  if (-not $IgnoreExit -and $exitCode -ne 0) {
    throw "adb $($Args -join ' ') failed: $output"
  }
  return [pscustomobject]@{ Output = $output; ExitCode = $exitCode }
}

function Get-SdkHint {
  $roots = @()
  if ($env:ANDROID_SDK_ROOT) { $roots += $env:ANDROID_SDK_ROOT }
  if ($env:ANDROID_HOME) { $roots += $env:ANDROID_HOME }
  $roots += "${env:LOCALAPPDATA}\Android\Sdk"

  $roots = $roots | Where-Object { $_ -and -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique
  if ($roots.Count -eq 0) {
    return 'Install Android platform-tools and ensure adb is on PATH. If SDK exists, set ANDROID_SDK_ROOT.'
  }

  return "Checked SDK roots: $($roots -join ', '). Install platform-tools and add <sdk>\\platform-tools to PATH."
}

function Find-AdbExecutable {
  $cmd = Get-Command adb -ErrorAction SilentlyContinue
  if ($cmd -and $cmd.Source) {
    return $cmd.Source
  }

  $candidates = @()
  if ($env:ANDROID_SDK_ROOT) { $candidates += (Join-Path $env:ANDROID_SDK_ROOT 'platform-tools\adb.exe') }
  if ($env:ANDROID_HOME) { $candidates += (Join-Path $env:ANDROID_HOME 'platform-tools\adb.exe') }
  $candidates += (Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe')

  foreach ($path in ($candidates | Select-Object -Unique)) {
    if (Test-Path -LiteralPath $path) {
      return $path
    }
  }

  return $null
}

function Get-DeviceRows {
  $r = Invoke-Adb -Args @('devices')
  $lines = @($r.Output -split "`r?`n")
  $rows = @()
  foreach ($line in $lines) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    if ($line -match '^List of devices attached') { continue }
    if ($line -match '^\s*([^\s]+)\s+([^\s]+)\s*$') {
      $rows += [pscustomobject]@{ Id = $matches[1]; State = $matches[2] }
    }
  }
  return $rows
}

function Get-DeviceList {
  $rows = Get-DeviceRows
  $devices = @()
  foreach ($row in $rows) {
    if ($row.State -eq 'device') {
      $devices += $row.Id
    }
  }
  return $devices
}

function Sanitize-FilePart {
  param([string]$Text)
  if ([string]::IsNullOrWhiteSpace($Text)) { return 'android_app' }
  $sanitized = ($Text -replace '[^A-Za-z0-9._-]+', '_').Trim('_')
  if ([string]::IsNullOrWhiteSpace($sanitized)) { $sanitized = 'android_app' }
  if ($sanitized.Length -gt 80) { $sanitized = $sanitized.Substring(0, 80) }
  return $sanitized
}

try {
  # Ensure adb exists (PATH first, then common SDK locations)
  $script:AdbExe = Find-AdbExecutable
  if (-not $script:AdbExe) {
    Exit-WithCode -Code 2 -Message ("adb not found. " + (Get-SdkHint))
  }

  $deviceRows = Get-DeviceRows
  $devices = @($deviceRows | Where-Object { $_.State -eq 'device' } | ForEach-Object { $_.Id })
  if (-not $devices -or $devices.Count -eq 0) {
    $knownRows = @($deviceRows | ForEach-Object { "$($_.Id):$($_.State)" })
    if ($knownRows.Count -gt 0) {
      Exit-WithCode -Code 3 -Message "No connected Android device in 'device' state. Found: $($knownRows -join ', ')."
    }
    Exit-WithCode -Code 3 -Message 'No connected Android device in device state. Run adb devices and connect/unlock/authorize a device.'
  }

  $target = $null
  if ($DeviceId) {
    if ($devices -contains $DeviceId) {
      $target = $DeviceId
    } else {
      Exit-WithCode -Code 4 -Message "Requested device '$DeviceId' not found in connected device list: $($devices -join ', ')"
    }
  } else {
    $target = $devices[0]
  }

  Write-Host "DEVICE: $target" -ForegroundColor Cyan

  # Wake device and dismiss keyguard if possible.
  Invoke-Adb -Args @('-s', $target, 'shell', 'input', 'keyevent', '224') -IgnoreExit | Out-Null
  Invoke-Adb -Args @('-s', $target, 'shell', 'input', 'keyevent', '82') -IgnoreExit | Out-Null
  Start-Sleep -Milliseconds 300

  # Try to detect current foreground app/activity.
  $focusDump = Invoke-Adb -Args @('-s', $target, 'shell', 'dumpsys', 'window', 'windows') -IgnoreExit
  $focusText = ($focusDump.Output | Out-String)
  $appId = $null

  if ($focusText -match 'mCurrentFocus.*?\s([A-Za-z0-9._$]+/[A-Za-z0-9._$]+)') {
    $appId = $matches[1]
  } elseif ($focusText -match 'mFocusedApp.*?\s([A-Za-z0-9._$]+/[A-Za-z0-9._$]+)') {
    $appId = $matches[1]
  }

  if (-not $appId) {
    Exit-WithCode -Code 5 -Message 'Unable to detect foreground app/activity via dumpsys.'
  }

  Write-Host "APP: $appId" -ForegroundColor Cyan

  $timestamp = (Get-Date).ToString('yyyy-MM-dd_HH-mm-ss')
  $filePart = Sanitize-FilePart -Text $appId
  $fileName = "{0}_{1}.png" -f $filePart, $timestamp

  if (-not (Test-Path -LiteralPath $OutDir)) {
    [void](New-Item -ItemType Directory -Path $OutDir -Force)
  }
  $localPath = Join-Path $OutDir $fileName
  $remotePath = "/sdcard/Download/$fileName"

  # Capture on device then pull to local host.
  $capture = Invoke-Adb -Args @('-s', $target, 'shell', 'screencap', '-p', $remotePath) -IgnoreExit
  if ($capture.ExitCode -ne 0) {
    Exit-WithCode -Code 6 -Message "Device screenshot capture failed: $($capture.Output | Out-String)"
  }

  $pull = Invoke-Adb -Args @('-s', $target, 'pull', $remotePath, $localPath) -IgnoreExit
  if ($pull.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $localPath)) {
    Exit-WithCode -Code 7 -Message "Screenshot pull failed: $($pull.Output | Out-String)"
  }

  # Best-effort cleanup on device.
  Invoke-Adb -Args @('-s', $target, 'shell', 'rm', $remotePath) -IgnoreExit | Out-Null

  Write-Host "SAVED: $localPath" -ForegroundColor Green

  # Final line contract: absolute local path only.
  Write-Output $localPath
}
catch {
  $msg = $_.Exception.Message
  if (-not $msg) { $msg = 'Unknown error.' }
  $msg = (($msg -split "`r?`n") | Select-Object -First 1)
  Exit-WithCode -Code 8 -Message "Android screenshot failed: $msg"
}
