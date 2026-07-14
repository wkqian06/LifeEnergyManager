# Reusable renderer for the LifeEnergyManager 2560x1440 daily wallpaper.
# All environment-specific configuration is passed to Invoke-LifeEnergyWallpaperRender.

function ConvertTo-LemColor([string]$Hex) {
  [System.Drawing.ColorTranslator]::FromHtml($Hex)
}

function New-LemFont([single]$Size, [string]$Style = 'Regular') {
  New-Object System.Drawing.Font('Segoe UI', $Size, [System.Drawing.FontStyle]::$Style, [System.Drawing.GraphicsUnit]::Pixel)
}

function New-LemBrush($Color) {
  New-Object System.Drawing.SolidBrush($Color)
}

function Measure-LemText($Graphics, [string]$Text, $Font, [single]$Width) {
  $format = [System.Drawing.StringFormat]::GenericTypographic.Clone()
  $format.Trimming = [System.Drawing.StringTrimming]::None
  $layout = New-Object System.Drawing.SizeF($Width, 10000)
  try { return $Graphics.MeasureString($Text, $Font, $layout, $format) }
  finally { $format.Dispose() }
}

function Get-LemConfigText($Config, [string]$Name, [string]$Fallback) {
  if (($Config.PSObject.Properties.Name -contains $Name) -and $Config.$Name) {
    return [string]$Config.$Name
  }
  return $Fallback
}

function Get-LemConfigLabel($Config, [string]$Name, [string]$Fallback) {
  if (($Config.PSObject.Properties.Name -contains 'labels') -and $Config.labels -and
      ($Config.labels.PSObject.Properties.Name -contains $Name) -and $Config.labels.$Name) {
    return [string]$Config.labels.$Name
  }
  return $Fallback
}

function Draw-LemText($Graphics, [string]$Text, $Font, $Color,
                      [single]$X, [single]$Y, [single]$Width, [single]$Height) {
  $safeText = if ($null -eq $Text) { '' } else { $Text }
  $measured = Measure-LemText $Graphics $safeText $Font $Width
  if ($measured.Height -gt $Height) {
    throw "Wallpaper text does not fit without truncation: $safeText"
  }
  $rectangle = New-Object System.Drawing.RectangleF($X, $Y, $Width, $Height)
  $format = [System.Drawing.StringFormat]::GenericTypographic.Clone()
  $format.Trimming = [System.Drawing.StringTrimming]::None
  $brush = New-LemBrush $Color
  try {
    $Graphics.DrawString($safeText, $Font, $brush, $rectangle, $format)
  } finally {
    $brush.Dispose()
    $format.Dispose()
  }
}

function Draw-LemSizedText($Graphics, [string]$Text, [single]$Size, [string]$Style,
                           $Color, [single]$X, [single]$Y, [single]$Width, [single]$Height) {
  $font = New-LemFont $Size $Style
  try {
    Draw-LemText $Graphics $Text $font $Color $X $Y $Width $Height
  } finally {
    $font.Dispose()
  }
}

function Draw-LemFittedText($Graphics, [string]$Text, [single]$StartSize,
                            [single]$MinSize, [string]$Style, $Color,
                            [single]$X, [single]$Y, [single]$Width, [single]$Height) {
  for ($size = $StartSize; $size -ge $MinSize; $size -= 1) {
    $font = New-LemFont $size $Style
    try {
      $measured = Measure-LemText $Graphics $Text $font $Width
      if ($measured.Height -le $Height) {
        Draw-LemText $Graphics $Text $font $Color $X $Y $Width $Height
        return
      }
    } finally {
      $font.Dispose()
    }
  }
  throw "Wallpaper text does not fit without truncation: $Text"
}

function New-LemRoundedPath([single]$X, [single]$Y, [single]$Width,
                            [single]$Height, [single]$Radius = 12) {
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $diameter = 2 * $Radius
  $path.AddArc($X, $Y, $diameter, $diameter, 180, 90)
  $path.AddArc($X + $Width - $diameter, $Y, $diameter, $diameter, 270, 90)
  $path.AddArc($X + $Width - $diameter, $Y + $Height - $diameter, $diameter, $diameter, 0, 90)
  $path.AddArc($X, $Y + $Height - $diameter, $diameter, $diameter, 90, 90)
  $path.CloseFigure()
  return $path
}

