param (
    [string]$Path,
    [switch]$NoPause
)

function IterateSubFolders() {
    param (
        # A single path, or an array of paths
        $Paths,
        # Return $True to visit subdirectories recursively
        $Callback
    )
    $ToVisit = @()
    foreach ($Path in $Paths) {
        # Skip junction (symbolic link of directory)
        $Item = Get-Item -Path $Path -Force
        if ($Item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            # Convert `$item` to a `DirectoryInfo` object and retrieves it
            $ReparsePointType = [System.IO.DirectoryInfo]$Item | Get-Item
            if ($ReparsePointType.LinkType -eq "Junction") {
                continue
            }
        }
        $Children = Get-ChildItem -Path $Path -Directory -Force
        foreach ($Child in $Children) {
            $Fullpath = $Child.FullName
            # Return $True to visit subdirectories recursively
            $Retval = & $Callback -Path $Fullpath
            if ($Retval[-1]) {
                $toVisit = $ToVisit + $Fullpath
            }
        }
    }
    $ToVisit
}

function IterateSubFoldersRecursively() {
    param (
        # A single path, or an array of paths
        $Paths,
        # Return $True to visit subdirectories recursively
        $Callback
    )
    $ToVisit = $Paths
    do {
        $ToVisit = IterateSubFolders -Paths $ToVisit -Callback $Callback
    }
    while ($ToVisit)
}

function GitOwn() {
    param (
        [string] $Path
    )
    Write-Host $Path
    Set-Location -Path $Path
    takeown /f .
}

function TryGitRepo() {
    param (
        [string] $Path
    )
    $IsGitRepo = (Test-Path -Path (Join-Path -Path $Path -ChildPath 'HEAD')) -and
                 (Test-Path -Path (Join-Path -Path $Path -ChildPath 'refs')) -and
                 (Test-Path -Path (Join-Path -Path $Path -ChildPath 'objects'))
    if ($IsGitRepo) {
        $Retval = GitOwn -Path $Path
        return $true
    }
    return $false
}

function TryGitWorktree() {
    param (
        [string] $Path
    )
    $Repo = Join-Path -Path $Path -ChildPath '.git'
    $IsGitWorktree = Test-Path -Path $Repo -PathType Container
    if ($IsGitWorktree) {
        $Retval = TryGitRepo -Path $Repo
        if ($Retval) {
            $Retval = GitOwn -Path $Path
            return $true
        }
    }
    return $false
}

$CurrentPrincipal = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $Cmd = @("-NoProfile", "-Command", "Set-Location -LiteralPath `"$PWD`"; & `"$PSCommandPath`" $args")
    Start-Process "powershell" -Verb RunAs -ArgumentList $Cmd
    Exit
}

$Callback = {
    param (
        [string] $Path
    )
    $Name = Split-Path -Path $Path -Leaf
    # Build directories
    if ($Name -cmatch '^(out|Asan|Debug|Release|RelWithDebInfo|OpRelease|OpDebug)$') {
        return $false
    }
    if ($Name -match 'qt.-build') {
        return $false
    }
    # '.' not followed by 'git'
    if ($Name -match '^\.(?!git$)') {
        return $false
    }
    if (TryGitWorktree -Path $Path) {
        # For 'nsfx`, search child directories
        return ($Path -match 'nsfx')
    } elseif (TryGitRepo -Path $Path) {
        return $false
    }
    return $true
}

if (-not $Path) {
    $Path = $PWD
}

# Get all subdirectories under current directory
IterateSubFoldersRecursively -Paths $Path -Callback $Callback

if (-not $NoPause) {
	if($psISE){(New-Object -ComObject 'WScript.Shell').Popup('Click OK to continue...',0,'Script done',0)}else{Write-Host 'Done. Press any key to continue...' -NoNewline;$key=$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode}
}
