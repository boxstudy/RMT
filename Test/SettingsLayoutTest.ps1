param([switch]$Render)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$source = Get-Content (Join-Path $repo 'Main/MainWindowXaml.ahk') -Raw -Encoding UTF8
$start = $source.IndexOf('    BuildSettingTab()')
$end = $source.IndexOf('        this._Bind("EditHoldFloat"', $start)
$builder = $source.Substring($start, $end - $start) + "    }"
$fields = [regex]::Matches($builder, 'MainSoftData\.(\w+)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique | Where-Object { $_ -ne 'HasProp' }
$defaults = ($fields | ForEach-Object { "MainSoftData.$_ := 1" }) -join "`n"
$fixture = (Get-Content (Join-Path $PSScriptRoot 'SettingsLayoutFixture.ahk') -Raw -Encoding UTF8).Replace('; @FIELDS@', $defaults).Replace('; @BUILD@', $builder)
$testDir = Join-Path $env:TEMP ('RmtSettings-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory $testDir | Out-Null
$fixturePath = Join-Path $testDir 'build.ahk'
[IO.File]::WriteAllText($fixturePath, $fixture, [Text.UTF8Encoding]::new($true))
$xamlPath = Join-Path $testDir 'settings.xaml'
& 'C:/Program Files/AutoHotkey/v2/AutoHotkey64.exe' /ErrorStdOut $fixturePath $xamlPath | Out-Host
if ($LASTEXITCODE -ne 0) { throw 'AHK builder failed' }
Add-Type -AssemblyName PresentationFramework
$xaml = Get-Content $xamlPath -Raw -Encoding UTF8
$xml = [xml]$xaml
$duplicate = $xml.SelectNodes('//*[@Name]') | ForEach-Object { $_.GetAttribute('Name') } | Group-Object | Where-Object Count -gt 1
if ($duplicate) { throw "Duplicate controls: $($duplicate.Name)" }
$root = [Windows.Markup.XamlReader]::Parse($xaml)
$brushes = @{
    BgColor='#FFFFFDF4'; ControlBg='#FFFFFAF0'; InputBg='#FFFFFFFF'; InputText='#FF77542E'
    TextMain='#FF51331F'; TextSub='#FF90745B'; ControlBorder='#FFF3D69A'; InputStroke='#FFE9B05A'
    OutlineStroke='#FFE9B05A'; Accent='#FFEC8D00'; TitleBarColor='#FFFFF3D5'
    ListAltBg='#FFFFF8E5'; EditHoverBg='#FFFFF0CC'; ActionBg='#FFEC8D00'
}
foreach ($key in $brushes.Keys) { $root.Resources[$key] = [Windows.Media.BrushConverter]::new().ConvertFromString($brushes[$key]) }
$root.SetValue([Windows.Documents.TextElement]::FontFamilyProperty, [Windows.Media.FontFamily]::new('Microsoft YaHei UI'))
$root.SetValue([Windows.Documents.TextElement]::ForegroundProperty, $root.Resources['TextMain'])
$pages = 'behavior','macro','record','trigger','hotkey','appearance','ai','diagnostic'
$expected = @{
    behavior=@('ChkBootStart','CmbLang','CmbScreenShot','ChkForeground','TabVisible_Normal','CmbJoyType')
    macro=@('EditHoldFloat','CmbKeyDownDown','CmbRemarkAuto','ChkNoVariable')
    record=@('ShowBorderCon','MouseTrailModeCon','KeyboardTogCon','JoyTogCon')
    trigger=@('WheelScaleCon','UIPanelBtnWidthCon')
    hotkey=@('Val_SuspendHotkey','Val_DebugStepHotkey')
    appearance=@('ThemePresetCon','CmbFont','PaletteText_14')
    ai=@('AiApiKeyCon','AiModelCon','AiAccessCon')
    diagnostic=@('ChkCMDTip','CmdTipLogPathCon','BtnCmdTipBrowse','ChkBusinessLog')
}
foreach ($page in $pages) {
    foreach ($name in $expected[$page]) {
        if (-not $xml.SelectSingleNode("//*[@Name='SetPage_$page']//*[@Name='$name']")) { throw "$name not in $page" }
    }
}
if ($root.FindName('AiApiKeyCon') -isnot [Windows.Controls.PasswordBox]) { throw 'API key not masked' }
if ($Render) {
    $renderDir = Join-Path $repo 'Web/SettingsLayoutResult'
    New-Item -ItemType Directory -Force $renderDir | Out-Null
}
foreach ($width in 940,1320) {
    foreach ($page in $pages) {
        foreach ($pgId in $pages) { $root.FindName("SetPage_$pgId").Visibility = if ($pgId -eq $page) { 'Visible' } else { 'Collapsed' } }
        $root.Measure([Windows.Size]::new($width,1200))
        $root.Arrange([Windows.Rect]::new(0,0,$width,1200))
        $root.UpdateLayout()
        foreach ($name in $expected[$page]) {
            $control = $root.FindName($name)
            if ($control.ActualWidth -le 0) { throw "$name has no width at $width" }
        }
        if ($page -eq 'diagnostic' -and $width -eq 1320 -and $root.FindName('CmdTipLogPathCon').ActualWidth -le 76) { throw 'Log path not wider than browse button' }
        if ($Render -and $width -eq 1320) {
            $bitmap = [Windows.Media.Imaging.RenderTargetBitmap]::new($width,1200,96,96,[Windows.Media.PixelFormats]::Pbgra32)
            $bitmap.Render($root)
            $encoder = [Windows.Media.Imaging.PngBitmapEncoder]::new()
            $encoder.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($bitmap))
            $stream = [IO.File]::Create((Join-Path $renderDir "$page.png"))
            try { $encoder.Save($stream) } finally { $stream.Dispose() }
        }
    }
}
'PASS: actual AHK builder, WPF load, eight page mappings, unique names, password masking and 940/1320 layout.'