function Draw-LemPanel($Graphics, $LineColor, [single]$X, [single]$Y,
                       [single]$Width, [single]$Height, $Fill) {
  $path = New-LemRoundedPath $X $Y $Width $Height 12
  $fillBrush = New-LemBrush $Fill
  $pen = New-Object System.Drawing.Pen($LineColor, 2)
  try {
    $Graphics.FillPath($fillBrush, $path)
    $Graphics.DrawPath($pen, $path)
  } finally {
    $fillBrush.Dispose()
    $pen.Dispose()
    $path.Dispose()
  }
}

function Add-LemSolidRectangle($Graphics, $Color, [single]$X, [single]$Y,
                               [single]$Width, [single]$Height) {
  $brush = New-LemBrush $Color
  try { $Graphics.FillRectangle($brush, $X, $Y, $Width, $Height) }
  finally { $brush.Dispose() }
}

function Add-LemSolidEllipse($Graphics, $Color, [single]$X, [single]$Y,
                             [single]$Width, [single]$Height) {
  $brush = New-LemBrush $Color
  try { $Graphics.FillEllipse($brush, $X, $Y, $Width, $Height) }
  finally { $brush.Dispose() }
}

function Assert-LemWallpaperConfig($Config, $CategoryColors) {
  foreach ($name in @('date', 'subtitle', 'focusType', 'focusColor', 'timeMix',
                      'baseline', 'stretch', 'progress', 'status', 'advice', 'tip',
                      'planRevisionId', 'outPath')) {
    if (-not ($Config.PSObject.Properties.Name -contains $name) -or $null -eq $Config.$name) {
      throw "Wallpaper config is missing required property: $name"
    }
  }
  if (-not $CategoryColors.ContainsKey([string]$Config.focusColor)) {
    throw 'focusColor must be orange, blue, green, or gray'
  }
  $progress = @($Config.progress)
  if ($progress.Count -lt 2) { throw 'progress requires at least month and phase items' }
  if ($progress.Count -gt 5) { throw 'progress supports at most 5 items; no item was rendered' }
  foreach ($item in $progress) {
    if (-not ($item.PSObject.Properties.Name -contains 'kind') -or
        @('week', 'sprint', 'commitment', 'month', 'phase') -notcontains [string]$item.kind) {
      throw 'every progress item requires kind: week, sprint, commitment, month, or phase'
    }
  }
  if ([string]$progress[$progress.Count - 2].kind -ne 'month' -or
      [string]$progress[$progress.Count - 1].kind -ne 'phase') {
    throw 'progress order must place month second-to-last and phase last'
  }
  foreach ($item in @($Config.baseline) + @($Config.stretch) + @($Config.urgent)) {
    if ($null -ne $item -and -not $CategoryColors.ContainsKey([string]$item.color)) {
      throw "task color must be orange, blue, green, or gray: $($item.title)"
    }
  }
}

function Get-LemColumnCardHeight([int]$Count, [single]$ColumnTop) {
  if ($Count -le 0) { return 168 }
  $available = 1378 - $ColumnTop
  $height = [Math]::Min(168, [Math]::Floor($available / $Count) - 20)
  if ($height -lt 118) { throw "Too many task cards to render readably: $Count" }
  return $height
}

function Draw-LemTaskCard($Graphics, $Task, $CategoryColors, $PanelColor,
                          $LineColor, $InkColor, $MutedColor, [single]$X,
                          [ref]$YRef, [single]$Height) {
  $y = $YRef.Value
  Draw-LemPanel $Graphics $LineColor $X $y 773 $Height $PanelColor
  Add-LemSolidRectangle $Graphics $CategoryColors[[string]$Task.color] $X $y 12 $Height
  $compact = $Height -lt 168
  $titleSize = if ($compact) { 25 } else { 30 }
  $titleHeight = if ($compact) { 70 } else { 84 }
  Draw-LemSizedText $Graphics ([string]$Task.title) $titleSize 'Bold' $InkColor ($X+34) ($y+14) 590 $titleHeight
  Draw-LemSizedText $Graphics ("$($Task.minutes) min") 26 'Bold' $CategoryColors[[string]$Task.color] ($X+620) ($y+16) 140 36
  $descriptionSize = if ($compact) { 22 } else { 24 }
  Draw-LemSizedText $Graphics ([string]$Task.desc) $descriptionSize 'Regular' $MutedColor ($X+34) ($y+$titleHeight+16) 705 ($Height-$titleHeight-26)
  $YRef.Value = $y + $Height + 20
}

