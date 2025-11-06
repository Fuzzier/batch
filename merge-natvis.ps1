function WriteProlog
{
    param
    (
        [string] $Target
    )
    $date  = Get-Date
    $year  = '{0:D4}' -f $date.Year
    $month = '{0:D2}' -f $date.Month
    $day   = '{0:D2}' -f $date.Day
    Add-Content -Path $Target -Value '<?xml version="1.0" encoding="utf-8"?>'
    Add-Content -Path $Target -Value '<!--'
    Add-Content -Path $Target -Value '- @file'
    Add-Content -Path $Target -Value '-'
    Add-Content -Path $Target -Value '- @brief Visual studio visualizer files.'
    Add-Content -Path $Target -Value '-'
    Add-Content -Path $Target -Value '- @author  Wei Tang <gauchyler@uestc.edu.cn>'
    Add-Content -Path $Target -Value "- @date    $year-$month-$day"
    Add-Content -Path $Target -Value '-'
    Add-Content -Path $Target -Value "- @copyright Copyright (c) $year."
    Add-Content -Path $Target -Value '-            National Key Laboratory of Science and Technology on Communications,'
    Add-Content -Path $Target -Value '-            University of Electronic Science and Technology of China.'
    Add-Content -Path $Target -Value '-            All rights reserved.'
    Add-Content -Path $Target -Value '-->'
    Add-Content -Path $Target -Value '<AutoVisualizer xmlns="http://schemas.microsoft.com/vstudio/debugger/natvis/2010">'
}

function WriteEpilog
{
    param
    (
        [string] $Target
    )
    Add-Content -Path $Target -Value '</AutoVisualizer>'
}

function Merge
{
    param
    (
        [string] $Path,
        [string] $Target
    )
    $count = -1
    $content = ''
    foreach ($line in Get-Content -Path $Path)
    {
        if ($count -ge 0)
        {
            if ($line -match '</AutoVisualizer>')
            {
                break
            }
            if ($count -eq 0)
            {
                if ($line -match '<Type Name="nsfx::([0-9a-zA-Z:]+)')
                {
                    $type = $Matches[1]
                    $title = "<!-- {0} -->`n" -f $type
                    $content = $title + $content
                    $count = $count + 1
                }
            }
            $content += "{0}`n" -f $line
        }
        elseif ($line -match '<AutoVisualizer')
        {
            $count = 0
        }
    }
    Add-Content -Path $Target -Value $content -NoNewline
}

# 从当前目录出发, 找到'/nsfx/natvis'目录
$target = Join-Path -Path $PWD -ChildPath 'nsfx.natvis'
$natvis = Join-Path -Path $PWD -ChildPath 'nsfx/natvis'

$file = New-Item -Path $target -ItemType File -Force
WriteProlog -Target $target

$files = Get-ChildItem -Path $natvis
foreach ($file in $files)
{
    $file = Join-Path -Path $natvis -ChildPath $file
    Merge -Path $file -Target $target
}

WriteEpilog -Target $target
Write-Output (Get-Content -Path $target)
Write-Output ""

# 使用Unix换行, 可直接在Linux中使用
(Get-Content $target -Raw) -replace "`r`n", "`n" |
    Set-Content $target -Encoding utf8

function CopyNatvisTo()
{
    param
    (
        [string] $Path
    )
    Write-Output $Path
    Copy-Item -Path "nsfx.natvis"        -Destination $Path -Force
    Copy-Item -Path "nsfx.natstepfilter" -Destination $Path -Force
    Copy-Item -Path "std.natstepfilter"  -Destination $Path -Force
}

function InstallNatvis()
{
    # Visual Studio Visualizers
    # e.g., "Visual Studio 2022"
    $targets = Get-ChildItem "$env:USERPROFILE\Documents" -Directory -Filter "Visual Studio *"
    foreach ($dir in $targets)
    {
        $path = Join-Path -Path $dir.FullName -ChildPath "Visualizers"
        CopyNatvisTo -Path $path
    }
    # VSCode Visualizers
    # e.g., "ms-vscode.cpptools-1.23.6-win32-x64"
    $targets = Get-ChildItem "$env:USERPROFILE\.vscode\extensions" -Directory -Filter "ms-vscode.cpptools-*-win32-*"
    foreach ($dir in $targets)
    {
        $path = Join-Path -Path $dir.FullName -ChildPath "debugAdapters\vsdbg\bin\Visualizers"
        CopyNatvisTo -Path $path
    }
}

InstallNatvis

function Pause($M="Press any key to continue . . . "){if($psISE){$S=New-Object -ComObject "WScript.Shell";$B=$S.Popup("Click OK to continue.",0,"Script Paused",0);return};Write-Host -NoNewline $M;$I=16,17,18,20,91,92,93,144,145,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183;while($K.VirtualKeyCode -Eq $Null -Or $I -Contains $K.VirtualKeyCode){$K=$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")};Write-Host}
Pause
