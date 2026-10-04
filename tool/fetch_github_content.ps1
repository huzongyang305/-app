# 从 GitHub 拉取开源 Markdown 教程到 assets/content/github，并生成索引。
# 用法： powershell -ExecutionPolicy Bypass -File tool/fetch_github_content.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$outDir = Join-Path $root 'assets/content/github'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

# 只收录允许再分发的开源内容；每条都记录仓库、许可证与原始链接。
$sources = @(
  @{ id='system-design';  repo='donnemartin/system-design-primer'; ref='master'; path='solutions/system_design'; mode='subdirs'; license='CC BY 4.0'; titleZh='系统设计案例'; titleEn='System Design Cases'; max=8 },
  @{ id='genai-beginners'; repo='microsoft/generative-ai-for-beginners'; ref='main'; path=''; mode='files'; license='MIT'; titleZh='生成式 AI 入门（微软）'; titleEn='Generative AI for Beginners'; max=8; files=@(
      '01-introduction-to-genai/README.md','02-exploring-and-comparing-different-llms/README.md','03-using-generative-ai-responsibly/README.md','04-prompt-engineering-fundamentals/README.md','05-advanced-prompts/README.md','06-text-generation-apps/README.md','07-building-chat-applications/README.md','08-building-search-applications/README.md') },
  @{ id='openai-cookbook'; repo='openai/openai-cookbook'; ref='main'; path='articles'; mode='files'; license='MIT'; titleZh='OpenAI Cookbook 实践'; titleEn='OpenAI Cookbook'; max=8; files=@(
      'articles/how_to_work_with_large_language_models.md','articles/techniques_to_improve_reliability.md','articles/text_comparison_examples.md','articles/what_makes_documentation_good.md','articles/related_resources.md','articles/openai-harmony.md') },
  @{ id='clean-code-js';  repo='ryanmcdermott/clean-code-javascript'; ref='master'; path=''; mode='files'; license='MIT'; titleZh='JavaScript 整洁代码'; titleEn='Clean Code JavaScript'; max=8 }
)

# 仓库维护类文件不是知识点，直接排除。
$excludePattern = '^(AGENTS|CHANGELOG|CODE_OF_CONDUCT|CONTRIBUTING|SECURITY|SUPPORT|LICENSE|NOTICE|TRANSLATIONS)$'

function Get-GitHubJson([string]$url) {
  $headers = @{ 'User-Agent' = 'code-learn-app-sync' }
  if ($env:GITHUB_TOKEN) { $headers['Authorization'] = "Bearer $($env:GITHUB_TOKEN)" }
  Invoke-RestMethod -Uri $url -Headers $headers -TimeoutSec 60
}

function Convert-ToSlug([string]$name) {
  ($name -replace '[^A-Za-z0-9\-_]', '-').ToLower()
}

# 用 jsDelivr 的文件树接口列目录：不消耗 GitHub API 配额，国内网络也可达。
function Get-MarkdownFiles($source) {
  if ($source.files) {
    return $source.files | ForEach-Object {
      [pscustomobject]@{
        name         = [IO.Path]::GetFileName($_)
        path         = $_
        download_url = "https://cdn.jsdelivr.net/gh/$($source.repo)@$($source.ref)/$_"
        html_url     = "https://github.com/$($source.repo)/blob/$($source.ref)/$_"
      }
    }
  }
  $url = "https://data.jsdelivr.com/v1/packages/gh/$($source.repo)@$($source.ref)?structure=flat"
  $data = Invoke-RestMethod -Uri $url -Headers @{ 'User-Agent' = 'code-learn-app-sync' } -TimeoutSec 60
  $prefix = if ($source.path) { "$($source.path)/" } else { '' }
  $candidates = $data.files |
    ForEach-Object { $_.name.TrimStart('/') } |
    Where-Object { $_ -like "$prefix*" } |
    ForEach-Object { $_.Substring($prefix.Length) }
  $selected = if ($source.mode -eq 'subdirs') {
    $candidates | Where-Object { $_ -match '^[^/]+/README\.md$' }
  } else {
    $candidates | Where-Object {
      $_ -notmatch '/' -and $_ -like '*.md' -and
      ([IO.Path]::GetFileNameWithoutExtension($_) -notmatch $excludePattern)
    }
  }
  return $selected | Sort-Object | Select-Object -First $source.max | ForEach-Object {
    [pscustomobject]@{
      name         = [IO.Path]::GetFileName($_)
      path         = "$prefix$_"
      download_url = "https://cdn.jsdelivr.net/gh/$($source.repo)@$($source.ref)/$prefix$_"
      html_url     = "https://github.com/$($source.repo)/blob/$($source.ref)/$prefix$_"
    }
  }
}

