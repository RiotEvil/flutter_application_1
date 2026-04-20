param(
    [string]$InputDir = ".\play_assets\raw",
    [string]$OutputDir = ".\play_assets\ready",
    [string]$FeatureGraphicDir = ".\assets\images",
    [int]$ScreenshotWidth = 1080,
    [int]$ScreenshotHeight = 1920,
    [int]$FeatureGraphicWidth = 1024,
    [int]$FeatureGraphicHeight = 500,
    [double]$CropTopRatio = 0.03,
    [double]$CropBottomRatio = 0.05,
    [int]$FramePadding = 16
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ResolvedInputDir = Join-Path $ProjectRoot $InputDir
$ResolvedOutputDir = Join-Path $ProjectRoot $OutputDir
$ResolvedFeatureGraphicDir = Join-Path $ProjectRoot $FeatureGraphicDir
$PreferredScreenshotManifest = @(
    @{ Name = 'photo_5371034583257782334_y.jpg'; Slug = 'dashboard' },
    @{ Name = 'photo_5371034583257782342_y.jpg'; Slug = 'new-order' },
    @{ Name = 'photo_5371034583257782336_y.jpg'; Slug = 'clients' },
    @{ Name = 'photo_5371034583257782340_y.jpg'; Slug = 'calendar' },
    @{ Name = 'photo_5371034583257782338_y.jpg'; Slug = 'inventory' },
    @{ Name = 'photo_5371034583257782339_y.jpg'; Slug = 'settings' },
    @{ Name = 'photo_5371034583257782341_y.jpg'; Slug = 'plans-pro' },
    @{ Name = 'photo_5371034583257782335_y.jpg'; Slug = 'team-chat' }
)

function Get-ScaledSize {
    param(
        [double]$SourceWidth,
        [double]$SourceHeight,
        [double]$BoundsWidth,
        [double]$BoundsHeight,
        [ValidateSet('Contain', 'Cover')]
        [string]$Mode
    )

    if ($Mode -eq 'Cover') {
        $scale = [Math]::Max($BoundsWidth / $SourceWidth, $BoundsHeight / $SourceHeight)
    }
    else {
        $scale = [Math]::Min($BoundsWidth / $SourceWidth, $BoundsHeight / $SourceHeight)
    }

    return [PSCustomObject]@{
        Width = [int]([Math]::Round($SourceWidth * $scale))
        Height = [int]([Math]::Round($SourceHeight * $scale))
    }
}

function Initialize-Graphics {
    param([System.Drawing.Graphics]$Graphics)

    $Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $Graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $Graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $Graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
}

function Get-CroppedBitmap {
    param([System.Drawing.Image]$Image)

    $srcW = $Image.Width
    $srcH = $Image.Height

    $topPx = [int]([Math]::Round($srcH * $CropTopRatio))
    $bottomPx = [int]([Math]::Round($srcH * $CropBottomRatio))
    $cropH = $srcH - $topPx - $bottomPx

    if ($cropH -lt 100) {
        $topPx = 0
        $bottomPx = 0
        $cropH = $srcH
    }

    $cropRect = New-Object System.Drawing.Rectangle(0, $topPx, $srcW, $cropH)
    $srcBmp = New-Object System.Drawing.Bitmap $Image
    try {
        return $srcBmp.Clone($cropRect, $srcBmp.PixelFormat)
    }
    finally {
        $srcBmp.Dispose()
    }
}

function Save-Jpeg {
    param(
        [System.Drawing.Bitmap]$Bitmap,
        [string]$Path,
        [long]$Quality = 92
    )

    $jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
        Where-Object { $_.MimeType -eq 'image/jpeg' } |
        Select-Object -First 1

    $encoder = [System.Drawing.Imaging.Encoder]::Quality
    $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters 1
    $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter($encoder, $Quality)
    try {
        $Bitmap.Save($Path, $jpegCodec, $encoderParams)
    }
    finally {
        $encoderParams.Dispose()
    }
}

function Draw-ShowcaseCard {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.Bitmap]$Image,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [System.Drawing.Color]$Accent
    )

    $shadowBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(90, 0, 0, 0))
    $frameBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 18, 18, 22))
    $framePen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(220, 255, 255, 255), 1)
    $accentBrush = New-Object System.Drawing.SolidBrush $Accent
    try {
        $Graphics.FillRectangle($shadowBrush, $X + 8, $Y + 10, $Width, $Height)
        $Graphics.FillRectangle($frameBrush, $X, $Y, $Width, $Height)
        $Graphics.DrawRectangle($framePen, $X, $Y, $Width - 1, $Height - 1)
        $Graphics.FillRectangle($accentBrush, $X, $Y, 8, $Height)

        $screenX = $X + 12
        $screenY = $Y + 12
        $screenW = $Width - 24
        $screenH = $Height - 24
        $screenSize = Get-ScaledSize -SourceWidth $Image.Width -SourceHeight $Image.Height -BoundsWidth $screenW -BoundsHeight $screenH -Mode Contain
        $drawX = [int]($screenX + (($screenW - $screenSize.Width) / 2))
        $drawY = [int]($screenY + (($screenH - $screenSize.Height) / 2))
        $Graphics.DrawImage($Image, $drawX, $drawY, $screenSize.Width, $screenSize.Height)
    }
    finally {
        $shadowBrush.Dispose()
        $frameBrush.Dispose()
        $framePen.Dispose()
        $accentBrush.Dispose()
    }
}

