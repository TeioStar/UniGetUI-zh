param(
    [string]$UpstreamUrl = "https://github.com/Devolutions/UniGetUI.git",
    [string]$UpstreamRemote = "upstream",
    [string]$UpstreamBranch = "main"
)

$ErrorActionPreference = "Stop"

function Invoke-Git {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)

    & git @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Arguments -join ' ') failed with exit code $LASTEXITCODE"
    }
}

$repoRoot = Invoke-Git rev-parse --show-toplevel
Set-Location $repoRoot

$currentBranch = (& git branch --show-current).Trim()
if ([string]::IsNullOrWhiteSpace($currentBranch)) {
    throw "Detached HEAD is not supported. Switch to a branch before syncing."
}

$dirtyState = (& git status --porcelain)
if ($dirtyState) {
    throw "Working tree has uncommitted changes. Commit or stash them before syncing."
}

$remoteExists = $false
try {
    Invoke-Git remote get-url $UpstreamRemote | Out-Null
    $remoteExists = $true
}
catch {
    $remoteExists = $false
}

if (-not $remoteExists) {
    Invoke-Git remote add $UpstreamRemote $UpstreamUrl
}

Invoke-Git fetch $UpstreamRemote $UpstreamBranch --prune
Invoke-Git rebase "$UpstreamRemote/$UpstreamBranch"
Invoke-Git branch --set-upstream-to="$UpstreamRemote/$UpstreamBranch" $currentBranch

Write-Host "Synced $currentBranch with $UpstreamRemote/$UpstreamBranch."
