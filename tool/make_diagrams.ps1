# 生成教程配图（纯本地绘制，无需联网）。
# 用法： powershell -ExecutionPolicy Bypass -File tool/make_diagrams.ps1
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $PSScriptRoot
$outDir = Join-Path $root 'assets/content/images'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

function New-StackDiagram {
  param(
    [string]$File,
    [string]$Title,
    [string[]]$Items,
    [string[]]$Colors,
    [string]$Footnote = ''
  )
  $width = 1000
  $rowHeight = 84
  $height = 120 + $Items.Count * $rowHeight + 60
  $bitmap = New-Object System.Drawing.Bitmap($width, $height)
  $g = [System.Drawing.Graphics]::FromImage($bitmap)
  $g.SmoothingMode = 'AntiAlias'
  $g.TextRenderingHint = 'ClearTypeGridFit'
  $g.Clear([System.Drawing.Color]::White)

  $titleFont = New-Object System.Drawing.Font('Microsoft YaHei', 26, [System.Drawing.FontStyle]::Bold)
  $itemFont = New-Object System.Drawing.Font('Microsoft YaHei', 18)
  $noteFont = New-Object System.Drawing.Font('Microsoft YaHei', 14)
  $brush = [System.Drawing.Brushes]::Black
  $g.DrawString($Title, $titleFont, $brush, 40, 30)

  for ($i = 0; $i -lt $Items.Count; $i++) {
    $y = 110 + $i * $rowHeight
    $rect = New-Object System.Drawing.Rectangle(60, $y, ($width - 120), 64)
    $rectF = New-Object System.Drawing.RectangleF(60, $y, ($width - 120), 64)
    $color = [System.Drawing.ColorTranslator]::FromHtml($Colors[$i % $Colors.Count])
    $fill = New-Object System.Drawing.SolidBrush($color)
    $g.FillRectangle($fill, $rect)
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(60, 60, 60), 1.5)
    $g.DrawRectangle($pen, $rect)
    $format = New-Object System.Drawing.StringFormat
    $format.Alignment = 'Center'
    $format.LineAlignment = 'Center'
    $g.DrawString($Items[$i], $itemFont, $brush, $rectF, $format)
  }
  if ($Footnote) {
    $g.DrawString($Footnote, $noteFont, [System.Drawing.Brushes]::DimGray, 60, ($height - 50))
  }
  $g.Dispose()
  $path = Join-Path $outDir $File
  $bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $bitmap.Dispose()
  Write-Host "生成 $File"
}

New-StackDiagram -File 'memory_hierarchy.png' -Title '存储器层次结构：越靠上越快越小越贵' -Items @(
  '寄存器（<1 KB，~0.3 ns）',
  'L1 缓存（~64 KB，~1 ns）',
  'L2 缓存（~512 KB，~4 ns）',
  'L3 缓存（~8 MB，~15 ns）',
  '主存 DRAM（~16 GB，~100 ns）',
  'SSD（~1 TB，~100 μs）',
  '机械硬盘（~4 TB，~10 ms）'
) -Colors @('#DBEAFE', '#BFDBFE', '#93C5FD', '#60A5FA', '#34D399', '#FBBF24', '#F87171') `
  -Footnote '越靠近 CPU 越快：寄存器 → 缓存 → 主存 → 磁盘'

New-StackDiagram -File 'tcp_ip_layers.png' -Title 'TCP/IP 分层与数据封装' -Items @(
  '应用层  HTTP / DNS / SMTP       数据：用户请求',
  '传输层  TCP / UDP               加 TCP 头：端口 + 序号',
  '网络层  IP / ICMP               加 IP 头：源/目的地址',
  '链路层  Ethernet / Wi-Fi        加帧头帧尾：MAC 地址'
) -Colors @('#DBEAFE', '#BFDBFE', '#93C5FD', '#60A5FA') `
  -Footnote '发送时自上而下逐层加头，接收时自下而上逐层解封装'

New-StackDiagram -File 'transformer_blocks.png' -Title 'Transformer 解码器单层结构' -Items @(
  '输入 Token → 词嵌入 + 位置编码',
  '多头自注意力（Self-Attention）',
  '残差连接 + 层归一化',
  '前馈网络 FFN（两层 MLP）',
  '残差连接 + 层归一化',
  '输出 → 下一个 Token 的概率分布'
) -Colors @('#DBEAFE', '#BFDBFE', '#93C5FD', '#BFDBFE', '#93C5FD', '#A7F3D0') `
  -Footnote '多层堆叠 + 自回归采样即可逐字生成文本'
