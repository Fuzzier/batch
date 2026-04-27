function Set-ProxyConfig {
    param(
        [string]$IP,
        [string]$Port,
        [bool]$Enable
    )

    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"

    # Defaults
    $defaultIP = "127.0.0.1"
    $defaultPort = "7890"
    $defaultEnable = $true

    # Read current IE/Windows settings
    $ie = Get-ItemProperty -Path $regPath

    # Default enable/disable value from IE setting
    if ($null -ne $ie.ProxyEnable) {
        $defaultEnable = ([int]$ie.ProxyEnable -ne 0)
    }

    # Read address from IE
    if ($ie.ProxyServer) {
        # Example formats:
        # 127.0.0.1:7890
        # https://127.0.0.1:7890
        # http=127.0.0.1:7890;https=127.0.0.1:7890;ftp=127.0.0.1:7890
        $proxy = $ie.ProxyServer
        # Split multiple entries (e.g. http=...;https=...)
        $entries = $proxy -split ';'
        foreach ($entry in $entries) {
            # Remove "http://" prefix
            $addr = $entry -replace '^[^:]+://',''
            # Remove "http=" prefix
            $addr = $addr -replace '^[^=]+=',''
            # Match ip:port
            if ($addr -match '^(.+):(\d+)$') {
                $defaultIP = $matches[1]
                $defaultPort = $matches[2]
                break
            }
        }
    }

    # Ask Enable if not provided
    if ($PSBoundParameters.ContainsKey('Enable') -eq $false) {
        $defaultEnableText = if ($defaultEnable) { "Y" } else { "N" }
        $inputEnable = Read-Host "Enable? Y/N [$defaultEnableText]"
        if ([string]::IsNullOrWhiteSpace($inputEnable)) {
            $Enable = $defaultEnable
        } else {
            $Enable = $inputEnable -match '^(y|yes|1|true)$'
        }
    }

    if (-not $Enable) {
        git config --global --unset http.proxy  2>$null
        git config --global --unset https.proxy 2>$null
        Set-ItemProperty -Path $regPath -Name ProxyEnable -Value 0
        Write-Host "Disabled."
        return
    }

    # Ask IP if not provided
    if (-not $IP) {
        $IP = if ([string]::IsNullOrWhiteSpace($inputIP)) { $defaultIP } else { $inputIP }
        $ip = Read-Host "IP [$defaultIP]"
        if ([string]::IsNullOrWhiteSpace($ip)) {
            $ip = $defaultIP
        }
    }

    # Ask Port if not provided
    if (-not $Port) {
        $inputPort = Read-Host "Port [$defaultPort]"
        $Port = if ([string]::IsNullOrWhiteSpace($inputPort)) { $defaultPort } else { $inputPort }
    }

    # Combine address
    $addr = "$ip`:$port"

    # Set Git proxy
    git config --global http.proxy  "http://$addr"
    git config --global https.proxy "http://$addr"

    Set-ItemProperty -Path $regPath -Name ProxyServer -Value "http://$addr"
    Set-ItemProperty -Path $regPath -Name ProxyEnable -Value 1

    Write-Host "Enabled: http://$addr"
}

Set-ProxyConfig

if($psISE){(New-Object -ComObject 'WScript.Shell').Popup('Click OK to continue...',0,'Script done',0)}else{Write-Host 'Done. Press any key to continue...' -NoNewline;$key=$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode}
