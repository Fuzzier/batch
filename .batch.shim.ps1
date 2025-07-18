# Capture the path of the script itself
$Script:ThisScriptPath = $MyInvocation.MyCommand.Path
$Script:ThisScriptRoot = Split-Path -Parent $Script:ThisScriptPath

function Batch-Import-Module {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Module
    )

    $Path = Join-Path -Path $Script:ThisScriptRoot -ChildPath $Module

    if (-not (Test-Path $Path)) {
        throw "Module '$Path' does not exist"
    }

    $module = Import-Module $Path -Force
}