function Invoke-LifeEnergyWallpaperRender {
  [CmdletBinding()]
  param([Parameter(Mandatory=$true)]$Config)

  Add-Type -AssemblyName System.Drawing
  $width = 2560
  $height = 1440
  $background = ConvertTo-LemColor '#f4f6fa'
  $panel = ConvertTo-LemColor '#ffffff'
  $ink = ConvertTo-LemColor '#172033'
  $muted = ConvertTo-LemColor '#526075'
  $line = ConvertTo-LemColor '#d6deea'
  $bar = ConvertTo-LemColor '#7c8db0'
  $categories = @{
    orange = ConvertTo-LemColor '#cc7000'
    blue = ConvertTo-LemColor '#2563eb'
    green = ConvertTo-LemColor '#008057'
    gray = ConvertTo-LemColor '#64748b'
  }
  $categorySoft = @{
    orange = ConvertTo-LemColor '#fff5e6'
    blue = ConvertTo-LemColor '#edf4ff'
    green = ConvertTo-LemColor '#eaf8f1'
    gray = ConvertTo-LemColor '#f1f5f9'
  }
  $risk = @{
    approaching = ConvertTo-LemColor '#a15c00'
    critical = ConvertTo-LemColor '#b42318'
    due = ConvertTo-LemColor '#b42318'
  }
  $riskSoft = @{
    approaching = ConvertTo-LemColor '#fff7e6'
    critical = ConvertTo-LemColor '#fff0ee'
    due = ConvertTo-LemColor '#fff0ee'
  }

  Assert-LemWallpaperConfig $Config $categories
  $bitmap = New-Object System.Drawing.Bitmap($width, $height)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  try {
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
    $graphics.Clear($background)

    $titlePrefix = Get-LemConfigLabel $Config 'titlePrefix' 'Daily Plan'
    Draw-LemFittedText $graphics "$titlePrefix - $($Config.date)" 72 60 'Bold' $ink 80 55 1500 100
    Draw-LemSizedText $graphics ([string]$Config.subtitle) 32 'Regular' $muted 80 160 1500 46

    $focusX = 1660; $focusY = 45; $focusWidth = 400; $focusHeight = 140
    Draw-LemPanel $graphics $line $focusX $focusY $focusWidth $focusHeight $categorySoft[[string]$Config.focusColor]
    Add-LemSolidRectangle $graphics $categories[[string]$Config.focusColor] $focusX $focusY 12 $focusHeight
    Draw-LemSizedText $graphics (Get-LemConfigLabel $Config 'taskFocus' 'TASK FOCUS') 22 'Bold' $muted ($focusX+30) ($focusY+14) ($focusWidth-40) 32
    Draw-LemFittedText $graphics ([string]$Config.focusType) 22 18 'Bold' $categories[[string]$Config.focusColor] ($focusX+30) ($focusY+48) ($focusWidth-36) 78
    $timeX = $focusX + $focusWidth + 20
    Draw-LemPanel $graphics $line $timeX $focusY $focusWidth $focusHeight $panel
    Add-LemSolidRectangle $graphics $categories.gray $timeX $focusY 12 $focusHeight
    Draw-LemSizedText $graphics (Get-LemConfigLabel $Config 'timeMix' 'TIME MIX') 22 'Bold' $muted ($timeX+30) ($focusY+14) ($focusWidth-40) 32
    Draw-LemFittedText $graphics ([string]$Config.timeMix) 26 18 'Bold' $ink ($timeX+30) ($focusY+50) ($focusWidth-36) 78

    $legend = @(
      @{ key='orange'; text=(Get-LemConfigLabel $Config 'legendOrange' 'Orange = urgent / external / deadline') },
      @{ key='blue'; text=(Get-LemConfigLabel $Config 'legendBlue' 'Blue = deliverable / closure / visible output') },
      @{ key='green'; text=(Get-LemConfigLabel $Config 'legendGreen' 'Green = deep research / analysis / implementation') },
      @{ key='gray'; text=(Get-LemConfigLabel $Config 'legendGray' 'Gray = planning / log / admin / stop') })
    $legendX = 80
    foreach ($item in $legend) {
      Add-LemSolidEllipse $graphics $categories[$item.key] $legendX 232 22 22
      Draw-LemSizedText $graphics $item.text 22 'Regular' $muted ($legendX+32) 231 575 34
      $legendX += 620
    }

    $hasAlert = ($Config.PSObject.Properties.Name -contains 'goalAlert') -and
      $null -ne $Config.goalAlert -and $Config.goalAlert.level
    $alertLevel = if ($hasAlert) { [string]$Config.goalAlert.level } else { '' }
    if ($hasAlert -and -not $risk.ContainsKey($alertLevel)) {
      throw 'goalAlert.level must be approaching, critical, or due'
    }
    if ($hasAlert) {
      $alertX = 80; $alertY = 282; $alertWidth = 2400; $alertHeight = 104
      Draw-LemPanel $graphics $line $alertX $alertY $alertWidth $alertHeight $riskSoft[$alertLevel]
      Add-LemSolidRectangle $graphics $risk[$alertLevel] $alertX $alertY 12 $alertHeight
      $levelText = Get-LemConfigLabel $Config $alertLevel $alertLevel.ToUpperInvariant()
      Draw-LemSizedText $graphics $levelText 22 'Bold' $risk[$alertLevel] ($alertX+32) ($alertY+14) 180 32
      $extra = ''
      if ([int]$Config.goalAlert.additionalCount -gt 0) {
        $template = Get-LemConfigLabel $Config 'additionalAlerts' '+{count} more alert(s)'
        $extra = " | $($template.Replace('{count}', [string][int]$Config.goalAlert.additionalCount))"
      }
      $deadlineLabel = Get-LemConfigLabel $Config 'deadline' 'due'
      $remainingLabel = Get-LemConfigLabel $Config 'remaining' 'remaining'
      $headline = "$($Config.goalAlert.title) | $deadlineLabel $($Config.goalAlert.deadline) | $remainingLabel $($Config.goalAlert.remaining)$extra"
      Draw-LemFittedText $graphics $headline 28 22 'Bold' $ink ($alertX+225) ($alertY+9) ($alertWidth-255) 40
      $required = "$(Get-LemConfigLabel $Config 'requiredToday' 'Required today'): $($Config.goalAlert.requiredToday)"
      Draw-LemFittedText $graphics $required 25 21 'Regular' $ink ($alertX+32) ($alertY+57) ($alertWidth-64) 34
    }

    $progress = @($Config.progress)
    $progressY = if ($hasAlert) { 408 } else { 300 }
    $progressHeight = if ($hasAlert) { 130 } else { 140 }
    $progressGap = 24
    $progressWidth = [Math]::Floor((2400 - ($progress.Count - 1) * $progressGap) / $progress.Count)
    for ($index = 0; $index -lt $progress.Count; $index++) {
      $item = $progress[$index]
      $progressX = 80 + $index * ($progressWidth + $progressGap)
      Draw-LemPanel $graphics $line $progressX $progressY $progressWidth $progressHeight $panel
      Draw-LemFittedText $graphics ([string]$item.label) 26 21 'Bold' $ink ($progressX+20) ($progressY+14) ($progressWidth-150) 36
      Draw-LemFittedText $graphics ([string]$item.value) 26 20 'Bold' $muted ($progressX+$progressWidth-125) ($progressY+14) 110 36
      Add-LemSolidRectangle $graphics $line ($progressX+20) ($progressY+62) ($progressWidth-40) 16
      $fillWidth = [Math]::Max(6, ($progressWidth-40) * [Math]::Min(100, [double]$item.percent) / 100)
      Add-LemSolidRectangle $graphics $bar ($progressX+20) ($progressY+62) $fillWidth 16
      Draw-LemSizedText $graphics ([string]$item.note) 22 'Regular' $muted ($progressX+20) ($progressY+88) ($progressWidth-40) ($progressHeight-92)
    }

    $boardY = if ($hasAlert) { 570 } else { 490 }
    $boardWidth = 773; $boardGap = 40
    $boardX = @(80, (80 + $boardWidth + $boardGap), (80 + 2*($boardWidth + $boardGap)))
    $titles = @(
      (Get-LemConfigText $Config 'baselineTitle' (Get-LemConfigLabel $Config 'baselineTitle' 'Baseline 3h')),
      (Get-LemConfigText $Config 'stretchTitle' (Get-LemConfigLabel $Config 'stretchTitle' 'Later 2h stretch')),
      (Get-LemConfigLabel $Config 'statusAdvice' 'Status and advice'))
    for ($index = 0; $index -lt 3; $index++) {
      Draw-LemSizedText $graphics $titles[$index] 40 'Bold' $ink $boardX[$index] $boardY $boardWidth 54
    }
    $cardTop = $boardY + 70
    $baseline = @($Config.baseline)
    $stretch = @($Config.stretch)
    $urgent = @()
    if (($Config.PSObject.Properties.Name -contains 'urgent') -and $null -ne $Config.urgent) {
      $urgent = @($Config.urgent)
    }
    $baselineHeight = Get-LemColumnCardHeight $baseline.Count $cardTop
    $stretchHeight = Get-LemColumnCardHeight ($stretch.Count + $urgent.Count) $cardTop
    $y1 = $cardTop
    foreach ($task in $baseline) { Draw-LemTaskCard $graphics $task $categories $panel $line $ink $muted $boardX[0] ([ref]$y1) $baselineHeight }
    $y2 = $cardTop
    foreach ($task in $stretch) { Draw-LemTaskCard $graphics $task $categories $panel $line $ink $muted $boardX[1] ([ref]$y2) $stretchHeight }
    foreach ($task in $urgent) { if ($null -ne $task) { Draw-LemTaskCard $graphics $task $categories $panel $line $ink $muted $boardX[1] ([ref]$y2) $stretchHeight } }

    $blocks = @(
      @{ heading=(Get-LemConfigLabel $Config 'statusSummary' 'Status summary'); text=$Config.status },
      @{ heading=(Get-LemConfigLabel $Config 'todayAdvice' 'Today advice'); text=$Config.advice },
      @{ heading=(Get-LemConfigLabel $Config 'antiDistraction' 'Anti-distraction tip'); text=$Config.tip })
    $rightY = $cardTop
    $rightHeight = [Math]::Floor((1378 - $cardTop - 52) / 3)
    foreach ($block in $blocks) {
      Draw-LemPanel $graphics $line $boardX[2] $rightY 773 $rightHeight $panel
      Add-LemSolidRectangle $graphics $categories.gray $boardX[2] $rightY 12 $rightHeight
      Draw-LemSizedText $graphics $block.heading 28 'Bold' $muted ($boardX[2]+34) ($rightY+20) 705 38
      Draw-LemFittedText $graphics ([string]$block.text) 30 22 'Regular' $ink ($boardX[2]+34) ($rightY+68) 705 ($rightHeight-88)
      $rightY += $rightHeight + 26
    }

    $revisionLabel = Get-LemConfigLabel $Config 'planRevision' 'Plan revision'
    Draw-LemSizedText $graphics "$revisionLabel`: $($Config.planRevisionId)" 18 'Regular' $muted 80 1402 2400 26

    $outputDirectory = Split-Path -Parent ([string]$Config.outPath)
    if (-not (Test-Path -LiteralPath $outputDirectory)) {
      throw "Wallpaper output directory does not exist: $outputDirectory"
    }
    $bitmap.Save([string]$Config.outPath, [System.Drawing.Imaging.ImageFormat]::Png)
  } finally {
    $graphics.Dispose()
    $bitmap.Dispose()
  }
  Write-Output "saved: $($Config.outPath)"
}

Export-ModuleMember -Function Invoke-LifeEnergyWallpaperRender
