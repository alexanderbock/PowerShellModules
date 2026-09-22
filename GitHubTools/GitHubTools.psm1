function Sync-GitHubRepos {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$Org,
    [string]$Root = (Get-Location).Path
  )

  $json = gh repo list $Org --limit 1000 --json name
  if ($LASTEXITCODE -ne 0) {
    Write-Error "Could not list repositories for '$Org'. Is gh installed and authenticated?"
    return
  }
  $repos = $json | ConvertFrom-Json | Sort-Object name

  foreach ($repo in $repos) {
    $name = $repo.name
    $path = Join-Path $Root $name

    if (-not (Test-Path $path)) {
      Write-Host "[clone] $name" -ForegroundColor Cyan
      gh repo clone "$Org/$name" $path -- --recursive
      continue
    }

    if (-not (Test-Path (Join-Path $path ".git"))) {
      Write-Warning "[skip]  $name exists but is not a git repository"
      continue
    }

    $changes = git -C $path status --porcelain --untracked-files=no
    if ($changes) {
      Write-Host "[skip]  $name has local changes, not updating" -ForegroundColor Yellow
      continue
    }

    Write-Host "[pull]  $name" -ForegroundColor Green
    git -C $path pull --ff-only --recurse-submodules
  }
}

Export-ModuleMember -Function Sync-GitHubRepos