$categories = @()
foreach ($source in $sources) {
  Write-Host "==> 拉取 $($source.repo)"
  $dir = Join-Path $outDir $source.id
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $lessons = @()
  try {
    $files = Get-MarkdownFiles $source
  } catch {
    Write-Warning "跳过 $($source.repo)：$_"
    continue
  }
  foreach ($file in $files) {
    # 章节型仓库的文件名都是 README.md，用所属目录名作为标题，避免标题重复与 ID 冲突。
    $base = [IO.Path]::GetFileNameWithoutExtension($file.name)
    if ($base -eq 'README') {
      $parentPath = Split-Path $file.path -Parent
      if ($parentPath) {
        $parent = Split-Path $parentPath -Leaf
        if ($parent) { $base = $parent }
      }
    }
    $slug = Convert-ToSlug $base
    $lessonId = "gh_$($source.id)_$slug"
    $targetName = "$lessonId.md"
    $targetPath = Join-Path $dir $targetName
    $cdnUrl = "https://cdn.jsdelivr.net/gh/$($source.repo)@$($source.ref)/$($file.path)"
    # raw.githubusercontent.com 在部分网络不可达；用 curl 走 jsDelivr CDN，失败再回退 GitHub API。
    $tmp = [IO.Path]::GetTempFileName()
    curl.exe -sL --max-time 60 -o "$tmp" "$cdnUrl"
    $content = if ((Test-Path $tmp) -and (Get-Item $tmp).Length -gt 0) {
      [System.IO.File]::ReadAllText($tmp, [System.Text.Encoding]::UTF8)
    } else { $null }
    Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    if (-not $content) {
      try {
        $meta = Get-GitHubJson "https://api.github.com/repos/$($source.repo)/contents/$($file.path)?ref=$($source.ref)"
        $content = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($meta.content))
      } catch {
        Write-Warning "下载失败 $($file.path)"
        continue
      }
    }
    $front = "# 来源与许可`n`n- 仓库：https://github.com/$($source.repo)`n- 文件：$($file.path)`n- 许可证：$($source.license)`n- 原始链接：$($file.html_url)`n`n---`n`n"
    [System.IO.File]::WriteAllText($targetPath, $front + $content, (New-Object System.Text.UTF8Encoding($false)))
    $lessons += [pscustomobject]@{
      id      = $lessonId
      title   = @{ zh = $base; en = $base }
      summary = @{ zh = "来自 $($source.repo)（$($source.license)）"; en = "From $($source.repo) ($($source.license))" }
      file    = "assets/content/github/$($source.id)/$targetName"
      minutes = 10
      keywords= @($source.id, 'github', '开源教程')
      source  = @{ repo = $source.repo; url = $file.html_url; license = $source.license }
      quiz    = @()
    }
  }
  if ($lessons.Count -gt 0) {
    $categories += [pscustomobject]@{
      id      = "gh_$($source.id)"
      title   = @{ zh = $source.titleZh; en = $source.titleEn }
      icon    = 'book'
      color   = '0F766E'
      lessons = $lessons
    }
  }
}

$manifest = [pscustomobject]@{
  version    = 1
  generatedAt= (Get-Date).ToUniversalTime().ToString('s') + 'Z'
  categories = $categories
}
$manifestPath = Join-Path $outDir 'manifest.json'
[System.IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 100), (New-Object System.Text.UTF8Encoding($false)))
$total = ($categories | ForEach-Object { $_.lessons.Count } | Measure-Object -Sum).Sum
Write-Host "完成：$($categories.Count) 个分类，$total 篇教程 -> assets/content/github"
