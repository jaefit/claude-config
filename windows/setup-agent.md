# Setup runbook (agent)

Written 2026-11-12 by the hub session on the source PC (Windows 11, user `infomax`, home `C:\Users\infomax`, Claude Code 2.1.322).

Reader: a Claude Code session asked to **publish** this PC's Claude Code setup (part A, source PC), to **apply** it on another Windows PC (part B, target PC), to **update a Mac** to it (part M), or to refresh the **private mirror** of `~/.claude` (part C, source PC).

Two repositories. The bundle is the `windows/` folder of `github.com/jaefit/claude-config` (public): settings only. The mirror is `github.com/jaefit/claude-home` (private, 2026-11-13): a snapshot of everything `~/.claude/.gitignore` lets through, which is desk files, per-folder memory, every skill, hooks and settings. This file carries order, gates and gotchas. Values live in the bundle files themselves. Inventory, versions and the reason behind each item live in `setup.md` beside this file (Korean, written for the human); read the section a step names.

## Ground rules

- A step is done when its **Check** passes. Paste the check output into your final report.
- `claude-config` is public. `windows/export.sh` is the list of what goes into it. Work content stays out of it: desk topic files, memory, key values, tokens, account ids, counterparty and fund names, internal reports. Those go to the private mirror only.
- `~/.claude` itself stays without a git remote. The mirror receives a file snapshot (part C), never the local history.
- Neither repository receives transcripts (`*.jsonl`) or `.credentials.json`.
- Before any push, confirm the destination's visibility with `gh repo view <owner/name> --json visibility`. The mirror must print `PRIVATE`.
- On the target, back up each file you replace as `<name>.bak-<yyyymmdd>` beside it. Fragments backups go outside the `Fragments` folder.
- Ask the user only for: the three branch facts in B0, logins, git author name and email, and the go-ahead before a push. Decide the rest and note it as your judgment.
- Reply to the user in Korean.
- Scripts containing backslashes: write them to a file and run by path. Git Bash heredocs and `-c` strings alter backslashes.

## A. Publish (source PC)

A1. Clone `https://github.com/jaefit/claude-config.git` into a folder outside `~/.claude`, then run `sh windows/export.sh` in Git Bash from the clone root. It rebuilds `windows/claude/`, `windows/pwsh/`, `windows/wt/`, copies `setup.md` and this file from `~/.claude/desk/`, drops the `remote` and `model` keys from `settings.json`, and stops with exit 1 when its scan finds a key-like string or an e-mail address.

A2. Read `git status` and the whole `git diff`. A file that newly carries work content (see Ground rules) comes out: add its path to the exclusions in `export.sh` and rerun.

A3. Commit with the author identity the repository log already shows (`git log -1 --format='%an <%ae>'`), in the log's message style, without attribution lines. Push to `main` on the user's word.

**Check A:** `export.sh` exits 0; `jq -e . windows/claude/settings.json` succeeds and `jq 'has("remote") or has("model")'` prints `false`; `git status --short` lists paths under `windows/` only.

## B. Apply (target PC)

`BUNDLE` below is `windows/` inside a clone of the repository (`git clone https://github.com/jaefit/claude-config.git ~/claude-config`).

### B0. Branch facts

Establish and state three facts before touching anything:

- `OS`: Windows, or macOS/Linux.
- `HOME` and user name, compared with line 3 of this file.
- `LAYOUT`: `same` when the user keeps projects under `Desktop` and `Desktop\task` and the logged-in GitHub account can clone the private mirror, else `different`.

On macOS/Linux stop here and follow part M.

### B1. Tools

Install every row of `setup.md` §1 (winget IDs are in the table), the two PowerShell modules with `Install-PSResource BurntToast, CompletionPredictor -Scope CurrentUser`, and the font.

- Font: install nerd-fonts `D2Coding.zip` by hand as a user font. The installed family name is `D2KodingLigature Nerd Font` (K spelling). `oh-my-posh font install` failed with exit 70 on the source PC.
- Python runs through `uv` only; the bare `python` on PATH is the Store stub.