function New-FeatureGraphic {
    param(
        [System.IO.FileInfo[]]$Files,
        [string]$OutputDir,
        [string]$AssetsDir
    )

    $logoPath = Join-Path $AssetsDir 'icon-play-512.png'
    if (-not (Test-Path $logoPath)) {
        throw "Logo not found: $logoPath"
    }

    $selectedFiles = $Files | Select-Object -First 3
    $croppedImages = New-Object System.Collections.Generic.List[System.Drawing.Bitmap]
    foreach ($selectedFile in $selectedFiles) {
        $image = [System.Drawing.Image]::FromFile($selectedFile.FullName)
        try {
            $croppedImages.Add((Get-CroppedBitmap -Image $image))
        }
        finally {
            $image.Dispose()
        }
    }

    $logo = [System.Drawing.Image]::FromFile($logoPath)
    $canvas = New-Object System.Drawing.Bitmap $FeatureGraphicWidth, $FeatureGraphicHeight
    $graphics = [System.Drawing.Graphics]::FromImage($canvas)
    try {
        Initialize-Graphics -Graphics $graphics

        $graphics.Clear([System.Drawing.Color]::FromArgb(11, 11, 14))

        $gradientRect = New-Object System.Drawing.Rectangle 0, 0, $FeatureGraphicWidth, $FeatureGraphicHeight
        $gradientBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            $gradientRect,
            [System.Drawing.Color]::FromArgb(255, 11, 11, 14),
            [System.Drawing.Color]::FromArgb(255, 28, 12, 12),
            15
        )
        $glowBrushLeft = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(55, 255, 76, 59))
        $glowBrushRight = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(35, 93, 124, 255))
        try {
            $graphics.FillRectangle($gradientBrush, $gradientRect)
            $graphics.FillEllipse($glowBrushLeft, -90, 260, 320, 220)
            $graphics.FillEllipse($glowBrushRight, 720, -80, 360, 240)
        }
        finally {
            $gradientBrush.Dispose()
            $glowBrushLeft.Dispose()
            $glowBrushRight.Dispose()
        }

        $background = $croppedImages[0]
        $backgroundSize = Get-ScaledSize -SourceWidth $background.Width -SourceHeight $background.Height -BoundsWidth 560 -BoundsHeight $FeatureGraphicHeight -Mode Cover
        $graphics.DrawImage($background, 464, 0, $backgroundSize.Width, $backgroundSize.Height)
        $overlayBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(185, 8, 8, 10))
        try {
            $graphics.FillRectangle($overlayBrush, 440, 0, 584, $FeatureGraphicHeight)
        }
        finally {
            $overlayBrush.Dispose()
        }

        $graphics.DrawImage($logo, 54, 54, 112, 112)

        $brandFont = New-Object System.Drawing.Font('Segoe UI', 34, [System.Drawing.FontStyle]::Bold)
        $headlineFont = New-Object System.Drawing.Font('Segoe UI', 19, [System.Drawing.FontStyle]::Bold)
        $tagFont = New-Object System.Drawing.Font('Segoe UI', 13, [System.Drawing.FontStyle]::Bold)
        $redBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 255, 72, 59))
        $whiteBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(245, 245, 245))
        $tagBackBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(70, 255, 72, 59))
        try {
            $graphics.DrawString('Detailing Pro', $brandFont, $redBrush, 52, 174)
            $graphics.DrawString('CRM and scheduling for detailing studios', $headlineFont, $whiteBrush, (New-Object System.Drawing.RectangleF(56, 238, 304, 62)))

            $graphics.FillRectangle($tagBackBrush, 58, 338, 124, 34)
            $graphics.FillRectangle($tagBackBrush, 192, 338, 108, 34)
            $graphics.FillRectangle($tagBackBrush, 310, 338, 124, 34)
            $graphics.DrawString('CLIENTS', $tagFont, $whiteBrush, 78, 345)
            $graphics.DrawString('ORDERS', $tagFont, $whiteBrush, 214, 345)
            $graphics.DrawString('TEAM CHAT', $tagFont, $whiteBrush, 328, 345)
        }
        finally {
            $brandFont.Dispose()
            $headlineFont.Dispose()
            $tagFont.Dispose()
            $redBrush.Dispose()
            $whiteBrush.Dispose()
            $tagBackBrush.Dispose()
        }

        Draw-ShowcaseCard -Graphics $graphics -Image $croppedImages[1] -X 580 -Y 138 -Width 138 -Height 258 -Accent ([System.Drawing.Color]::FromArgb(255, 93, 124, 255))
        Draw-ShowcaseCard -Graphics $graphics -Image $croppedImages[0] -X 708 -Y 84 -Width 154 -Height 300 -Accent ([System.Drawing.Color]::FromArgb(255, 255, 196, 70))
        Draw-ShowcaseCard -Graphics $graphics -Image $croppedImages[2] -X 852 -Y 126 -Width 138 -Height 258 -Accent ([System.Drawing.Color]::FromArgb(255, 112, 224, 108))

        $pngAssetPath = Join-Path $AssetsDir 'feature-graphic-1024x500.png'
        $jpgAssetPath = Join-Path $AssetsDir 'feature-graphic-1024x500.jpg'
        $pngReadyPath = Join-Path $OutputDir 'feature-graphic-1024x500.png'
        $jpgReadyPath = Join-Path $OutputDir 'feature-graphic-1024x500.jpg'

        $canvas.Save($pngAssetPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $canvas.Save($pngReadyPath, [System.Drawing.Imaging.ImageFormat]::Png)
        Save-Jpeg -Bitmap $canvas -Path $jpgAssetPath
        Save-Jpeg -Bitmap $canvas -Path $jpgReadyPath

        Write-Output "Saved: $pngAssetPath"
        Write-Output "Saved: $jpgAssetPath"
        Write-Output "Saved: $pngReadyPath"
        Write-Output "Saved: $jpgReadyPath"
    }
    finally {
        $graphics.Dispose()
        $canvas.Dispose()
        $logo.Dispose()
        foreach ($cropped in $croppedImages) {
            $cropped.Dispose()
        }
    }
}

