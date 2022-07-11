##
# @file
# 
# @brief Add to PATH environment variable.
# 
# @version 1.0
# @author  Wei Tang <gauchyler@uestc.edu.cn>
# @date    2021-03-13
# 
# @copyright Copyright (c) 2021.
#   National Key Laboratory of Science and Technology on Communications,
#   University of Electronic Science and Technology of China.
#   All rights reserved.

param(
    [switch] $sys = $false,
	[Parameter(Position=0, ValueFromRemainingArguments=$true)] $args
)

# By default, add current directory to `PATH`.
If ($args -eq $null)
{
    $args = @("$(Get-Location)")
}

##
# @param[in] $path The string value of `PATH` environment variable.
# @param[in] $coll The array of paths to be added.
function AppendPaths([string] $path, $coll)
{
    $paths = $path -split ';'
    $result = @()
    ForEach($dir In $paths)
    {
        If ($dir -ne "")
        {
            $result = $result + $dir
        }
    }
    ForEach($dir In $coll)
    {
        # Prevent duplication.
        If ($result -notcontains $dir)
        {
            $result = $result + $dir
        }
    }
    Return $result -join ';'
}

function DoWork([switch] $sys = $false)
{
	$coll = @()
	ForEach($arg In $args)
	{
		If ([System.IO.Directory]::Exists($arg))
		{
			$coll = $coll + $arg
		}
		Else
		{
			Write-Host "The directory '$arg' does not exist."
		}
	}
	If ($coll)
	{
		If ($sys)
		{
			$path = [System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::Machine)
            $path = AppendPaths -path $path -coll $coll
			Write-Host $path
			[System.Environment]::SetEnvironmentVariable('PATH', $path, [System.EnvironmentVariableTarget]::Machine)
		}
		Else
		{
			$path = [System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::User)
            $path = AppendPaths -path $path -coll $coll
			Write-Host $path
			[System.Environment]::SetEnvironmentVariable('PATH', $path, [System.EnvironmentVariableTarget]::User)
		}
	}
}

If ($sys)
{
	$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
	if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
	{
		DoWork -sys @args
		# Write-Host "Press any key ..."; $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	}
	else
	{
        $argList = "-File $PSCommandPath -sys"
        Foreach ($arg In $args)
        {
            $argList += ' "' + $arg + '"'
        }
		Start-Process -FilePath "powershell" -Verb RunAs -ArgumentList $argList
	}
}
Else
{
	DoWork @args
}
