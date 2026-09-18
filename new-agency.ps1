param(
  [Parameter(Mandatory=$true)][string]$Name,      # 영업대행사명 (예: 글로뷰티)
  [Parameter(Mandatory=$true)][string]$Slug,      # 주소 폴더명, 영문 소문자 (예: globeauty)
  [string]$ScriptUrl = "",                        # 테스트용 Apps Script 배포 주소 (비우면 템플릿 그대로 = 운영 주소)
  [switch]$NoPush                                 # 커밋·푸시 없이 파일만 만들 때
)
# 사용법: powershell -NoProfile -ExecutionPolicy Bypass -File .\new-agency.ps1 -Name "글로뷰티" -Slug globeauty
# 결과 주소: https://marketing173.github.io/kbs-contract/<Slug>/
$ErrorActionPreference = "Stop"
$Repo = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Repo
if ($Slug -notmatch '^[a-z0-9-]+$') { throw "Slug 는 영문 소문자·숫자·하이픈만 가능합니다: $Slug" }

$tpl = [IO.File]::ReadAllText((Join-Path $Repo "_template\index.html"), [Text.Encoding]::UTF8)
if ($tpl -notmatch '__AGENCY_NAME__') { throw "템플릿에 __AGENCY_NAME__ 자리가 없습니다." }
$html = $tpl.Replace('__AGENCY_NAME__', $Name)
if ($ScriptUrl) {
  $html = [regex]::Replace($html, 'const SCRIPT_URL = "[^"]+";', ('const SCRIPT_URL = "' + $ScriptUrl + '";'))
}
$dir = Join-Path $Repo $Slug
New-Item -ItemType Directory -Force $dir | Out-Null
$utf8 = New-Object Text.UTF8Encoding($false)
[IO.File]::WriteAllText((Join-Path $dir "index.html"), $html, $utf8)
Write-Host ("생성: {0}\index.html (대행사: {1})" -f $dir, $Name)

if ($NoPush) { exit 0 }
git add -- "$Slug/index.html"
$changed = git status --porcelain -- "$Slug/index.html"
if (-not $changed) { Write-Host "변경 없음 - 푸시하지 않았습니다."; exit 0 }
git commit --quiet -m ("Add agency page: {0} ({1})" -f $Name, $Slug)
git push origin main
if (-not $?) { throw "push 실패" }
Write-Host ("푸시 완료. 1~2분 뒤 https://marketing173.github.io/kbs-contract/{0}/ 에서 열립니다." -f $Slug)
