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
                if ($line -match '<Type Name="nsfx::([0-9a-zA-Z]+)')
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
