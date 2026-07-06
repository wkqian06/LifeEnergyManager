# LifeEnergyManager wallpaper generator (Windows PowerShell 5.1+, System.Drawing)
#
# Renders the 2560x1440 daily-plan PNG per templates/wallpaper_spec.md from a JSON config.
# Validated end-to-end in the 2026-07 Claude Code reliability test (test/RELIABILITY_REPORT.md):
# includes adaptive compact card layout (columns never overflow the canvas) and
# truncation-safe header chips.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File templates\wallpaper_generator.ps1 -ConfigPath <config.json>
#
# Config JSON schema (all text fields plain strings; colors one of orange|blue|green|gray):
# {
#   "date": "YYYY-MM-DD",
#   "subtitle": "Phase ... | Week of ... | <mode> mode",
#   "focusType": "Deep research / analysis",       // today's overall task focus type
#   "focusColor": "green",                          // its task-category color
#   "timeMix": "3 H Baseline + 2 H Stretch",
#   "baselineTitle": "Baseline 3h",                 // optional; can shrink for manual catch-up
#   "stretchTitle": "Later 2h stretch",             // optional; can become "No stretch"
#   "progress": [ { "label": "...", "value": "3/28", "percent": 11, "note": "..." }, x4 ],
#   "baseline": [ { "title": "...", "minutes": 60, "desc": "...", "color": "orange" }, ... ],
#   "stretch":  [ { ...same shape... } ],
#   "urgent":   [ { ...same shape... } ],           // optional; rendered after stretch cards
#   "status": "...", "advice": "...", "tip": "...", // wallpaper-short readable variants; exactly the three right-column blocks
#   "outPath": "<absolute path>\\outputs\\daily-wallpapers\\YYYY-MM-DD-daily-plan.png"
# }
#
# QA per templates/wallpaper_spec.md still applies after generation (artifact-qa subagent
# or the artifact QA skill): check readability, truncation, overlap, legend, and
# right-column blocks. If text does not fit, reduce detail instead of using
# cryptic wording.

param([Parameter(Mandatory=$true)][string]$ConfigPath)

Add-Type -AssemblyName System.Drawing
$cfg = Get-Content $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json

$W = 2560; $H = 1440
$bmp = New-Object System.Drawing.Bitmap($W, $H)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

function C([string]$hex) { [System.Drawing.ColorTranslator]::FromHtml($hex) }
$colBg     = C '#f4f6fa'; $colPanel = C '#ffffff'; $colInk = C '#172033'
$colMuted  = C '#526075'; $colLine  = C '#d6deea'; $colBar = C '#7c8db0'
$cat = @{ orange = C '#cc7000'; blue = C '#2563eb'; green = C '#008057'; gray = C '#64748b' }
$catSoft = @{ orange = C '#fff5e6'; blue = C '#edf4ff'; green = C '#eaf8f1'; gray = C '#f1f5f9' }

$g.Clear($colBg)

function F([single]$size, [string]$style='Regular') { New-Object System.Drawing.Font('Segoe UI', $size, [System.Drawing.FontStyle]::$style, [System.Drawing.GraphicsUnit]::Pixel) }
function Brush($c) { New-Object System.Drawing.SolidBrush($c) }
function CfgText([string]$name, [string]$fallback) {
  if (($cfg.PSObject.Properties.Name -contains $name) -and $cfg.$name) { return [string]$cfg.$name }
  return $fallback
}
function DrawText([string]$text, $font, $c, [single]$x, [single]$y, [single]$w, [single]$h) {
  $rect = New-Object System.Drawing.RectangleF($x, $y, $w, $h)
  $fmt = New-Object System.Drawing.StringFormat
  $fmt.Trimming = [System.Drawing.StringTrimming]::Word
  $g.DrawString($text, $font, (Brush $c), $rect, $fmt)
}
function Panel([single]$x, [single]$y, [single]$w, [single]$h, $fill) {
  $g.FillRectangle((Brush $fill), $x, $y, $w, $h)
  $pen = New-Object System.Drawing.Pen($colLine, 2)
  $g.DrawRectangle($pen, $x, $y, $w, $h)
}

# ---------- Header band ----------
DrawText "Daily Plan - $($cfg.date)" (F 72 'Bold') $colInk 80 55 1500 90
DrawText $cfg.subtitle (F 32) $colMuted 80 160 1500 46

# Top-right summary: task focus (category colored) + time mix. 26px bold wraps inside
# the chip instead of clipping (spec: no truncated text in the top-right summary).
$fx = 1660; $fy = 55; $fw = 400; $fh = 110
Panel $fx $fy $fw $fh $catSoft[$cfg.focusColor]
$g.FillRectangle((Brush $cat[$cfg.focusColor]), $fx, $fy, 12, $fh)
DrawText 'TASK FOCUS' (F 22 'Bold') $colMuted ($fx+30) ($fy+14) ($fw-40) 28
DrawText $cfg.focusType (F 26 'Bold') $cat[$cfg.focusColor] ($fx+30) ($fy+50) ($fw-36) 54
$tx = $fx + $fw + 20
Panel $tx $fy $fw $fh $colPanel
$g.FillRectangle((Brush $cat['gray']), $tx, $fy, 12, $fh)
DrawText 'TIME MIX' (F 22 'Bold') $colMuted ($tx+30) ($fy+14) ($fw-40) 28
DrawText $cfg.timeMix (F 26 'Bold') $colInk ($tx+30) ($fy+50) ($fw-36) 54

