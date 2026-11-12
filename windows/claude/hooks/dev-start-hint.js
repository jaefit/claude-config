#!/usr/bin/env node
/* SessionStart 훅 — 세 가지 일을 한다.
   1) 새 세션(source=startup)이면 세션 이름을 <사용자>-<부모 폴더>-<폴더> 로 정한다.
      PowerShell 프로필의 claude 래퍼와 같은 규칙. 래퍼는 pwsh 에서 직접 칠 때만 먹고
      프로필 로드 전에 열린 탭·Desktop 앱·VS Code 에선 안 붙어서 훅으로 옮겼다.
      resume/clear/compact 는 건드리지 않는다(/rename 으로 바꾼 이름 보존).
   2) 이 프로젝트에 dev-log가 있으면 컨텍스트 한 줄을 주입. 자동 실행 아님.
      devlog 없으면 안내 생략(랜덤 디렉토리서 잡음 방지). dev-start/dev-end 스킬과 같은 slug 규칙.
      - startup/resume/clear: /dev-start 안내 + next_todos 의 지난·오늘 기한(`due YYYY-MM-DD`) 항목.
      - compact (대화 압축 직후): /dev-start 안내 대신 체크포인트 지시 — 압축 전 작업이 devlog 맨 위
        항목에 없으면 압축 요약을 근거로 `/dev-end checkpoint` 형식의 짧은 항목을 쓰게 한다.
        (2026-10-13: 이틀짜리 세션이 압축되며 첫날 기록이 요약본으로만 남았던 일 때문에 추가)
   3) 기한 항목 파싱 실패는 조용히 넘어간다.
   4) (2026-11-02, ~/.claude/desk/structure-design.md 3.8) 폴더 사이 안내:
      - ~/.claude/desk/handoff.md 에서 이 폴더 앞으로 온 `[ ]` 줄 수, devlog 맨 위 날짜 뒤에 바뀐
        desk 주제 파일(최대 3개)을 안내 끝에 한 줄로 붙인다.
      - devlog 가 없는 Desktop 하위 폴더면 "공용 사실은 desk, 부모 메모리 복사 금지" 한 줄.
      - Desktop\task 와 홈 폴더에서는 다른 안내 대신 "여기서 세션을 열지 않는다" 한 줄. Temp 에서는 아무것도 안 한다.

   [Windows 포팅] 원본은 cwd.replace(/\//g, '-') 로 슬래시만 치환했다. 윈도우에서는
   구분자가 백슬래시고 드라이브 문자 뒤에 콜론이 붙어서, 그대로 두면 메모리 디렉토리를
   못 찾고 조용히 종료한다. Claude Code 는 영문·숫자 말고 전부 '-' 로 바꾼다(한글은 글자마다 '-').
   실측: C:\Users\infomax\Desktop -> C--Users-infomax-Desktop  (':' 와 '\' 가 각각 '-')
         C:\Users\infomax\Desktop\업무 -> C--Users-infomax-Desktop---  (2.1.321, 2026-11-10) */
const fs = require('fs');
const path = require('path');
const os = require('os');

function today() {
  const d = new Date();
  const p = (n) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
}

function dueItems(todoPath) {
  // 열린 항목 중 due 가 오늘 이전·오늘인 것
  if (!fs.existsSync(todoPath)) return [];
  const t = today();
  const out = [];
  for (const line of fs.readFileSync(todoPath, 'utf8').split(/\r?\n/)) {
    const m = line.match(/^\s*-\s*\[ \]\s*.*?due\s+(\d{4}-\d{2}-\d{2})\s*[·:-]?\s*(.*)$/);
    if (m && m[1] <= t) out.push(`${m[1]} ${m[2].replace(/\s+—.*$/, '').slice(0, 60)}`);
  }
  return out;
}

const DESK = path.join(os.homedir(), '.claude', 'desk');
// 매 세션 행동을 바꾸는 desk 주제 파일. 설계 문서와 handoff 는 너무 자주 바뀌어 세지 않는다.
const TOPICS = ['user', 'toolchain', 'toolchain-ref', 'infomax', 'infomax-ref', 'workbook-style', 'business-data', 'lseg-data'];

function folderName(cwd) {
  // 지도 「폴더」 열 표기: Desktop 루트는 'Desktop', 바로 아래는 폴더 이름, task 아래는 'task/<이름>'
  const desktop = path.join(os.homedir(), 'Desktop');
  const rel = path.relative(desktop.toLowerCase(), cwd.toLowerCase()) === '' ? '' : path.relative(desktop, cwd);
  if (rel === '') return 'Desktop';
  if (rel.startsWith('..') || path.isAbsolute(rel)) return null;
  const parts = rel.split(/[\\/]/);
  if (parts[0].toLowerCase() === 'task') return parts.length >= 2 ? `task/${parts[1]}` : 'task';
  return parts[0];
}

function handoffCount(name) {
  const f = path.join(DESK, 'handoff.md');
  if (!name || !fs.existsSync(f)) return 0;
  // minutes 는 Vault 세션이 맡는다 (데스크 규칙 1, 2026-11-05)
  const want = name.toLowerCase() === 'vault' ? ['vault', 'minutes'] : [name.toLowerCase()];
  let n = 0;
  for (const line of fs.readFileSync(f, 'utf8').split(/\r?\n/)) {
    const m = line.match(/^\s*-\s*\[ \]\s.*?→\s*([^·]+?)\s*·/);
    if (m && want.includes(m[1].trim().toLowerCase())) n++;
  }
  return n;
}

