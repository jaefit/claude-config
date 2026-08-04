#!/usr/bin/env python3
"""Claude Code Notification hook — UTF-8 안전한 macOS native 알림.

사운드는 afplay로 별도 재생 (Claude 알림만 볼륨 조절 가능).
Focus/DND 모드 무시함 — 시스템 mute(F10)로 전체 사운드 끌 수 있음.
"""
import json, os, subprocess, sys

# Claude 알림 사운드 볼륨 (0.0 ~ 1.0)
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

# 디버그: hook 한 번 firing 될 때마다 stdin 원본을 /tmp/notify_dbg.log에 append.
try:
    with open('/tmp/notify_dbg.log', 'a') as _f:
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
    """Desktop 기준 상대경로, 밖이면 ~ 기준."""
    if not cwd:
        return 'claude'
    cwd = cwd.rstrip('/')
    home = os.path.expanduser('~')
    desktop = os.path.join(home, 'Desktop')
    if cwd == desktop:
        return 'Desktop'
    if cwd.startswith(desktop + '/'):
        return cwd[len(desktop) + 1:]
    if cwd == home:
        return '~'
    if cwd.startswith(home + '/'):
        return '~/' + cwd[len(home) + 1:]
    return cwd or 'claude'


proj = project_label(data.get('cwd') or '')
msg = (data.get('message') or '').strip()
title = f"ClaudeCode › {proj}"


def esc(s: str) -> str:
    """AppleScript 문자열 escape."""
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'


# 사운드 (afplay로 별도 재생, 볼륨 조절 가능)
subprocess.Popen(['afplay', '-v', str(VOLUME), SOUND_FILE],
                 stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

# 배너 (사운드 없이)
script = f'display notification {esc(msg)} with title {esc(title)}'
subprocess.run(['osascript', '-e', script])
