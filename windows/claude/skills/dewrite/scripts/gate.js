#!/usr/bin/env node
// dewrite gate: node gate.js <original.md> <rewritten.md>
// Prints change rate and structural counts. Exit 1 if a hard limit is breached.
const fs = require("fs");
const [orig, next] = process.argv.slice(2).map(p => fs.readFileSync(p, "utf8"));

function lev(a, b) {
  const m = a.length, n = b.length;
  let p = new Uint32Array(n + 1), c = new Uint32Array(n + 1);
  for (let j = 0; j <= n; j++) p[j] = j;
  for (let i = 1; i <= m; i++) {
    c[0] = i;
    for (let j = 1; j <= n; j++)
      c[j] = Math.min(p[j] + 1, c[j - 1] + 1, p[j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1));
    [p, c] = [c, p];
  }
  return p[n];
}
const count = (s, re) => (s.match(re) || []).length;
const counts = s => ({
  headings: count(s, /^#{1,6} /mg),
  tables: count(s, /^\|[-: |]+\|\s*$/mg),
  tableRows: count(s, /^\|/mg),
  codeFences: count(s, /^```/mg) / 2,
  blockquotes: count(s, /^> /mg),
  bold: count(s, /\*\*/g) / 2,
  dashes: count(s, /[—–]| -- /g),
});
const numbers = s => new Set((s.match(/\d[\d,.]*%?p?|제\d+-\d+조/g) || []));

const d = lev(orig, next);
const rate = 100 * d / orig.length;
const a = counts(orig), b = counts(next);
const missing = [...numbers(orig)].filter(x => !numbers(next).has(x));

console.log(`change rate: ${rate.toFixed(1)}%  (levenshtein ${d} / ${orig.length} chars)`);
let bad = false;
for (const k of ["headings", "tables", "tableRows", "codeFences", "blockquotes"]) {
  const ok = a[k] === b[k];
  if (!ok) bad = true;
  console.log(`${ok ? "ok  " : "FAIL"} ${k}: ${a[k]} -> ${b[k]}`);
}
console.log(`info bold: ${a.bold} -> ${b.bold}   dashes: ${a.dashes} -> ${b.dashes}`);
if (missing.length) { bad = true; console.log(`FAIL numbers missing in output: ${missing.join(", ")}`); }
else console.log("ok   all numbers/article refs present");
if (rate > 50) { bad = true; console.log("FAIL change rate > 50%: withhold rewrite, return detect only"); }
else if (rate > 30) console.log("WARN change rate > 30%: review for over-editing");
process.exit(bad ? 1 : 0);
