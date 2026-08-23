#!/bin/sh
# notify.py 실행 래퍼.
# settings.json 이 /usr/bin/python3 를 하드코딩하면 Windows(Git Bash)에서 죽는다.
# 여기서 인터프리터를 찾아 넘긴다. macOS/Linux 는 python3, Windows 는 보통 python.
DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
for PY in python3 python py; do
  if command -v "$PY" >/dev/null 2>&1; then
    exec "$PY" "$DIR/notify.py"
  fi
done
exit 0   # 파이썬이 없으면 조용히 종료 — 훅 실패가 세션을 막지 않게