**Check B1:** `Get-Command claude, git, gh, node, jq, uv, wt, zoxide, oh-my-posh` resolves all nine in pwsh 7; `sh` and `cygpath` resolve inside Git Bash; the font family appears in the installed font list.

### B2. Auth

The user performs `claude` login and `gh auth login`. Then you run `gh auth setup-git` and set the git author the user gives.

**Check B2:** `git config --global --get-regexp credential` shows the `gh auth git-credential` helper for `https://github.com`. Without it Git Credential Manager opens an invisible login window and `git push` hangs.

### B3. `~/.claude`

Copy `BUNDLE/claude/*` into `~/.claude/`, then `agents/`, `skills/proofread/` and `skills/review-paper/` from the repository root (identical on both platforms). Where the target already has `settings.json`, merge key by key and keep target keys the bundle lacks.

- With `LAYOUT=same`, skip the bundle copy above: clone `https://github.com/jaefit/claude-home.git` to a folder outside `~/.claude` and copy its contents except `.git` into `~/.claude/`. It carries the full `CLAUDE.md`, `settings.json` (with the `remote` key), `desk/`, `projects/*/memory/` and every skill. `settings.local.json` and `hooks/notify.ps1` still come from `BUNDLE/claude/` when the mirror lacks them.
- The bundle's `CLAUDE.md` loads only the dewrite rules; the mirror's also loads `desk/user.md` and `desk/rules.md`.
- With `LAYOUT=different` the skills and the session hook still mention `desk/map.md` and `desk/handoff.md` (hub mode, handoff lines). Those branches stay idle without the files.
- Pinned skills (`socratic-tutor`, `writing-for-agents`) carry local sections: install them from the bundle or the mirror, never from upstream. `to-questionnaire` is in the mirror only.
- `permissions.defaultMode` ships as `bypassPermissions` by the user's choice.
- `/model` writes a `model` key into `settings.json`. The bundle ships without it, so the target starts on the account default.

**Check B3:** `settings.json` parses; every `@` path in `~/.claude/CLAUDE.md` exists; both hook commands in `settings.json` point at existing files.

### B4. Memory slugs (only with `projects/*/memory/` from the mirror)

Claude Code names a project's memory directory from its working directory: every character outside `[A-Za-z0-9]` becomes one `-`, each Hangul character included (`C:\Users\infomax\Desktop\업무` → `C--Users-infomax-Desktop---`). Compute with node, since Git Bash `tr` and `sed` work bytewise and turn one Hangul character into three dashes:

`node -e "process.stdout.write(process.argv[1].replace(/[^A-Za-z0-9]/g,'-'))" "<working directory in the OS's native form>"`

Rename each `projects/<source slug>/` to the slug of the matching target folder.

**Check B4:** for every project folder on the target, `~/.claude/projects/<computed slug>/memory/MEMORY.md` exists.

### B5. Hooks and status line

Hooks load only in a new session, so test them now by feeding stdin. Write each sample JSON to a file and redirect it in (`< sample.json`): Windows paths in an inline `echo` lose their backslashes, the JSON turns invalid, and the scripts fall back silently (verified on the source PC).

- Status line: build the sample from the eight `jq` paths the script reads (`grep -o "jq -r '[^']*'" statusline-command.sh`), with `rate_limits.five_hour.resets_at` as epoch seconds; run `sh ~/.claude/statusline-command.sh < sample.json`.
- Session hook: `{"source":"startup","cwd":"<a project dir>"}` into `node ~/.claude/hooks/dev-start-hint.js`.
- Notification (Windows): `{"message":"test","cwd":"<dir>"}` into `pwsh -NoProfile -NonInteractive -File <notify.ps1>`.

