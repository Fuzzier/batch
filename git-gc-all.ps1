param (
    [string]$Path,
    [switch]$NoPause
)

function IterateSubFolders() {
    param (
        # A single path, or an array of paths
        $Paths,
        # If $true is returned, then visit subdirectories recursively
        $VisitSubdirCb
    )
    $ToVisit = @()
    foreach ($Path in $Paths) {
        # Skip junction (symbolic link of directory)
        $Item = Get-Item -Path $Path -Force
        if ($Item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            # Convert `$item` to `DirectoryInfo` object and retrieves it
            $ReparsePointType = [System.IO.DirectoryInfo]$Item | Get-Item
            if ($ReparsePointType.LinkType -eq "Junction") {
                continue
            }
        }
        $Children = Get-ChildItem -Path $Path -Directory -Force
        foreach ($Child in $Children) {
            $FullPath = $Child.FullName
            # If $true is returned, then visit subdirectories recursively
            $VisitSubdir = & $VisitSubdirCb -Path $FullPath
            if ($VisitSubdir[-1]) {
                $ToVisit = $ToVisit + $FullPath
            }
        }
    }
    $ToVisit
}

function IterateSubFoldersRecursively() {
    param (
        # A single path, or an array of paths
        $Paths,
        # If $true is returned, then visit subdirectories recursively
        $VisitSubdirCb
    )
    $ToVisit = $Paths
    do {
        $ToVisit = IterateSubFolders -Paths $ToVisit -VisitSubdirCb $VisitSubdirCb
    } while ($ToVisit)
}

function GitGc() {
    param (
        [string]$Path
    )
    Write-Host '========================================'
    Write-Host $Path
    Write-Host '========================================'
    Set-Location -Path $Path
    git gc
    git prune
}

function TryGitRepo() {
    param (
        [string]$Path
    )
    $IsGitRepo = (Test-Path -Path (Join-Path -Path $Path -ChildPath 'HEAD')) -and
                 (Test-Path -Path (Join-Path -Path $Path -ChildPath 'refs')) -and
                 (Test-Path -Path (Join-Path -Path $Path -ChildPath 'objects'))
    if ($IsGitRepo) {
        $ObjectsPath = Join-Path -Path $Path -ChildPath 'objects'
        # If there are subdirectories whose name has two characters, do `git gc`
        $Subfolders = Get-ChildItem -Path $ObjectsPath -Directory -Name '??'
        if ($Subfolders) {
            $Retval = GitGc -Path $Path
            return $true
        }
    }
    return $false
}

function TryGitWorktree() {
    param (
        [string]$Path
    )
    $Repo = Join-Path -Path $Path -ChildPath '.git'
    $IsGitWorktree = Test-Path -Path $Repo -PathType Container
    if ($IsGitWorktree) {
        return (TryGitRepo -Path $Repo)
    }
    return $false
}

$VisitSubdirCb = {
    param (
        [string]$Path
    )
    $Name = Split-Path -Path $Path -Leaf
    if ($Name -match 'qt.-build') {
        return $false
    }
    if ($Name -match '^\.(?!git$)') {
        return $false
    }
    if ($Name -cmatch '^(Misc|Swig|Lua|out|Asan|Debug|Release|RelWithDebInfo|OpRelease|OpDebug)$') {
        return $false
    }
    if ($Name -cmatch '^(qt.|icu|llvm-project|vim|neovim)$') {
        TryGitWorktree -Path $Path
        return $false
    }
    TryGitRepo -Path $Path
    return $true
}

if (-not $Path) {
    $Path = $PWD
}
# Get all subdirectories under current directory
IterateSubFoldersRecursively -Paths $Path -VisitSubdirCb $VisitSubdirCb

if (-not $NoPause) {
	if($psISE){(New-Object -ComObject 'WScript.Shell').Popup('Click OK to continue...',0,'Script done',0)}else{Write-Host 'Done. Press any key to continue...' -NoNewline;$key=$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode}
}