function Get-PublicationScreenshotJobs {
    param([System.IO.FileInfo[]]$Files)

    $filesByName = @{}
    foreach ($file in $Files) {
        $filesByName[$file.Name] = $file
    }

    $jobs = New-Object System.Collections.Generic.List[psobject]
    foreach ($item in $PreferredScreenshotManifest) {
        if ($filesByName.ContainsKey($item.Name)) {
            $jobs.Add([PSCustomObject]@{
                File = $filesByName[$item.Name]
                Slug = $item.Slug
            })
        }
    }

    if ($jobs.Count -gt 0) {
        return $jobs
    }

    $index = 1
    foreach ($file in $Files | Sort-Object Name | Select-Object -First 8) {
        $jobs.Add([PSCustomObject]@{
            File = $file
            Slug = ('screen-{0:D2}' -f $index)
        })
        $index++
    }

    return $jobs
}

if (-not (Test-Path $ResolvedInputDir)) {
    throw "Input folder not found: $ResolvedInputDir"
}

New-Item -ItemType Directory -Path $ResolvedOutputDir -Force | Out-Null
New-Item -ItemType Directory -Path $ResolvedFeatureGraphicDir -Force | Out-Null

Get-ChildItem -Path $ResolvedOutputDir -File |
    Where-Object { $_.Name -like 'play-shot-*.png' -or $_.Name -like 'feature-graphic-1024x500.*' } |
    Remove-Item -Force

