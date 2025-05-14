param (
    [string]$Path,
    [switch]$NoPause
)

function IterateSubFolders()
{
    param
    (
        # A single path, or an array of paths
        $Paths,
        # Return $True to visit subdirectories recursively
        $Callback
    )
    $ToVisit = @()
    foreach ($Path in $Paths)
    {
        # Skip junction (symbolic link of directory)
        $Item = Get-Item -Path $Path -Force
        if ($Item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)
        {
            # Convert `$item` to a `DirectoryInfo` object and retrieves it
            $ReparsePointType = [System.IO.DirectoryInfo]$Item | Get-Item
            if ($ReparsePointType.LinkType -eq "Junction")
            {
                continue
            }
        }
        $Children = Get-ChildItem -Path $Path -Directory -Force
        foreach ($Child in $Children)
        {
            $Fullpath = $Child.FullName
            # Return $True to visit subdirectories recursively
            $Retval = & $Callback -Path $Fullpath
            if ($Retval[-1])
            {
                $toVisit = $ToVisit + $Fullpath
            }
        }
    }
    $ToVisit
}

function IterateSubFoldersRecursively()
{
    param
    (
        # A single path, or an array of paths
        $Paths,
        # Return $True to visit subdirectories recursively
        $Callback
    )
    $ToVisit = $Paths
    do
    {
        $ToVisit = IterateSubFolders -Paths $ToVisit -Callback $Callback
    }
    while ($ToVisit)
}

function GitGc()
{
    param
    (
        [string] $Path
    )
    Write-Host '========================================'
    Write-Host $Path
    Write-Host '========================================'
    Set-Location -Path $Path
    git gc
    git prune
}

function TryGitRepo()
{
    param
    (
        [string] $Path
    )
    $IsGitRepo = (Test-Path -Path (Join-Path -Path $Path -ChildPath 'HEAD')) -and
                 (Test-Path -Path (Join-Path -Path $Path -ChildPath 'refs')) -and
                 (Test-Path -Path (Join-Path -Path $Path -ChildPath 'objects'))
    if ($IsGitRepo)
    {
        $ObjectsPath = Join-Path -Path $Path -ChildPath 'objects'
        # Get all subdirectories whose Name has two characters, other than 'info' and 'pack'
        $Subfolders = Get-ChildItem -Path $ObjectsPath -Directory -Name '??'
        if ($Subfolders)
        {
            $Retval = GitGc -Path $Path
            return $true
        }
    }
    return $false
}

function TryGitWorktree()
{
    param
    (
        [string] $Path
    )
    $Repo = Join-Path -Path $Path -ChildPath '.git'
    $IsGitWorktree = Test-Path -Path $Repo -PathType Container
    if ($IsGitWorktree)
    {
        return (TryGitRepo -Path $Repo)
    }
    return $false
}

$Callback = {
    param
    (
        [string] $Path
    )
    $Name = Split-Path -Path $Path -Leaf
    if ($Name -match 'qt.-build')
    {
        return $false
    }
    if ($Name -match '^\.(?!git$)')
    {
        return $false
    }
    if ($Name -cmatch '^(Misc|Swig|Lua|out|Asan|Debug|Release|RelWithDebInfo|OpRelease|OpDebug)$')
    {
        return $false
    }
    if ($Name -cmatch '^(qt.|icu|llvm-project|vim|neovim)$')
    {
        TryGitWorktree -Path $Path
        return $false
    }
    TryGitRepo -Path $Path
    return $true
}

if (-not $Path)
{
    $Path = $PWD
}
# Get all subdirectories under current directory
IterateSubFoldersRecursively -Paths $Path -Callback $Callback

if (-not $NoPause)
{
    Write-Host 'Done. Press any key to continue...' -NoNewline
    $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
}