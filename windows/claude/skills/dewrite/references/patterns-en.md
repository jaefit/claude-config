# English AI-tell catalog (EN-1 … EN-25)

Source: blader/humanizer v3.0.0 (MIT), itself from Wikipedia "Signs of AI writing". Condensed and re-keyed. See LICENSES.md.

Severity: **S1** act on one sighting · **S2** act when 2+ sightings or other tells nearby · **S3** flag only, fix if genre forbids.
Genre column: which profiles (see genres.md) change the default. `paper↓` = one step weaker in paper, `chat↑` = one step stronger in chat.

## A. Staging instead of stating (strongest)

| id | name | signal | fix | genre |
|---|---|---|---|---|
| EN-1 | Not X but Y | "not just/only/merely X, but Y", "it's not X, it's Y", "X rather than Y", split form "This does not mean X. It means Y.", clipped tail ", no guessing" | State Y directly. Keep contrast only if reader actually believes X. | S1 all |
| EN-2 | One-line closer / fragment row | one-sentence paragraph restating the prior one; "That is the real win."; "Read that again."; row of fragments "No X. No Y."; every. single. word. | Cut the repeat. Merge fragments into one sentence with a new fact. | S1 all |
| EN-3 | Sayings that sound deep | "the real question is", "at its core", "what really matters", "fundamentally", "X is the Y of Z", "the language/currency/architecture of" | Replace with the specific claim. | S1; paper↓ |
| EN-4 | Staged run-up | "Let's dive in", "here's what you need to know", "Honestly?", "Look,", "Here's the thing", "Let's be honest" | Delete the run-up, keep the point. | S1 all |
| EN-5 | Arguing with no one | "This isn't about", "I'm not saying", "To be clear", "Don't get me wrong", "Some might say… but", "A tempting approach would be" | Delete the defense unless the objection is attributed or a reader would weigh it. | S1; paper↓ (real counter-arguments are normal) |

## B. Rhythm by rule (weaker alone)

| id | name | signal | fix | genre |
|---|---|---|---|---|
| EN-6 | Forced triad | three items, three examples, or three facts + lesson where fewer would do | Merge or develop the strongest one. Keep real threes. | S2 all |
| EN-7 | Repeated openings | 3+ consecutive sentences start with the same subject/pronoun | Merge, change subject, or lead with the action. | S2; note↓ |
| EN-8 | Dashes everywhere | em/en dash or ` -- ` as universal connector, more than 1–2 per document | Period, comma, colon, parentheses. Leave dashes in code/paths. | S2; paper↓ S3; chat↑ S1 |
| EN-9 | Stacked qualifiers | "could potentially possibly", "to be fair, it's also possible", "might arguably" | Keep one hedge if doubt is real. Ordinary "perhaps" is fine. | S2; paper↓ (scope statements stay) |
| EN-10 | Hyphenated pairs after noun | "the report is high-quality", "the team is cross-functional" | Drop hyphen after the noun; keep before. | S3 all |
| EN-11 | Passive with hidden actor | "results are preserved", "no configuration needed" when the actor matters | Active voice when it names who acts. | S3; paper↓ off (passive is conventional) |

## C. Inflation and borrowed authority

| id | name | signal | fix | genre |
|---|---|---|---|---|
| EN-12 | Overused AI words | additionally, align with, bolster, crucial, deep dive, delve, emphasize, enduring, enhance, foster, garner, highlight (v), interplay, intricate, key (adj), landscape (abstract), meticulous, pivotal, quietly, robust (figurative), showcase, tapestry, testament, underscore (v), valuable, vibrant | Plain word. Technical "robust"/"gate" stay. | S2 (S1 if 3+ in one paragraph) |
| EN-13 | Inflated significance | "stands as a testament", "pivotal moment", "plays a key role", "lasting legacy", "setting the stage", "evolving landscape"; stock "Challenges and outlook" section; send-off "the future looks bright" | Keep the fact, drop the dressing. End on the last concrete fact. | S1 all |
| EN-14 | Vague connection | "associated with", "linked to", "tied to", "in connection with" without saying how | Name the relation the source gives; else keep vague, never invent. | S2 all |
| EN-15 | Shallow -ing rider | "…, highlighting/underscoring/reflecting/symbolizing/ensuring …" bolted to a fact | Cut the rider unless the source supports it. | S2 all |
| EN-16 | Sales language | boasts, vibrant, rich (fig.), profound, nestled, in the heart of, renowned, breathtaking, diverse array, stunning, commitment to | Say what the thing is. | S1; memo/report/paper |
| EN-17 | Borrowed authority | "experts argue", "observers note", "industry reports", prestige outlet lists, "over N followers" | Name the real source or cut. Never invent one. | S2 all |
| EN-18 | Avoiding is/are/has | serves as, stands as, functions as, represents a, boasts, features, offers, refers to | Use is / are / has. | S2 all |

## D. Formatting by rule

| id | name | signal | fix | genre |
|---|---|---|---|---|
| EN-19 | Bold as decoration | bold on random words; every list item "**Label:** text" | Remove bold; turn labeled list into prose when labels carry nothing. | S2; report↓ (bold on the one number that matters is fine) |
| EN-20 | Decorative headings | Title Case Every Word, emoji/arrow decorations, horizontal rule between every section, H1 that repeats the title | Sentence case, no ornaments. | S2; chat↑ S1 |
| EN-21 | Curly quotes | “ ” where the target uses " " | Match target format. | S3 all |

## E. Leftovers from chat and draft

| id | name | signal | fix | genre |
|---|---|---|---|---|
| EN-22 | Chatbot residue | "I hope this helps", "Great question!", "Certainly!", "Would you like…", "let me know" | Delete wrapper, keep content. | S1 all |
| EN-23 | Knowledge-limit disclaimer / guess | "as of my training", "not widely documented", "likely grew up", "it is believed that" filling a gap | State what the source lacks or delete. Never present a guess as fact. | S1 all |
| EN-24 | Heading repeated in first line | heading, then one line restating it | Delete the restatement. | S2 all |
| EN-25 | Writing about the previous version | docs/comments describing what was replaced | Describe current behavior; history only in changelogs. | S2; note↓ off |

## When not to act

Inside quotations, titles, proper names, or a passage discussing the phrase itself. Text dated before 2022-11-30. A single *weak alone* tell with no company. Keep: a specific odd detail, mixed feelings, dated slang, a first-person choice, a genuine aside.