$files = Get-ChildItem -Path $ResolvedInputDir -File |
    Where-Object { $_.Extension.ToLowerInvariant() -in @('.png', '.jpg', '.jpeg') }
if (-not $files) {
    throw "No images found in $ResolvedInputDir"
}

$screenshotJobs = Get-PublicationScreenshotJobs -Files $files

$index = 1
foreach ($job in $screenshotJobs) {
    $img = [System.Drawing.Image]::FromFile($job.File.FullName)
    try {
        $cropped = Get-CroppedBitmap -Image $img

        $canvas = New-Object System.Drawing.Bitmap $ScreenshotWidth, $ScreenshotHeight
        $g = [System.Drawing.Graphics]::FromImage($canvas)
        try {
            Initialize-Graphics -Graphics $g
            $g.Clear([System.Drawing.Color]::FromArgb(14, 14, 18))

            $backgroundSize = Get-ScaledSize -SourceWidth $cropped.Width -SourceHeight $cropped.Height -BoundsWidth $ScreenshotWidth -BoundsHeight $ScreenshotHeight -Mode Cover
            $backgroundX = [int](($ScreenshotWidth - $backgroundSize.Width) / 2)
            $backgroundY = [int](($ScreenshotHeight - $backgroundSize.Height) / 2)
            $g.DrawImage($cropped, $backgroundX, $backgroundY, $backgroundSize.Width, $backgroundSize.Height)

            $dimBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(150, 8, 8, 10))
            try {
                $g.FillRectangle($dimBrush, 0, 0, $ScreenshotWidth, $ScreenshotHeight)
            }
            finally {
                $dimBrush.Dispose()
            }

            $contentBoundsWidth = $ScreenshotWidth - ($FramePadding * 2)
            $contentBoundsHeight = $ScreenshotHeight - ($FramePadding * 2)
            $contentSize = Get-ScaledSize -SourceWidth $cropped.Width -SourceHeight $cropped.Height -BoundsWidth $contentBoundsWidth -BoundsHeight $contentBoundsHeight -Mode Contain
            $x = [int](($ScreenshotWidth - $contentSize.Width) / 2)
            $y = [int](($ScreenshotHeight - $contentSize.Height) / 2)

            $shadowBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(90, 0, 0, 0))
            $framePen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(190, 255, 255, 255), 2)
            try {
                $g.FillRectangle($shadowBrush, $x + 6, $y + 8, $contentSize.Width, $contentSize.Height)
                $g.DrawImage($cropped, $x, $y, $contentSize.Width, $contentSize.Height)
                $g.DrawRectangle($framePen, $x, $y, $contentSize.Width - 1, $contentSize.Height - 1)
            }
            finally {
                $shadowBrush.Dispose()
                $framePen.Dispose()
            }

            $name = ("play-shot-{0:D2}-{1}.png" -f $index, $job.Slug)
            $outPath = Join-Path $ResolvedOutputDir $name
            $canvas.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
            Write-Output "Saved: $outPath"
            $index++
        }
        finally {
            $g.Dispose()
            $canvas.Dispose()
            $cropped.Dispose()
        }
    }
    finally {
        $img.Dispose()
    }
}

if ($screenshotJobs.Count -ge 3) {
    $featureFiles = @(
        ($screenshotJobs | Where-Object { $_.Slug -eq 'dashboard' } | Select-Object -First 1).File,
        ($screenshotJobs | Where-Object { $_.Slug -eq 'new-order' } | Select-Object -First 1).File,
        ($screenshotJobs | Where-Object { $_.Slug -eq 'clients' } | Select-Object -First 1).File
    ) | Where-Object { $null -ne $_ }

    if ($featureFiles.Count -lt 3) {
        $featureFiles = $screenshotJobs | Select-Object -First 3 | ForEach-Object { $_.File }
    }

    New-FeatureGraphic -Files $featureFiles -OutputDir $ResolvedOutputDir -AssetsDir $ResolvedFeatureGraphicDir
}
else {
    New-FeatureGraphic -Files ($files | Sort-Object Name | Select-Object -First 3) -OutputDir $ResolvedOutputDir -AssetsDir $ResolvedFeatureGraphicDir
}

Write-Output "Done. Generated $($index - 1) screenshots in $ResolvedOutputDir"
