#!/usr/bin/env node
/* SessionStart 훅 — 이 프로젝트에 dev-log가 있으면 /dev-start 안내 한 줄을 컨텍스트로 주입.
   자동 실행 아님. devlog 없으면 침묵(랜덤 디렉토리서 잡음 방지).

   slug 규칙: Claude Code 는 경로의 구분자와 . _ 공백을 전부 '-' 로 바꾼다.
   Windows 는 구분자가 '\' 이고 드라이브 문자 뒤에 ':' 가 붙는다. 규칙이 버전·OS 마다
   달라진 전례가 있어서, 계산값이 빗나가면 실제 디렉토리를 스캔하는 폴백을 둔다.
   dev-start/dev-end 스킬의 §0 폴백과 같은 사고방식이다. */
const fs = require('fs');
const path = require('path');
const os = require('os');

const PROJECTS = path.join(os.homedir(), '.claude', 'projects');

/** 경로 → 디렉토리 이름 후보. 구분자/./_/공백/드라이브 콜론을 '-' 로. */
function slugify(p) {
  return p.replace(/[/\\:._ ]/g, '-');
}

/** 비교용 정규화 — 연속된 '-' 를 하나로 접고 소문자화. 규칙 차이를 흡수한다. */
function normalize(s) {
  return s.replace(/-+/g, '-').replace(/^-|-$/g, '').toLowerCase();
}

function devlogIn(dirName) {
  return path.join(PROJECTS, dirName, 'memory', 'devlog.md');
}

/** cwd 에 대응하는 projects 디렉토리를 찾는다. 못 찾으면 null. */
function resolveDevlog(cwd) {
  // 1) 현재 규칙
  const direct = slugify(cwd);
  if (fs.existsSync(devlogIn(direct))) return devlogIn(direct);

  // 2) 구버전 규칙 (구분자만 치환)
  const legacy = cwd.replace(/[/\\]/g, '-');
  if (fs.existsSync(devlogIn(legacy))) return devlogIn(legacy);

  // 3) 폴백 — devlog 가 있는 디렉토리만 훑어서 정규화 비교
  let entries;
  try {
    entries = fs.readdirSync(PROJECTS);
  } catch {
    return null;
  }
  const want = normalize(direct);
  for (const name of entries) {
    if (normalize(name) === want && fs.existsSync(devlogIn(name))) return devlogIn(name);
  }
  return null;
}

try {
  const devlog = resolveDevlog(process.cwd());
  if (!devlog) process.exit(0); // 기록 없으면 조용히 종료

  const txt = fs.readFileSync(devlog, 'utf8');
  const m = txt.match(/^##\s+(.+)$/m); // 최신(맨 위) 세션 항목 헤더
  const last = m ? m[1].trim() : '이전 세션 기록 있음';

  process.stdout.write(
    `[dev-log 감지] 이 프로젝트에 dev-log 있음. 마지막 세션: ${last}. ` +
    `첫 응답에 "\`/dev-start\`로 지난 작업 캐치업 가능" 한 줄을 사용자에게 안내할 것. ` +
    `사용자가 이미 다른 작업을 지시했으면 그 작업을 우선하고 안내는 짧게 덧붙이기만 할 것.`
  );
} catch {
  process.exit(0); // 훅 실패가 세션 시작을 막지 않게
}
