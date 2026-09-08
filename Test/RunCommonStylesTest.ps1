$ErrorActionPreference = 'Stop'
$gmRoot = Split-Path $PSScriptRoot -Parent
$gmOut = Join-Path $env:TEMP 'RmtGMUI-check'
New-Item -ItemType Directory -Force -Path $gmOut | Out-Null
$gmFramework = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319'
$gmReferences = @('/reference:System.dll', '/reference:System.Core.dll', '/reference:System.Xml.dll', '/reference:PresentationFramework.dll', '/reference:PresentationCore.dll', '/reference:WindowsBase.dll', '/reference:System.Xaml.dll')
$gmAhk = Join-Path $env:ProgramFiles 'AutoHotkey\v2\AutoHotkey64.exe'
& $gmAhk /ErrorStdOut (Join-Path $PSScriptRoot 'CommonStyleDialogsTest.ahk') | Out-Host
if ($LASTEXITCODE -ne 0) { throw 'GM-UI migrated dialog builder tests failed' }
& (Join-Path $gmFramework 'csc.exe') /nologo /target:exe "/out:$gmOut\CommonStylesTest.exe" "/lib:$gmFramework\WPF" @gmReferences (Join-Path $PSScriptRoot 'CommonStylesTest.cs') (Join-Path $gmRoot 'Plugins\AHK-XAML\lib\dep\src\CommonStyles.cs')
if ($LASTEXITCODE -ne 0) { throw 'GM-UI test compilation failed' }
& "$gmOut\CommonStylesTest.exe"
if ($LASTEXITCODE -ne 0) { throw 'GM-UI behavior tests failed' }
& "$gmOut\CommonStylesTest.exe" release
if ($LASTEXITCODE -ne 0) { throw 'GM-UI release guard failed' }
