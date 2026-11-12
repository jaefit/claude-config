<#
Claude Code Notification hook — Windows 포팅본.

원본(macOS, hooks/notify.py)의 afplay + osascript 조합을 대체:
  - 사운드  : afplay Morse.aiff        -> [console]::beep (외부 의존 없음)
  - 배너    : osascript display notification -> Windows 토스트(BurntToast) 또는 풍선 알림

동작 원칙은 원본과 동일:
  - stdin 으로 hook JSON 을 받는다
  - message 가 JSON 이고 type 이 SUPPRESSED_TYPES 면 조용히 종료 (팀원 status 스팸 차단)
  - 제목은 "ClaudeCode > <프로젝트 라벨>", 라벨은 Desktop 기준 상대경로, 밖이면 ~ 기준
  - 어떤 실패도 세션을 막지 않는다 (전부 try/catch, 항상 exit 0)
#>

$ErrorActionPreference = 'SilentlyContinue'

$SuppressedTypes = @('idle_notification', 'task_completed', 'task_started', 'task_updated')

# ---- stdin ----
$raw = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($raw)) { $raw = '{}' }
try { $data = $raw | ConvertFrom-Json } catch { $data = [pscustomobject]@{} }

# 디버그 로그 (원본의 /tmp/notify_dbg.log 대응)
try {
  $dbg = Join-Path $env:TEMP 'notify_dbg.log'
  Add-Content -Path $dbg -Value ($raw.TrimEnd() + "`n---") -Encoding utf8
} catch {}

# ---- 억제 대상 판정 ----
$msg = ''
if ($data.PSObject.Properties['message']) { $msg = [string]$data.message }
$msg = $msg.Trim()

if ($msg.StartsWith('{')) {
  try {
    $inner = $msg | ConvertFrom-Json
    if ($inner.type -and ($SuppressedTypes -contains $inner.type)) { exit 0 }
  } catch {}
}

# ---- 프로젝트 라벨 ----
function Get-ProjectLabel([string]$cwd) {
  if ([string]::IsNullOrWhiteSpace($cwd)) { return 'claude' }
  $cwd = $cwd -replace '[\\/]+$', ''
  $home_ = $env:USERPROFILE
  $desk  = Join-Path $home_ 'Desktop'
  $n = { param($p) ($p -replace '/', '\').TrimEnd('\') }
  $c = & $n $cwd; $h = & $n $home_; $d = & $n $desk
  if ($c -ieq $d) { return 'Desktop' }
  if ($c.StartsWith($d + '\', [StringComparison]::OrdinalIgnoreCase)) { return $c.Substring($d.Length + 1) }
  if ($c -ieq $h) { return '~' }
  if ($c.StartsWith($h + '\', [StringComparison]::OrdinalIgnoreCase)) { return '~\' + $c.Substring($h.Length + 1) }
  return $c
}

$cwd = ''
if ($data.PSObject.Properties['cwd']) { $cwd = [string]$data.cwd }
# cc/ccs/ccl 로 연 pane 은 $env:CC_TAB 에 이름이 있다 (PowerShell $PROFILE 의 cc 블록)
$label = if ($env:CC_TAB) { $env:CC_TAB } else { Get-ProjectLabel $cwd }
$title = "ClaudeCode > " + $label
if ([string]::IsNullOrWhiteSpace($msg)) { $msg = 'Claude Code' }

# ---- 사운드 ----
try { [console]::beep(880, 120) } catch {}

# ---- 배너 ----
$shown = $false
try {
  if (Get-Module -ListAvailable -Name BurntToast) {
    Import-Module BurntToast -ErrorAction Stop
    New-BurntToastNotification -Text $title, $msg -ErrorAction Stop
    $shown = $true
  }
} catch { $shown = $false }

if (-not $shown) {
  # BurntToast 없을 때 폴백: WinForms 풍선 알림 (추가 설치 불필요).
  # NotifyIcon 은 Dispose 하는 순간 풍선도 같이 사라지므로 잠깐 붙잡아야 한다.
  # 훅은 blocking 이라 이 대기가 그대로 세션 지연이 된다 — 1.2초로 제한한다.
  # (BurntToast 가 있으면 이 경로 자체를 타지 않고 즉시 반환한다.)
  try {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    $ni = New-Object System.Windows.Forms.NotifyIcon
    $ni.Icon = [System.Drawing.SystemIcons]::Information
    $ni.BalloonTipTitle = $title
    $ni.BalloonTipText  = $msg
    $ni.Visible = $true
    $ni.ShowBalloonTip(5000)
    Start-Sleep -Milliseconds 1200
    $ni.Dispose()
  } catch {}
}

exit 0