# Stable task-category color legend (wording matches templates/artifact_spec.md)
$legend = @(
  @{ k='orange'; t='Orange = urgent / external / deadline' },
  @{ k='blue';   t='Blue = deliverable / closure / visible output' },
  @{ k='green';  t='Green = deep research / analysis / implementation' },
  @{ k='gray';   t='Gray = planning / log / admin / stop' })
$lx = 80
foreach ($item in $legend) {
  $g.FillEllipse((Brush $cat[$item.k]), $lx, 232, 22, 22)
  DrawText $item.t (F 22) $colMuted ($lx+32) 231 575 34
  $lx += 620
}

# ---------- Progress row (neutral gray-blue bars per spec) ----------
$py = 300; $pw = 580; $ph = 140; $gap = 27
for ($i = 0; $i -lt $cfg.progress.Count; $i++) {
  $p = $cfg.progress[$i]
  $px = 80 + $i * ($pw + $gap)
  Panel $px $py $pw $ph $colPanel
  DrawText $p.label (F 26 'Bold') $colInk ($px+20) ($py+14) ($pw-160) 36
  DrawText $p.value (F 26 'Bold') $colMuted ($px+$pw-150) ($py+14) 135 36
  $g.FillRectangle((Brush $colLine), ($px+20), ($py+62), ($pw-40), 16)
  $fillw = [Math]::Max(6, ($pw-40) * [Math]::Min(100, [double]$p.percent) / 100)
  $g.FillRectangle((Brush $colBar), ($px+20), ($py+62), $fillw, 16)
  DrawText $p.note (F 22) $colMuted ($px+20) ($py+90) ($pw-40) 40
}

# ---------- Main board: Baseline | Stretch | Status and advice ----------
$by = 490; $bw = 773; $bgap = 40
$bx = @(80, (80 + $bw + $bgap), (80 + 2*($bw + $bgap)))
$titles = @((CfgText 'baselineTitle' 'Baseline 3h'), (CfgText 'stretchTitle' 'Later 2h stretch'), 'Status and advice')
for ($i = 0; $i -lt 3; $i++) {
  DrawText $titles[$i] (F 40 'Bold') $colInk $bx[$i] $by $bw 54
}
$cy0 = $by + 70

function TaskCard([single]$x, [ref]$yRef, $task, [single]$hh) {
  $y = $yRef.Value
  Panel $x $y 773 $hh $colPanel
  $g.FillRectangle((Brush $cat[$task.color]), $x, $y, 12, $hh)
  $compact = $hh -lt 168
  $titleFontSize = if ($compact) { 25 } else { 30 }
  $titleH = if ($compact) { 70 } else { 84 }
  DrawText $task.title (F $titleFontSize 'Bold') $colInk ($x+34) ($y+14) 660 $titleH
  DrawText ("$($task.minutes) min") (F 26 'Bold') $cat[$task.color] ($x+660) ($y+16) 100 36
  $descFontSize = if ($compact) { 22 } else { 24 }
  DrawText $task.desc (F $descFontSize) $colMuted ($x+34) ($y+$titleH+16) 705 ($hh-$titleH-26)
  $yRef.Value = $y + $hh + 20
}

# Card height adapts to task count so columns never overflow the 1440px canvas.
function ColumnCardHeight([int]$count) {
  if ($count -le 0) { return 168 }
  $avail = 1400 - $cy0
  [Math]::Min(168, [Math]::Floor($avail / $count) - 20)
}

$bh1 = ColumnCardHeight $cfg.baseline.Count
$stretchCount = $cfg.stretch.Count; if ($cfg.urgent) { $stretchCount += $cfg.urgent.Count }
$bh2 = ColumnCardHeight $stretchCount
$y1 = $cy0; foreach ($t in $cfg.baseline) { TaskCard $bx[0] ([ref]$y1) $t $bh1 }
$y2 = $cy0; foreach ($t in $cfg.stretch)  { TaskCard $bx[1] ([ref]$y2) $t $bh2 }
if ($cfg.urgent -and $cfg.urgent.Count -gt 0) { foreach ($t in $cfg.urgent) { TaskCard $bx[1] ([ref]$y2) $t $bh2 } }

# Right column: exactly the three approved reminder blocks (spec content rule)
$blocks = @(
  @{ h='Status summary'; t=$cfg.status },
  @{ h='Today advice'; t=$cfg.advice },
  @{ h='Anti-distraction tip'; t=$cfg.tip })
$y3 = $cy0
foreach ($b in $blocks) {
  $hh = 250
  Panel $bx[2] $y3 773 $hh $colPanel
  $g.FillRectangle((Brush $cat['gray']), $bx[2], $y3, 12, $hh)
  DrawText $b.h (F 28 'Bold') $colMuted ($bx[2]+34) ($y3+20) 705 38
  DrawText $b.t (F 30) $colInk ($bx[2]+34) ($y3+68) 705 160
  $y3 += $hh + 26
}

$g.Dispose()
$bmp.Save($cfg.outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Output "saved: $($cfg.outPath)"
