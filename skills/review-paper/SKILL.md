---
name: review-paper
description: 학술 논문 (학부논문·학회지 draft) 단일 패스 비판 검토. 메인 narrative defensibility · 식별 전략 · 표·인용 정합 · 한계 명시 적정성 · 등급 표현 일관성을 학회지 referee 톤으로 보고. 수정 X. Use when user says "전체 리뷰", "심사 시뮬레이션", "review my paper".
argument-hint: "[paper path] [--strict (skeptical referee 모드)]"
allowed-tools: ["Read", "Grep", "Glob", "Write", "Bash", "Agent"]
---

# Review Paper (학회지급 비판 검토)

학술 논문 draft를 학회지 referee report 수준으로 비판 검토. **수정 X**. 단일 패스 산출.

## Modes

### Default (single-pass)
한 번의 종합 검토 보고서. 빠르고 토큰 효율적. 초고/중간고에 적합.

### `--strict` (skeptical referee)
가장 비판적인 referee 톤. SKEPTIC disposition — "기각 사유를 찾는다" 가정. 사전 제출 stress test용.

## Steps

1. **컨텍스트 로드:**
   - `$ARGUMENTS` 경로 paper 읽기 (.md / .docx / .pdf)
   - 같은 폴더의 `CRITICAL_REVIEW_LOG.md` / `RESEARCH_LOG.md` / `RESULTS_SUMMARY.md` 참조 (이전 검토 이력 + 메인 narrative 기준)
   - 참조된 표 docx, 부록, references.bib 확인

2. **research-critical-reviewer agent 실행** (있으면) 또는 general-purpose Agent로 다음 차원 검토:

   ### A. 메인 narrative defensibility
   - "한 문장 contribution"이 명확한지
   - 결과 강도 vs 표현 등급 (G1 사다리) 일치
   - 회신/심사 시 첫 단락에서 핵심 결과 즉시 파악 가능?

   ### B. 식별 전략 검증
   - FE 구조·clustering·DID 디자인이 식별 가설과 일치
   - Robustness check (Oster, wild boot, alternative spec) 적정 커버리지
   - Bad-control / mediator / endogeneity 인지 + hedge
   - Pre-trend·placebo·falsification 존재

   ### C. 수치-narrative-표 정합
   - 본문 인용 수치가 표·부록·raw output과 일치
   - 같은 결과를 여러 위치에서 동일 표현 등급으로
   - Spec 명시 (어느 column·어느 회귀에서 산출)

   ### D. 인용 정확성
   - 인용된 선행연구의 abstract와 본문 주장 정합
   - 인용 형식 일관 (`@author` vs `[@author]`)
   - Bib entry 존재 + 메타데이터 완전

   ### E. 한계 명시 적정성
   - Limitations 섹션이 결과 약점을 정직 노출
   - 결론에서 한계 톤과 정합 (단정형 vs hedge)
   - Over-claim 회피

   ### F. 산문 톤 (학회지 표준)
   - 격식 학술체 일관
   - 영문 용어 병기 통일
   - 문단 흐름 (topic sentence → evidence → implication)

3. **보고서 저장:**
   - `quality_reports/review_paper_<YYYY-MM-DD>.md`

4. **사용자에게 종합 요약:**
   - 차원별 등급 (A/B/C/D)
   - Critical issue top 5
   - 수정 우선순위 (제출/회신 전 vs 후)
   - Defensibility 평가 (referee 첫 통독에서 노출될 risk)

5. **중요: 파일 수정 X.** 보고서만.

## Tips

프로젝트별 컨텍스트(문서 종류·제출 일정·메인 narrative·지도 회신 반영 이력)는 **해당 프로젝트의
`CLAUDE.md` / 검토 로그**에서 읽는다. 이 스킬에 하드코딩하지 않는다 — 전역 스킬이라 다른
프로젝트에서도 로드되고, 프로젝트가 바뀌면 그대로 stale 해진다.

검토 시작 전 프로젝트에서 확인:
- 문서 종류와 기대 기여 수준 (학부논문 / 학회지 / 연구계획서) → referee 톤 강도 조정
- 메인 narrative 최신 버전이 어느 파일에 있는지
- 직전 회신·심사 권고가 본문에 반영됐는지

## 추천 사용 시점

- 본문 substantial 수정 후 (예: 새 spec 추가, narrative reframe)
- 제출 전 final pass
- 교수님 회신 받은 후 권고 반영 검증
- 영문 abstract 정제 전 본문 컨센서스 확인