**Check B5:** status line prints two lines, the first `<root> › <subfolder>` and the second containing `(↻HH:MM)`; the session hook exits 0 and prints `sessionTitle` as `<user>-<parent folder>-<folder>` of the sample `cwd` (a title built from your shell's own directory means the JSON failed to parse); the user confirms a toast titled `ClaudeCode > …`. The hook has run only with `desk/handoff.md` present; report what it prints without it.

### B6. Plugins

`settings.json` now carries `enabledPlugins` (11) and `extraKnownMarketplaces` (4). Whether that alone installs them is untested. Compare `claude plugin list` against `enabledPlugins`; add missing marketplaces with `claude plugin marketplace add` and missing plugins with `claude plugin install`, reading each subcommand's `--help` for the exact form on the installed version.

Expected gaps to report rather than fix: `cc-plugin-you-should-know@builtin` never appears in the installed list, and the source of marketplace `anthropic-plugin-directory` (`context7`, `skill-creator`) is unconfirmed.

**Check B6:** every other `enabledPlugins` key appears in `claude plugin list`.

### B7. PowerShell profile (Windows)

Place `BUNDLE/pwsh/Microsoft.PowerShell_profile.ps1` at `$PROFILE`; where the target has a profile, append the bundle's blocks to it.

- Edit `$CcLayouts` to the target's folders. Each entry must equal a Fragments profile name minus the `cc ` prefix (B8). The usage comment near line 27 lists retired preset names; `$CcLayouts` is the truth.
- Keep `CompletionPredictor` inside its `PowerShell.OnIdle` block. A direct `Import-Module` there makes every non-interactive `pwsh` hang after finishing.
- The `claude` wrapper calls `$env:USERPROFILE\.local\bin\claude.exe`; confirm that path on the target.
- A shell opened before the edit keeps the old `$CcLayouts`: use a new tab or `. $PROFILE`.

**Check B7:** `pwsh -NoLogo -Command "Get-Command claude, cc, ccs, ccl | ForEach-Object CommandType"` prints four `Function` lines and returns within 5 seconds (0.8 s on the source PC). Two `Set-PSReadLineOption` errors about redirected output precede them in a non-interactive run; they are expected.

### B8. Windows Terminal (Windows)

- Copy `BUNDLE/wt/cc-projects.json` to `%LOCALAPPDATA%\Microsoft\Windows Terminal\Fragments\claude-cc\cc-projects.json`. Rewrite every `startingDirectory` (source paths start `C:\Users\infomax\Desktop`) and drop profiles for folders the target lacks.
- Set `profiles.defaults.font.face` in WT `settings.json` to the font from B1. A per-profile font reaches only that profile.
- Touch WT `settings.json` to trigger a reload. WT then writes one `"source": "claude-cc"` stub per fragment profile into `profiles.list`; that write is expected.
- A new per-folder profile follows the colour rule in `setup.md` §4.

**Check B8:** stub count in `profiles.list` equals the profile count in the fragment file; every `$CcLayouts` entry has a `cc <entry>` profile; the user runs `ccl <one preset>` and confirms folder, tab colour and title.

### B9. Report

One table: step, check, result. Then list what remains with the user: connector logins on claude.ai, anything in "Outside this runbook" they want, and each unverified item you hit.

## M. Update a Mac to this setup (run on the Mac)

The Mac already runs the repository root (`install.sh`, `SETUP.md`). On a Mac without it, run the root `SETUP.md` first. This part brings over what changed on the Windows PC since: three new skills, newer `dev-start` and `dev-end`, the session hook, the status line, the dewrite rules and the settings keys. The bundle's hook, status line and both skills carry both-platform code, written on Windows and untested on a Mac until you run the checks below.

M0. Find the clone: `readlink ~/.claude/settings.json` points into it when `install.sh` ran in link mode (`MODE=link`); otherwise ask the user where it is (`MODE=copy`). In link mode the Mac's own setting changes sit in the clone as uncommitted edits: read `git status` and `git diff`, commit them, then `git pull`. `BUNDLE` is `<clone>/windows`.

M1. Place these from `BUNDLE/claude/` into `~/.claude/` at the same relative path, backing up what you replace (Ground rules): `skills/dev-start`, `skills/dev-end`, `skills/dewrite`, `skills/socratic-tutor`, `skills/writing-for-agents`, `hooks/dev-start-hint.js`, `statusline-command.sh`. Link mode: `ln -sfn "$BUNDLE/claude/<path>" ~/.claude/<path>`. Copy mode: `cp -R`.

- Keep the Mac's `hooks/notify.sh`, `hooks/notify.py`, `skills/proofread`, `skills/review-paper` and `agents/`. `notify.ps1`, part B7 and part B8 are Windows only.
- The skills name `~/.claude/desk/` files and a hub mode keyed to the Windows path `C:\Users\infomax\Desktop`. Without a `desk/` folder those branches stay idle, and the hook skips its folder hints (it checks for `desk/map.md`).

M2. `~/.claude/CLAUDE.md`: add the line `@~/.claude/skills/dewrite/always-on.md` when absent. Leave the user's other lines.

M3. Settings. Merge `BUNDLE/claude/settings.json` into the Mac's `settings.json` (in link mode, the file in the clone root): the bundle wins for every key except `hooks`, the Mac keeps keys the bundle lacks (`model` among them), and `enabledPlugins` and `extraKnownMarketplaces` are unions.

```sh
jq -s '.[0] as $m | .[1] as $w | $m + ($w | del(.hooks)) + {enabledPlugins: ($m.enabledPlugins + $w.enabledPlugins), extraKnownMarketplaces: ($m.extraKnownMarketplaces + $w.extraKnownMarketplaces)}' settings.json "$BUNDLE/claude/settings.json" > settings.merged.json
```

Read the diff against the old file, then replace it. Plugins follow part B6.

M4. Test as in B5 with Mac paths in the samples (`"cwd":"/Users/<name>/<project>"`), skipping the Windows notification line. Where a check fails, restore that one file from its backup and report the failure text.

**Check M:** `jq -e . ~/.claude/settings.json` succeeds and `.hooks.Notification` still names `notify.sh`; the status line prints two lines with `(↻HH:MM)` on the second; the session hook exits 0 and prints `sessionTitle` built from the sample `cwd`; `node ~/.claude/skills/dewrite/scripts/gate.js ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md` prints `change rate: 0.0%`; every `@` path in `~/.claude/CLAUDE.md` exists; a new session lists `dewrite`, `socratic-tutor` and `writing-for-agents`.

M5. Report as in B9. In link mode the root `settings.json` now differs in the clone: commit it, and push on the user's word.

Desk files and per-folder memory describe the Windows PC's folders. They come to the Mac only on the user's word, from the private mirror (B3, `LAYOUT=same` line).

## C. Private mirror (source PC)

Run in Git Bash. `MIRROR` is a clone of `https://github.com/jaefit/claude-home.git` in a folder outside `~/.claude`.

```sh
gh repo view jaefit/claude-home --json visibility -q .visibility   # must print PRIVATE
cd "$MIRROR" && git config core.autocrlf false && git pull -q
git rm -rq --ignore-unmatch .
git -C ~/.claude ls-files -co --exclude-standard -z | tar -C ~/.claude --null -T - -cf - | tar -xf -
git add -A && git status --short | wc -l
```

The file list is whatever `~/.claude/.gitignore` lets through, tracked or not; the copied `.gitignore` applies the same rules inside the mirror. Commit with the author identity the mirror's log shows, without attribution lines, and push to `main` on the user's word.

`tar` prints `Cannot stat` for index entries already deleted on disk (`git -C ~/.claude ls-files -d`) and exits non-zero; those files are meant to be absent.

**Check C:** `git ls-files | grep -ciE 'credential|\.jsonl$'` prints `0`; `git ls-files | wc -l` equals `git -C ~/.claude ls-files -co --exclude-standard | wc -l` minus `git -C ~/.claude ls-files -d | wc -l` (558 = 566 − 8 on 2026-11-13); visibility printed `PRIVATE`.

## Outside this runbook

These stay on the source PC and move only by the user's hand:

- Windows scheduled tasks and cloud routines (listed in the source PC's `desk/schedule.md`).
- Excel 2016, Infomax, LSEG Workspace rules (source PC `desk/toolchain.md`, `infomax.md`, `lseg-data.md`).

Account-side, they appear after login: claude.ai connectors and `skills/synced/`.

Local MCP servers: the source PC has none. The `caveman-shrink` command in the repository README registers a proxy with nothing to wrap and fails on every platform.
