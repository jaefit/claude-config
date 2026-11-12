oh-my-posh init pwsh | Invoke-Expression

Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

Invoke-Expression (& { (zoxide init powershell | Out-String) })

Set-Alias ll Get-ChildItem
Set-Alias g git
# claude 세션 이름 자동 지정: <사용자>-<현재 디렉토리 이름>
# -n/--name, 재개(-r/-c), -p 모드일 땐 건드리지 않음
# claude ds -> 첫 프롬프트로 /dev-start 실행 (지난 세션 캐치업)
function claude {
    $exe = "$env:USERPROFILE\.local\bin\claude.exe"
    if ($args.Count -gt 0 -and $args[0] -eq 'ds') { $args = @('/dev-start') + @($args | Select-Object -Skip 1) }
    $skip = $args | Where-Object { $_ -match '^(-n|--name|-r|--resume|-c|--continue|-p|--print)$' }
    if ($skip) { & $exe @args; return }
    $cwd = Get-Location; $parent = Split-Path -Leaf (Split-Path -Parent $cwd); $name = "$env:USERNAME-$parent-$(Split-Path -Leaf $cwd)"
    & $exe -n $name @args
}

# >>> cc: Windows Terminal 에서 Claude 탭/분할창 열기 (2026-10-26 추가) >>>
# cc  <폴더> [이름] [색]       현재 창에 새 탭
# ccs <폴더> [이름] [색] [-H]  지금 pane 옆에 분할 (-H 면 아래로)
# ccl [monitor|repo|hub|project|news|mail] 프리셋 배치. 인자 없으면 전부 탭으로
# ccl [프리셋] resume          위와 같고, 모든 pane 이 /dev-start 로 시작 (claude ds). 'ccl resume 프리셋' 순서도 됨
# <폴더>: 경로, 또는 zoxide 검색어 (ccs vault, cc repo)
# 색: red orange yellow green teal blue purple pink gray (Catppuccin Mocha 값), 또는 #RRGGBB
# 이름은 claude 가 도는 동안 $env:CC_TAB 에 들어가 ~/.claude/hooks/notify.ps1 토스트 제목에 쓰인다.
# 원복: (1) 이 블록 삭제
#       (2) %LOCALAPPDATA%\Microsoft\Windows Terminal\Fragments\claude-cc 폴더 삭제
#       (3) WT settings.json 의 profiles.list 에서 "source": "claude-cc" 항목 전부 삭제 (Fragments 를 읽을 때 WT 가 스스로 넣은 것)
#       (4) notify.ps1 의 CC_TAB 줄은 남겨도 된다 (CC_TAB 이 없으면 예전과 같다)
$CcColors = @{
    red = '#F38BA8'; orange = '#FAB387'; yellow = '#F9E2AF'; green = '#A6E3A1'; teal = '#94E2D5'
    blue = '#89B4FA'; purple = '#CBA6F7'; pink = '#F5C2E7'; gray = '#6C7086'
}
# cc/ccs 는 공통 프로필 'cc' (Mocha 스킴, 비활성 pane 흐림) 로 연다.
# 프리셋 항목은 WT Fragments 프로필 'cc <이름>' 과 맞춰야 한다
# (%LOCALAPPDATA%\Microsoft\Windows Terminal\Fragments\claude-cc\cc-projects.json).
# 첫 항목은 왼쪽, 둘째는 오른쪽, 셋째부터는 오른쪽을 위아래로 쪼갠다.
# 2026-11-02 구조 설계(~/.claude/desk/structure-design.md 2.5)대로 project→lab, mail→work. data(market_feed+signals)는 2026-11-02 밤 market_feed 를 만들며 넣었다.
$CcLayouts = [ordered]@{
    monitor = @('bondswap_monitor', 'fwdcd_monitor')
    repo    = @('repo_fund')
    hub     = @('Desktop', 'Vault')
    lab     = @('project', 'study')
    data    = @('market_feed', 'signals')
    news    = @('ficc_news_alarm')
    work    = @('업무', 'mailbackup')
}

# zoxide 는 UTF-8 로 출력하는데 콘솔 기본 코드페이지(949)로 읽으면 한글 경로가 깨진다.
# zoxide init 의 __zoxide_bin 과 같은 방식으로 잠깐 UTF-8 로 바꿔서 읽는다.
function Invoke-CcZoxide {
    $enc = [Console]::OutputEncoding
    try { [Console]::OutputEncoding = [Text.UTF8Encoding]::new(); zoxide @args 2>$null }
    finally { [Console]::OutputEncoding = $enc }
}

