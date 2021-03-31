# ===========================================================
# 20210316
# ===========================================================

# This script executes a queue of tasks in parallel.

param (
    [Parameter(HelpMessage='The maximum number of tasks in parallel.')]
    [ValidateRange(1, [int]::MaxValue)]
    [Alias('j')]
    [int]
    $jobs = 1,
    
    [Parameter(HelpMessage='Log the output of each task.')]
    [Alias('l')]
    [switch]
    $log = $false,
    
    [Parameter(HelpMessage='Keep the task console from being closed. This is for debugging purpose only.')]
    [Alias('k')]
    [switch]
    $keep = $false,

    [Parameter(Position=0, ValueFromRemainingArguments=$true,
               HelpMessage='The queue files where each line specifies a task.')]
    [string[]]
    $queues
)

class Task
{
    # The process information.
    [System.Diagnostics.Process]
    $proc

    # The cursor position.
    [System.Management.Automation.Host.Coordinates]
    $cpos

    Task([System.Diagnostics.Process] $proc,
         [System.Management.Automation.Host.Coordinates] $cpos)
    {
        $this.proc = $proc
        $this.cpos = $cpos
    }

    [string] GetElapsedTime()
    {
        $d = $null
        if (-not $this.proc.HasExited)
        {
            $now = Get-Date
            $d = $now - $this.proc.StartTime
        }
        else
        {
            $d = $this.proc.ExitTime - $this.proc.StartTime
        }
        $str = '*'
        if ($d.Days)
        {
            $str = '{0}.' -f $d.Days
        }
        $str += '{0:d2}:{1:d2}:{2:d2}' -f $d.Hours, $d.Minutes, $d.Seconds
        return $str
    }
}

function RunQueues([int] $jobs, [switch] $log, [switch] $keep, [string[]] $queues)
{
    # Load all tasks into a list.
    $cmdlines = New-Object System.Collections.Generic.Queue[string]
    foreach ($queue in $queues)
    {
        $content = Get-Content -LiteralPath $queue
        foreach ($line in $content)
        {
            # Skip the line that starts with semicolon ';'
            if ($line -match '^\s*;' -or $line -match '^\s*$')
            {
                continue
            }
            $cmdlines.Enqueue($line)
        }
    }
    Write-Host ('Total number of tasks: {0}' -f $cmdlines.Count)
    $width = [System.Math]::Ceiling([System.Math]::Log10($cmdlines.Count + 1))
    # Run tasks.
    $pool = New-Object System.Collections.Generic.List[Task]
    $index = 0
    while ($cmdlines.Count)
    {
        # Run tasks in parallel.
        while ($pool.Count -lt $jobs)
        {
            $index += 1
            $line = $cmdlines.Dequeue()
            Write-Host -NoNewline ('{0}. {1}  ' -f $index, $line)
            # Save the cursor position.
            $cpos = $Host.UI.RawUI.CursorPosition
            Write-Host ''
            if ($log)
            {
                $line = '{0} | Tee-Object -FilePath {1}.log' -f $line, $index
            }
            # 1. Change double quotes (") to the escaped form (\").
            #    `Start-Process` will pass each double quoted argument as a whole entity.
            #    However, it will remove the escaped double quotes.
            # 2. Add two additional escaped double quotes (\"\") for each escaped double quote.
            #    The additional two escaped double quotes will be substituted by one double quote.
            $line = $line -replace '"', '\"\"\"'
            $line = '-NoLogo -Command . ' + $line
            if ($keep)
            {
                $line = '-NoExit ' + $line
            }
            $proc = Start-Process -PassThru -FilePath 'powershell' -ArgumentList $line
            $task = [Task]::new($proc, $cpos)
            [void] $pool.Add($task)
        }
        # Wait for any process to stop.
        $cpos = $Host.UI.RawUI.CursorPosition
        while ($pool.Count -eq $jobs)
        {
            $i = 0
            while ($i -lt $pool.Count)
            {
                $task = $pool[$i]
                if ($task.proc.HasExited)
                {
                    $Host.UI.RawUI.CursorPosition = $task.cpos
                    Write-Host -NoNewline $task.GetElapsedTime()
                    $pool.RemoveAt($i)
                }
                else
                {
                    $Host.UI.RawUI.CursorPosition = $task.cpos
                    Write-Host -NoNewline -ForegroundColor Green $task.GetElapsedTime()
                    $i += 1
                }
            }
            # Wait for some time before test again.
            if ($pool.Count -eq $jobs)
            {
                Start-Sleep -Seconds 1
            }
        }
        $Host.UI.RawUI.CursorPosition = $cpos
    }
    # Wait for all process to stop.
    $cpos = $Host.UI.RawUI.CursorPosition
    while ($pool.Count)
    {
        $i = 0
        while ($i -lt $pool.Count)
        {
            $task = $pool[$i]
            if ($task.proc.HasExited)
            {
                $Host.UI.RawUI.CursorPosition = $task.cpos
                Write-Host -NoNewline $task.GetElapsedTime()
                $pool.RemoveAt($i)
            }
            else
            {
                $Host.UI.RawUI.CursorPosition = $task.cpos
                Write-Host -NoNewline -ForegroundColor Green $task.GetElapsedTime()
                $i += 1
            }
        }
        # Wait for some time before test again.
        if ($pool.Count)
        {
            Start-Sleep -Seconds 1
        }
    }
    $Host.UI.RawUI.CursorPosition = $cpos
}

$csize = $Host.UI.RawUI.CursorSize
$Host.UI.RawUI.CursorSize = 0
RunQueues -jobs $jobs -log:$log -keep:$keep -queues $queues
$Host.UI.RawUI.CursorSize = $csize
