#!/usr/bin/env python3
"""Claude Code Notification hook — UTF-8 안전한 네이티브 알림 (macOS / Windows / Linux).

macOS  : afplay(사운드) + osascript(배너). Focus/DND 무시.
Windows: winsound(사운드) + PowerShell NotifyIcon 풍선(배너).
Linux  : paplay/canberra(사운드) + notify-send(배너). 전부 best-effort.

플랫폼 감지 실패나 명령 부재는 조용히 넘어간다 — 훅이 세션을 막으면 안 된다.
"""
import json, os, subprocess, sys, tempfile

IS_MAC = sys.platform == 'darwin'
IS_WIN = sys.platform.startswith('win') or os.name == 'nt'

# Claude 알림 사운드 볼륨 (0.0 ~ 1.0). macOS 전용 — Windows/Linux는 시스템 볼륨을 따른다.
VOLUME = 0.18
SOUND_FILE = '/System/Library/Sounds/Morse.aiff'

# 팀원 status 알림은 spam — silent skip.
# message가 JSON이고 type이 여기 들어 있으면 사운드/배너 둘 다 안 띄움.
SUPPRESSED_TYPES = {'idle_notification', 'task_completed', 'task_started', 'task_updated'}

_raw = sys.stdin.read() or '{}'
try:
    data = json.loads(_raw)
except Exception:
    data = {}

# 디버그: hook 한 번 firing 될 때마다 stdin 원본을 임시 디렉토리에 append.
# /tmp 하드코딩은 Windows에서 없다 — tempfile로 해석한다.
try:
    with open(os.path.join(tempfile.gettempdir(), 'notify_dbg.log'), 'a', encoding='utf-8') as _f:
        _f.write(_raw.rstrip() + '\n---\n')
except Exception:
    pass

_msg_raw = (data.get('message') or '').strip()
try:
    _inner = json.loads(_msg_raw) if _msg_raw else None
    if isinstance(_inner, dict) and _inner.get('type') in SUPPRESSED_TYPES:
        sys.exit(0)
except Exception:
    pass


def project_label(cwd: str) -> str:
    """Desktop 기준 상대경로, 밖이면 ~ 기준. 구분자는 플랫폼 것을 쓴다."""
    if not cwd:
        return 'claude'
    sep = '\\' if IS_WIN else '/'
    cwd = cwd.rstrip('/\\')
    home = os.path.expanduser('~')
    desktop = os.path.join(home, 'Desktop')
    if cwd == desktop:
        return 'Desktop'
    if cwd.startswith(desktop + sep):
        return cwd[len(desktop) + 1:]
    if cwd == home:
        return '~'
    if cwd.startswith(home + sep):
        return '~' + sep + cwd[len(home) + 1:]
    return cwd or 'claude'


proj = project_label(data.get('cwd') or '')
msg = (data.get('message') or '').strip()
title = f"ClaudeCode › {proj}"


def esc_applescript(s: str) -> str:
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'


def esc_powershell(s: str) -> str:
    """PowerShell single-quoted 문자열: ' 를 '' 로 이스케이프."""
    return "'" + s.replace("'", "''") + "'"


def run(cmd, **kw):
    try:
        return subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, **kw)
    except Exception:
        return None


def popen(cmd):
    try:
        return subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        return None


if IS_MAC:
    # 사운드 (afplay로 별도 재생, 볼륨 조절 가능)
    popen(['afplay', '-v', str(VOLUME), SOUND_FILE])
    # 배너 (사운드 없이)
    run(['osascript', '-e', f'display notification {esc_applescript(msg)} with title {esc_applescript(title)}'])

elif IS_WIN:
    # 사운드 — winsound는 Windows 표준 라이브러리.
    try:
        import winsound
        winsound.MessageBeep(winsound.MB_ICONASTERISK)
    except Exception:
        pass
    # 배너 — NotifyIcon 풍선. BurntToast 같은 추가 모듈 없이 기본 PowerShell로 동작한다.
    ps = (
        "Add-Type -AssemblyName System.Windows.Forms;"
        "$n=New-Object System.Windows.Forms.NotifyIcon;"
        "$n.Icon=[System.Drawing.SystemIcons]::Information;"
        "$n.Visible=$true;"
        f"$n.ShowBalloonTip(6000,{esc_powershell(title)},{esc_powershell(msg or ' ')},"
        "[System.Windows.Forms.ToolTipIcon]::Info);"
        "Start-Sleep -Milliseconds 6500;$n.Dispose()"
    )
    popen(['powershell', '-NoProfile', '-NonInteractive', '-Command', ps])

else:
    # Linux — 있는 것만 쓴다.
    for snd in (['canberra-gtk-play', '-i', 'message'], ['paplay', '/usr/share/sounds/freedesktop/stereo/message.oga']):
        if popen(snd) is not None:
            break
    run(['notify-send', title, msg])
