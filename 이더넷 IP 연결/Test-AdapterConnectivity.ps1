function Test-AdapterConnectivity {
    param (
        [Parameter(Mandatory=$true)]
        [string]$LocalIP,
        [string]$Target = "8.8.8.8",
        [int]$Port = 53,
        [int]$Timeout = 20000
    )
    try {
        $localIPObj = [System.Net.IPAddress]::Parse($LocalIP)
        $localEndPoint = New-Object System.Net.IPEndPoint($localIPObj, 0)
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Client.Bind($localEndPoint)
        $asyncResult = $tcpClient.BeginConnect($Target, $Port, $null, $null)
        $success = $asyncResult.AsyncWaitHandle.WaitOne($Timeout)
        if ($success -and $tcpClient.Connected) {
            return $true
        } else {
            return $false
        }
    }
    catch {
        return $false
    }
    finally {
        if ($tcpClient) {
            $tcpClient.Close()
        }
    }
}

# 어댑터의 유효 IP(169.254 제외) 선택
$adapterName = '이더넷 4'
$addrs = Get-NetIPAddress -InterfaceAlias $adapterName -AddressFamily IPv4 |
         Where-Object { $_.IPAddress -notmatch '^169\.254\.' }
if ($addrs) {
    $adapterIP = ($addrs | Select-Object -First 1).IPAddress
    $connectivity = Test-AdapterConnectivity -LocalIP $adapterIP
    Write-Host "[TCP 연결 테스트] 어댑터($adapterIP)로 외부 연결 성공: $connectivity" -ForegroundColor Cyan
} else {
    Write-Host "유효한 어댑터 IP가 없습니다." -ForegroundColor Yellow
}
