# P2 图片压缩：把课程目录中的 PNG 转为 WebP，并同步 Markdown 引用。
#
# 用法：
#   powershell -ExecutionPolicy Bypass -File tool/optimize_content_images.ps1
param(
    [string]$FfmpegPath = "C:\MediaToolkit\ffmpeg.exe",
    [int]$Quality = 82
)

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$imageDir = (Resolve-Path (Join-Path $projectRoot "assets\content\images")).Path

if (-not $imageDir.StartsWith($projectRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Image directory escaped the project root: $imageDir"
}
if (-not (Test-Path -LiteralPath $FfmpegPath -PathType Leaf)) {
    throw "ffmpeg not found: $FfmpegPath"
}

$beforeBytes = (Get-ChildItem -LiteralPath $imageDir -File | Measure-Object Length -Sum).Sum
$pngs = Get-ChildItem -LiteralPath $imageDir -File -Filter *.png
$converted = 0

foreach ($png in $pngs) {
    $target = Join-Path $png.DirectoryName ($png.BaseName + ".webp")
    $targetFull = [System.IO.Path]::GetFullPath($target)
    if (-not $targetFull.StartsWith($imageDir, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Target escaped the image directory: $targetFull"
    }

    if (-not (Test-Path -LiteralPath $targetFull) -or (Get-Item $targetFull).LastWriteTimeUtc -lt $png.LastWriteTimeUtc) {
        & $FfmpegPath -y -loglevel error -i $png.FullName -c:v libwebp -quality $Quality -compression_level 6 $targetFull
        if ($LASTEXITCODE -ne 0) {
            throw "ffmpeg failed for $($png.Name)"
        }
    }

    $oldReference = "images/$($png.Name)"
    $newReference = "images/$($png.BaseName).webp"
    Get-ChildItem -LiteralPath (Join-Path $projectRoot "assets\content") -Recurse -File -Filter *.md | ForEach-Object {
        $text = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
        if ($text.Contains($oldReference)) {
            Set-Content -LiteralPath $_.FullName -Value $text.Replace($oldReference, $newReference) -Encoding UTF8 -NoNewline
        }
    }

    $resolvedPng = (Resolve-Path -LiteralPath $png.FullName).Path
    if (-not $resolvedPng.StartsWith($imageDir, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove file outside image directory: $resolvedPng"
    }
    Remove-Item -LiteralPath $resolvedPng
    $converted++
}

$afterBytes = (Get-ChildItem -LiteralPath $imageDir -File | Measure-Object Length -Sum).Sum
$remainingPng = (Get-ChildItem -LiteralPath $imageDir -File -Filter *.png).Count
Write-Output "converted=$converted remaining_png=$remainingPng before_mb=$([Math]::Round($beforeBytes / 1MB, 2)) after_mb=$([Math]::Round($afterBytes / 1MB, 2))"