# wt 는 인자 속 ';' 를 자기 명령 구분자로 읽는다. 값에 든 ';' 는 '\;' 로 넘긴다.
function ConvertTo-CcWtValue([string]$s) { $s -replace ';', '\;' }

# PowerShell 작은따옴표 문자열 안에 넣을 수 있게 이스케이프 (' 뿐 아니라 ’ ‘ 도 따옴표로 읽힌다)
function ConvertTo-CcQuoted([string]$s) { [System.Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent($s) }

function Get-CcPaneArgs {
    param([string]$Path, [string]$Name, [string]$Color)
    $ErrorActionPreference = 'Stop'  # 중간에 하나라도 실패하면 wt 를 부르지 않는다
    # 있는 폴더면 그대로, 아니면 zoxide 검색어로 본다 (ccs vault -> Desktop\Vault)
    $dir = if (Test-Path -LiteralPath $Path -PathType Container) {
        # 친 대소문자 그대로 돌아오므로 (vault) 실제 폴더 이름 (Vault) 으로 맞춘다. 숨김 폴더도 받게 -Force
        $item = Get-Item -LiteralPath $Path -Force
        if ($item.Parent) { $item.Parent.GetDirectories($item.Name)[0].FullName } else { $item.FullName }
    } else {
        $z = Invoke-CcZoxide query -- $Path | Select-Object -First 1
        if (-not $z) { throw "폴더를 못 찾음: $Path (경로도 아니고 zoxide 기록에도 없음)" }
        Write-Host "zoxide: $z" -ForegroundColor DarkGray
        $z
    }
    $dir = $dir.TrimEnd('\')
    if ($dir -match '^[A-Za-z]:$') { $dir += '\.' }  # "C:\" 로 넘기면 끝의 \" 가 따옴표를 먹는다
    if (-not $Name) { $Name = Split-Path -Leaf $dir }
    $a = @('-p', 'cc', '-d', (ConvertTo-CcWtValue $dir), '--title', (ConvertTo-CcWtValue $Name), '--suppressApplicationTitle')
    if ($Color) {
        $hex = if ($Color -match '^#[0-9A-Fa-f]{6}$') { $Color } else { $CcColors[$Color.ToLower()] }
        if (-not $hex) { throw "모르는 색: $Color (쓸 수 있는 색: $($CcColors.Keys -join ', '))" }
        $a += @('--tabColor', $hex)
    }
    $a + (Get-CcShell $Name)
}

# pane 안에서 돌 셸 명령. 셸 명령 속 ';' 가 wt 에 쪼개지지 않게 EncodedCommand 로 넘긴다.
# claude 가 끝나면 CC_TAB 을 지운다. 같은 pane 에서 다른 폴더로 옮겨 claude 를 다시 띄울 때 옛 이름이 토스트에 붙지 않게.
function Get-CcShell {
    param([string]$Name, [string]$Claude = 'claude')
    $cmd = "`$env:CC_TAB = '$(ConvertTo-CcQuoted $Name)'; try { $Claude } finally { Remove-Item Env:CC_TAB -ErrorAction Ignore }"
    $enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($cmd))
    @('pwsh', '-NoLogo', '-NoExit', '-EncodedCommand', $enc)
}

function cc {
    param([Parameter(Mandatory)][string]$Path, [string]$Name, [string]$Color)
    $a = Get-CcPaneArgs $Path $Name $Color
    wt.exe -w 0 nt @a
}

function ccs {
    param([Parameter(Mandatory)][string]$Path, [string]$Name, [string]$Color, [switch]$H)
    $a = Get-CcPaneArgs $Path $Name $Color
    wt.exe -w 0 sp $(if ($H) { '-H' } else { '-V' }) @a
}

function ccl {
    param([string]$Layout, [string]$Mode)
    if ($Layout -eq 'resume') { $Layout, $Mode = $Mode, 'resume' }  # 'ccl resume monitor' 순서도 받는다
    if ($Mode -and $Mode -ne 'resume') { throw "모르는 옵션: $Mode (resume 만 있음)" }
    $names = if ($Layout) { @($Layout) } else { @($CcLayouts.Keys) }
    # resume 이면 프로필의 commandline 대신 'claude ds' 를 넘긴다. 폴더·색은 프로필 것을 그대로 쓴다.
    # 탭 제목은 포커스된 pane 것을 따라가므로 pane 이 여럿인 탭은 모든 pane 에 같은 합친 제목을 준다.
    $pane = { param($p, $t) @('-p', "cc $p") + $(if ($t) { @('--title', $t) } else { @() }) + $(if ($Mode) { Get-CcShell $p 'claude ds' } else { @() }) }
    $a = @('-w', '0')
    foreach ($l in $names) {
        $panes = $CcLayouts[$l]
        if (-not $panes) { throw "모르는 프리셋: $l (있는 것: $($CcLayouts.Keys -join ', '))" }
        if ($a.Count -gt 2) { $a += ';' }
        # 합친 제목은 탭 폭에 들어가게 '_' 앞부분만 쓴다 (bondswap_monitor -> bondswap)
        $title = if ($panes.Count -gt 1) { ($panes | ForEach-Object { ($_ -split '_')[0] }) -join ' | ' }
        $a += @('nt') + (& $pane $panes[0] $title)
        for ($i = 1; $i -lt $panes.Count; $i++) {
            $a += @(';', 'sp', $(if ($i -eq 1) { '-V' } else { '-H' })) + (& $pane $panes[$i] $title)
        }
    }
    wt.exe @a
}

# Tab 완성: ccl 프리셋, 색 이름, 폴더 (지금 위치의 하위 폴더 먼저, 그 다음 zoxide 기록)
function New-CcCompletion([string]$Text, [string]$List = $Text, [string]$Tip = $Text, [string]$Type = 'ParameterValue') {
    [System.Management.Automation.CompletionResult]::new($Text, $List, $Type, $Tip)
}
# 완성 후보를 명령줄에 그대로 넣을 수 있게: 공백, 따옴표, ; ( ) 같은 문자가 있거나 - 로 시작하면 작은따옴표로 감싼다
function ConvertTo-CcArgText([string]$t) {
    if ($t -match '[^\w\\/:.~-]' -or $t.StartsWith('-')) { "'$(ConvertTo-CcQuoted $t)'" } else { $t }
}
Register-ArgumentCompleter -CommandName ccl -ParameterName Layout -ScriptBlock {
    param($cmd, $param, $word)
    @($CcLayouts.Keys) + 'resume' | Where-Object { $_ -like "$word*" } | ForEach-Object { New-CcCompletion $_ }
}
Register-ArgumentCompleter -CommandName ccl -ParameterName Mode -ScriptBlock {
    param($cmd, $param, $word, $ast, $bound)
    # 'ccl resume <Tab>' 이면 프리셋을, 아니면 resume 을 낸다
    $opts = if ($bound['Layout'] -eq 'resume') { @($CcLayouts.Keys) } else { @('resume') }
    $opts | Where-Object { $_ -like "$word*" } | ForEach-Object { New-CcCompletion $_ }
}
Register-ArgumentCompleter -CommandName cc, ccs -ParameterName Color -ScriptBlock {
    param($cmd, $param, $word)
    $CcColors.Keys | Sort-Object | Where-Object { $_ -like "$word*" } | ForEach-Object { New-CcCompletion $_ $_ $CcColors[$_] }
}
Register-ArgumentCompleter -CommandName cc, ccs -ParameterName Path -ScriptBlock {
    param($cmd, $param, $word)
    $w = $word.Trim("'", '"')
    # 친 앞부분(마지막 구분자까지)은 그대로 두고 그 뒤만 폴더 이름으로 채운다 (task\ -> task\repo_fund)
    $prefix = $w.Substring(0, $w.LastIndexOfAny([char[]]'\/:') + 1)
    $leaf = $w.Substring($prefix.Length)
    $base = if ($prefix) { $prefix } else { '.' }
    Get-ChildItem -LiteralPath $base -Directory -Filter "$leaf*" -ErrorAction SilentlyContinue | ForEach-Object {
        New-CcCompletion (ConvertTo-CcArgText ($prefix + $_.Name)) $_.Name $_.FullName 'ProviderContainer'
    }
    # 경로처럼 생긴 입력은 zoxide 검색어로 쓰지 않는다
    if (-not $prefix) {
        Invoke-CcZoxide query -l -- $w | Select-Object -First 15 | ForEach-Object {
            New-CcCompletion (ConvertTo-CcArgText $_) "$(Split-Path $_ -Leaf)  (zoxide)" $_ 'ProviderContainer'
        }
    }
}
# <<< cc <<<

# >>> CompletionPredictor: Tab 완성 후보를 입력 중 추천 목록에도 띄움 (2026-10-26 추가. 원복은 이 블록 삭제 + Uninstall-PSResource CompletionPredictor) >>>
# 바로 Import 하면 'pwsh -Command ...' 처럼 잠깐 도는 프로세스가 끝나지 않고 멈춘다.
# 대화형 셸이 처음 입력을 기다릴 때(OnIdle) 한 번만 불러온다. -Command 실행에서는 OnIdle 이 오지 않는다.
$null = Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action {
    Import-Module CompletionPredictor -Global -ErrorAction SilentlyContinue
}
# <<< CompletionPredictor <<<
