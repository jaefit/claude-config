#!/usr/bin/env node
/* SessionStart 훅 — 이 프로젝트에 dev-log가 있으면 /dev-start 안내 한 줄을 컨텍스트로 주입.
   자동 실행 아님. devlog 없으면 침묵(랜덤 디렉토리서 잡음 방지).
   dev-start/dev-end 스킬과 같은 slug 규칙(pwd의 / → -) 사용. */
const fs = require('fs');
const path = require('path');
const os = require('os');

try {
  const cwd = process.cwd();
  const slug = cwd.replace(/\//g, '-'); // dev-start/dev-end 스킬과 동일 규칙
  const devlog = path.join(os.homedir(), '.claude', 'projects', slug, 'memory', 'devlog.md');
  if (!fs.existsSync(devlog)) process.exit(0); // 기록 없으면 조용히 종료

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
