# Setup runbook (agent)

Written 2026-11-12 by the hub session on the source PC (Windows 11, user `infomax`, home `C:\Users\infomax`, Claude Code 2.1.322).

Reader: a Claude Code session asked either to **publish** this PC's Claude Code setup (part A, source PC) or to **apply** it on another PC (part B, target PC).

The bundle is the `windows/` folder of `github.com/jaefit/claude-config` (public repository). This file carries order, gates and gotchas. Values live in the bundle files themselves. Inventory, versions and the reason behind each item live in `setup.md` beside this file (Korean, written for the human); read the section a step names.

## Ground rules

- A step is done when its **Check** passes. Paste the check output into your final report.
- The repository is public. `windows/export.sh` is the list of what goes into it. `~/.claude` itself stays without a git remote: it also tracks desk work files and per-folder memory, and those stay on the PC.
- Work content stays out of the bundle: desk topic files, memory, transcripts (`*.jsonl`), `.credentials.json`, key values, tokens, account ids, counterparty and fund names, internal reports.
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
- `LAYOUT`: `same` when the user keeps projects under `Desktop` and `Desktop\task` and will bring the desk files and memory from the source PC themselves, else `different`.

On macOS/Linux use the repository root instead of `BUNDLE` (its `SETUP.md` and `install.sh` are the mac path) and take from `BUNDLE` only the skills the root lacks. The bundle's `dev-start-hint.js` and `statusline-command.sh` carry both-platform code, untested on mac since the Windows edits.

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

- The bundle's `CLAUDE.md` loads only the dewrite rules. With `LAYOUT=same`, once the user has placed `desk/` in `~/.claude/`, append `@~/.claude/desk/user.md` and `@~/.claude/desk/rules.md` to it.
- With `LAYOUT=different` the skills and the session hook still mention `desk/map.md` and `desk/handoff.md` (hub mode, handoff lines). Those branches stay idle without the files.
- Pinned skills (`socratic-tutor`, `writing-for-agents`) carry local sections: install them from the bundle, never from upstream. `to-questionnaire` is held back from the bundle; the user copies it from the source PC.
- `permissions.defaultMode` ships as `bypassPermissions` by the user's choice.
- `/model` writes a `model` key into `settings.json`. The bundle ships without it, so the target starts on the account default.

**Check B3:** `settings.json` parses; every `@` path in `~/.claude/CLAUDE.md` exists; both hook commands in `settings.json` point at existing files.

### B4. Memory slugs (only when the user brought `projects/*/memory/`)

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

## Outside this runbook

These stay on the source PC and move only by the user's hand:

- `~/.claude/desk/` topic files, `projects/*/memory/`, `skills/to-questionnaire/`.
- Windows scheduled tasks and cloud routines (listed in the source PC's `desk/schedule.md`).
- Excel 2016, Infomax, LSEG Workspace rules (source PC `desk/toolchain.md`, `infomax.md`, `lseg-data.md`).

Account-side, they appear after login: claude.ai connectors and `skills/synced/`.

Local MCP servers: the source PC has none. The `caveman-shrink` command in the repository README registers a proxy with nothing to wrap and fails on every platform.
