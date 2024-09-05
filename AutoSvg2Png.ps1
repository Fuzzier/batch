# Define the mutex name
$mutexName = "Global\AutoSvg2Png.Mutex"

# Create or open the mutex
$global:mutex = New-Object -TypeName System.Threading.Mutex($false, $mutexName)

$global:lastPath = ''
$global:lastTime = Get-Date

# Inkscape
function GetInkscape()
{
    $cmd = 'inkscape.exe'
    $exist = Get-Command $cmd -ErrorAction SilentlyContinue
    if (-not $exist)
    {
        $cmd = "$env:ProgramFiles\inkscape\bin\inkscape.exe"
        $exist = Test-Path -Path $cmd
    }
    if (-not $exist)
    {
        $cmd = "$env:ProgramFiles(x86)\inkscape\bin\inkscape.exe"
        $exist = Test-Path -Path $cmd
    }
    if (-not $exist)
    {
        $cmd = $null
        Write-Host "Error: inkscape not found"
    }
    return $cmd
}

function DoConvert()
{
    param
    (
        [string]$Cmd,
        [string]$Path
    )

    try
    {
        # Wait to acquire the mutex
        $acquired = $global:mutex.WaitOne()

        if ($acquired)
        {
            $samePath = $global:lastPath -eq $Path
            $currTime = Get-Date
            if ($samePath)
            {
                $timeDiff = New-TimeSpan -Start $global:lastTime -End $currTime
                $seconds = $timeDiff.TotalSeconds
                $sameTime = $seconds -le 5
                if ($sameTime)
                {
                    return
                }
            }

            # Run the processing script and pass the new file as an argument
            $outputPath = [System.IO.Path]::ChangeExtension($Path, 'png')
            & $Cmd --export-type=png --export-dpi=300 --export-filename=$outputPath $Path

            Sleep -Seconds 1
            $trials = 1
            while ((-not (Test-Path -Path $outputPath)) -and ($trials -le 3))
            {
                Sleep -Seconds 1
                $trials += 1
            }
            Set-Clipboard -Path $outputPath
            $time = [string]::Format("{0:hh:mm:ss}", $(Get-Date))
            Write-Host "[$time] File copied: $outputPath"

            $global:lastPath = $Path
            $global:lastTime = Get-Date
        }
    }
    finally
    {
        if ($acquired)
        {
            # Release the mutex
            $global:mutex.ReleaseMutex()
        }
    }
}

function DoWatch()
{
    param
    (
        [string]$Cmd,
        [string]$Folder
    )

    # Define the folder to watch
    $folderToWatch = $Folder

    # Create a FileSystemWatcher object
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $folderToWatch
    $watcher.Filter = "*.svg"  # Monitor svg file types
    $watcher.EnableRaisingEvents = $true
    # Monitor for creation and changes
    $watcher.NotifyFilter = [System.IO.NotifyFilters]'FileName, LastWrite'

    # Define the action to take when a file is created
    $onCreatedAction = {
        param ($source, $eventArgs)
    
        # Get the full path of the new file
        $path = $eventArgs.FullPath

        # Log the file creation detection (optional)
        Write-Output "File created: $path"
        DoConvert -Cmd $cmd -Path $path
    }

    # Define the action to take when a file is changed
    $onChangedAction = {
        param ($source, $eventArgs)
    
        # Get the full path of the changed file
        $path = $eventArgs.FullPath

        # Log the file change detection (optional)
        Write-Output "File changed: $path"
        DoConvert -Cmd $cmd -Path $path
    }

    # Register the event handler for the 'Created' event
    Register-ObjectEvent $watcher Created -Action $onCreatedAction

    # Register the event handler for the 'Changed' event
    Register-ObjectEvent $watcher Changed -Action $onChangedAction

    # Keep the script running to monitor the folder
    Write-Output "Monitoring folder: $folderToWatch"

    while ($true) { Start-Sleep 1 }
}

try
{
    $cmd = GetInkscape
    if ($cmd)
    {
        DoWatch -Cmd $cmd -Folder 'Z:\'
    }
}
finally
{
    # Dispose of the mutex object
    $global:mutex.Dispose()
}