function changedTopics(sinceDate) {
  if (!sinceDate) return [];
  const since = new Date(`${sinceDate}T23:59:59`).getTime();
  const out = [];
  for (const t of TOPICS) {
    const f = path.join(DESK, `${t}.md`);
    try { if (fs.statSync(f).mtimeMs > since) out.push(t); } catch {}
  }
  return out.slice(0, 3);
}

function crossFolderLine(name, devlogTop) {
  const n = handoffCount(name);
  const ch = changedTopics(devlogTop);
  const parts = [];
  if (n) parts.push(`다른 폴더에서 온 일 ${n}개(~/.claude/desk/handoff.md)`);
  if (ch.length) parts.push(`바뀐 공용 파일: ${ch.join(', ')}`);
  return parts.length ? ` ${parts.join(', ')}. 이 줄도 안내에 짧게 덧붙일 것.` : '';
}

try {
  let input = {};
  try { input = JSON.parse(fs.readFileSync(0, 'utf8') || '{}'); } catch {}

  const cwd = input.cwd || process.cwd();
  const source = input.source || 'startup';
  const out = { hookEventName: 'SessionStart' };

  if (source === 'startup') {
    const user = process.env.USERNAME || process.env.USER || os.userInfo().username;
    const leaf = path.basename(cwd);
    const parent = path.basename(path.dirname(cwd));
    out.sessionTitle = `${user}-${parent}-${leaf}`;
  }

  const slug = cwd.replace(/[^A-Za-z0-9]/g, '-'); // Claude Code 와 같은 규칙. dev-start/dev-end §0 도 같다
  const memDir = path.join(os.homedir(), '.claude', 'projects', slug, 'memory');
  const devlog = path.join(memDir, 'devlog.md');
  const name = folderName(cwd);
  const isTemp = /[\\/]AppData[\\/]Local[\\/]Temp([\\/]|$)/i.test(cwd);
  const isHome = path.resolve(cwd).toLowerCase() === path.resolve(os.homedir()).toLowerCase();
  // claude -p(헤드리스)는 CLAUDE_CODE_ENTRYPOINT=sdk-cli. 아침 작업 결과물에 안내 문구가 섞이지 않게 안내를 넣지 않는다 (11-02 실측)
  const headless = process.env.CLAUDE_CODE_ENTRYPOINT === 'sdk-cli';
  if (isTemp || headless) {
    // claude -p 시험이나 루틴 작업 폴더. 안내하지 않는다.
  } else if (name === 'task' || isHome) {
    out.additionalContext =
      `[폴더 안내] 이 폴더(${isHome ? '홈' : 'Desktop\\task'})에서는 세션을 열지 않는다. 하위 폴더나 Desktop에서 연다 ` +
      `(~/.claude/desk/structure-design.md 2.1). 첫 응답에 이 한 줄을 사용자에게 알릴 것.`;
  } else if (fs.existsSync(devlog)) {
    const txt = fs.readFileSync(devlog, 'utf8');
    const m = txt.match(/^##\s+(.+)$/m); // 최신(맨 위) 세션 항목 헤더
    const last = m ? m[1].trim() : '이전 세션 기록 있음';
    const topDate = (last.match(/\d{4}-\d{2}-\d{2}/) || [null])[0];
    let cross = '';
    try { cross = crossFolderLine(name, topDate); } catch {}
    let due = [];
    try { due = dueItems(path.join(memDir, 'next_todos.md')); } catch {}
    const dueTxt = due.length ? ` 지난·오늘 기한 할 일 ${due.length}개: ${due.slice(0, 4).join(' / ')}.` : '';

    if (source === 'compact') {
      out.additionalContext =
        `[dev-log 체크포인트] 대화가 방금 압축됐다. devlog 맨 위 항목: ${last} (오늘 ${today()}). ` +
        `압축 전에 한 작업이 이 항목에 없으면, 이어서 하던 일을 계속하기 전에 압축 요약을 근거로 ` +
        `\`/dev-end checkpoint\` 형식(한 일·다음 각 3줄 이내, 제목에 checkpoint, 날짜별)의 짧은 항목을 ${devlog} 맨 위에 쓸 것. ` +
        `사용자에게 /dev-start 안내는 하지 않는다. 쓴 뒤 한 줄로만 알린다.` + dueTxt;
    } else {
      out.additionalContext =
        `[dev-log 감지] 이 프로젝트에 dev-log 있음. 마지막 세션: ${last}. ` +
        `첫 응답에 "\`/dev-start\`로 지난 작업 캐치업 가능" 한 줄을 사용자에게 안내할 것. ` +
        `사용자가 이미 다른 작업을 지시했으면 그 작업을 우선하고 안내는 짧게 덧붙이기만 할 것.` +
        (dueTxt ? `${dueTxt} 이 기한 항목도 안내 줄에 짧게 덧붙일 것.` : '') + cross;
    }
  } else if (name) {
    let cross = '';
    try { cross = crossFolderLine(name, null); } catch {}
    out.additionalContext =
      `[처음 세션] 이 폴더에는 dev-log가 없다. 공용 사실은 ~/.claude/desk(목록 paths.md)에 있다. ` +
      `부모 폴더 메모리를 통째로 복사하지 않는다.` + cross;
  }

  if (out.sessionTitle || out.additionalContext) {
    process.stdout.write(JSON.stringify({ hookSpecificOutput: out }));
  }
} catch {
  process.exit(0); // 훅 실패가 세션 시작을 막지 않게
}
