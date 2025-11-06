function Process
{
    $keyPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers'
    $key = Get-Item -Path $keyPath
    $subkeys = Get-ChildItem -Path $keyPath
    $nameToNewName = @{}
    $newNameAlreadyExist = @{}
    foreach ($subkey in $subkeys)
    {
        $name = Split-Path -Path $subkey.Name -Leaf
        $rawName = $name.Trim()
        $level = 0
        switch -Wildcard ($rawName)
        {
            {$_ -cmatch '^Tortoise\d'}
            { $level = 5; break }
            {$_ -cmatch '^IconOverlay'}
            { $level = 4; break }
            {$_ -cmatch '^AccExtIco\d'}
            { $level = 3; break }
        }
        $newName = (' ' * $level) + $rawName
        $nameToNewName[$name] = $newName
        if (-not $newNameAlreadyExist.ContainsKey($newName) -or
            -not $newNameAlreadyExist[$newName])
        {
            # Set $newName existance flag
            $newNameAlreadyExist[$newName] = ($name -ceq $newName);
        }
    }
    foreach ($subkey in $subkeys)
    {
        $name = Split-Path -Path $subkey.Name -Leaf
        $newName = $nameToNewName[$name]
        # If $newName already exists
        if ($newNameAlreadyExist[$newName])
        {
            # Remove if it is a redundant name
            if ($name -cne $newName)
            {
                Remove-Item -Path "HKLM:$subkey"
            }
        }
        else
        {
            # Rename the first $name to $newName
            Rename-Item -Path "HKLM:$subkey" -NewName "$newName"
            # Will remove redundant names
            $newNameAlreadyExist[$newName] = true
       }
    }
}

function Pause($M="Press any key to continue . . . "){if($psISE){$S=New-Object -ComObject "WScript.Shell";$B=$S.Popup("Click OK to continue.",0,"Script Paused",0);return};Write-Host -NoNewline $M;$I=16,17,18,20,91,92,93,144,145,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183;while($K.VirtualKeyCode -Eq $Null -Or $I -Contains $K.VirtualKeyCode){$K=$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")};Write-Host}

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
    Process
    # Write-Host 'Press any key ...'; $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    Pause
}
else
{
    Start-Process -FilePath 'powershell' -Verb RunAs -ArgumentList '-File', """$PSCommandPath"""
}
