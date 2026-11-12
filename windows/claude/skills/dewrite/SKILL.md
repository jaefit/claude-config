---
name: dewrite
description: Use when asked to remove AI tells, humanize, 윤문, "AI 티 빼줘", de-slop, or check whether Korean or English prose (memo, report, paper, note, chat) reads as machine-written. Also use before delivering any prose the user will send under their own name.
---

# dewrite

Detect and remove AI-writing patterns in Korean and English text without changing what it says. Bilingual: per-paragraph language detection, one output format, one change table.

**Core rule: the output is the same document with fewer tells, not a different document.** Structure, facts, register and mood stay. Only flagged spans move.

## Invocation

```
/dewrite <file | pasted text> [--detect] [--ko | --en] [--genre memo|report|paper|chat|note] [--out <path>]
```

- default: rewrite + change table
- `--detect`: change table only, nothing rewritten
- `--ko` / `--en`: force language for the whole text (default: per paragraph)
- `--genre`: force profile (default: estimate, see step 2)
- `--out`: write result to a new file. Never overwrite the input file unless the user says so.

## Procedure

Load `references/preserve.md` first. Then the catalog(s) for the language(s) found, then `references/genres.md`.

### 1. Language, per paragraph
Count Hangul syllables vs Latin letters in each paragraph. Hangul ≥ 30% → `ko`, else `en`. Tables, code blocks, headings inherit the surrounding paragraph. A flag overrides everything. English tokens inside a `ko` paragraph are checked against the preserve list before being treated as KO-B2.

### 2. Genre, one per document
Estimate from shape: 2+ tables or 3+ headings → `report`; greeting or sign-off → `memo`; citations, abstract, "본 연구" → `paper`; under 400 chars and no headings → `chat`; wiki links, fragments, `#tags` → `note`. Write the estimate and its reason as the first line of the change table header. `--genre` overrides.

### 3. Detect
Scan the whole text once against the catalog for its language. Record every hit as a span: `id · severity (after genre adjustment) · original text · location`. Document-level patterns (rhythm, comma rate, repeated closers) count too. Do not fix anything yet.

### 4. Rewrite (skipped with `--detect`)
Fix S1 and S2 spans. Leave S3 in the table only. For each span, apply the catalog's prescription to that span and nothing around it. Constraints, all hard:

- **Preserve list** (`references/preserve.md`) is byte-identical in the output.
- **Structure is fixed.** Same number of headings, tables, table rows, code fences, block quotes, list items. You may change words inside them, not their existence. A callout (`> **label**: text`) stays a callout.
- **Heading text stays.** Fix decoration only (case, emoji, trailing colon). Never rephrase a heading into a pattern the catalog flags (for example "~하는 이유", "X: Y").
- **Register and mood stay.** Formal stays formal. "~에 불과하다" does not become "~밖에 안 되고". Hedged stays hedged, asserted stays asserted, obligation stays obligation.
- **Removal only.** No new hedges, dashes, triads, closers, "~해야 한다", "~하는 이유다", or any phrase from a prescription example that the original did not need.
- **Bold**: in `report`/`note`, remove bold on prose sentences but keep bold on numbers and on table cells. In other genres follow the catalog.

### 5. Gate
Run `node ~/.claude/skills/dewrite/scripts/gate.js <original> <rewritten>` when both are files (write the rewrite to a temp file if needed). It prints the numbers below and exits 1 on a hard breach. Compute by hand only if node is unavailable.

| check | limit | on breach |
|---|---|---|
| char change rate (Levenshtein ÷ original length) | warn > 30%, **stop** > 50% | > 50%: return detect output only, say the rewrite was withheld |
| heading count, table count, table row count, code fence count | must equal original | revert the offending edits |
| every number, date, article number, proper noun in original | present in output | revert |
| any new phrase matching a catalog signature that the original lacked | none | revert |

### 6. Output

Always this shape, in the language of the input:

```
장르: report (표 6개, 헤딩 9개)  ·  언어: ko 41문단 / en 0문단  ·  변경률: 7.9%
--- 윤문본 ---
<full rewritten text, or omitted with --detect>
--- 변경표 ---
| # | id | S | 원문 | 수정 | 위치 |
|---|----|---|------|------|------|
| 1 | KO-J3 | S2 | 얼마나 조달할 수 있나 — 총량 | 얼마나 조달할 수 있나 (총량) | §1 표 |
...
--- 미수정 (S3 / 장르 허용) ---
| id | S | 원문 | 위치 | 이유 |
```

With `--out`, write the 윤문본 to that path and print only the header and the two tables. Mention anything you noticed but did not touch (a factual inconsistency, a term you were unsure about) in one line after the tables. Do not fix it.

## Quick reference

| want | do |
|---|---|
| only see the tells | `--detect` |
| Korean note full of English domain terms | default; preserve list handles terms |
| paper draft, keep passive and 접속사 | `--genre paper` |
| Slack message | `--genre chat` |
| "it changed too much" | rerun with `--detect`, apply only S1 by hand |

## Common mistakes

- Rewriting the whole paragraph because one phrase was flagged. Fix the span.
- Turning tables, callouts, or formula code blocks into prose. Those are the document's format in `report`, not a tell.
- Replacing a heading with one that contains "~하는 이유" or "X: Y". That injects a pattern.
- Splitting "A가 아니라 B" into "B이다. A가 아니다." That trades KO-C8 for a fragment closer (EN-2). Drop the negative half, or keep the sentence if the reader might believe A.
- Dropping "(검산 완료)" or a status marker because it repeats. Repeated status markers are information.
- Softening "판단된다" to "보인다" or the reverse. That is a mood change, not a style fix.
- Treating IRS, carry, roll-down, bp as KO-B2 jargon. They are on the preserve list.
- Skipping the gate because the text "looks fine". Compute the numbers.
