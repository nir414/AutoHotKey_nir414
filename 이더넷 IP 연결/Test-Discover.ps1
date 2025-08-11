<#
Standalone test script for UDP broadcast device discovery
#>
try {
    $BROADCAST_IP = "255.255.255.255"
    $PORT = 51417
    $message = [byte[]](0, 0, 255, 255, 0, 0, 0, 12, 0, 101, 0, 0)
    $TIMEOUT_MS = 2000    # 전체 대기 시간(ms)
    $PER_RECEIVE_TIMEOUT_MS = 200   # 개별 Receive 타임아웃(ms)
    $SEND_COUNT = 3       # 브로드캐스트 반복 전송 횟수 (증가)
    $SEND_INTERVAL_MS = [Math]::Floor($TIMEOUT_MS / $SEND_COUNT)  # 전송 간격
    $BYTE_DELAY_MS = 50   # 바이트별 전송 딜레이(ms)

    Write-Host "[테스트시작] UDP 브로드캐스트 전송 및 응답 확인" -ForegroundColor Cyan

    $udpClient = New-Object System.Net.Sockets.UdpClient
    # 포트 재사용을 허용하여 반복 실행 시 바인딩 충돌 방지
    $udpClient.Client.SetSocketOption(
        [System.Net.Sockets.SocketOptionLevel]::Socket,
        [System.Net.Sockets.SocketOptionName]::ReuseAddress,
        $true
    )
    $udpClient.EnableBroadcast = $true

    # 로컬 포트 바인딩 및 타임아웃 설정
    $localEP = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, $PORT)
    $udpClient.Client.Bind($localEP)
    $udpClient.Client.ReceiveTimeout = $PER_RECEIVE_TIMEOUT_MS
    # 브로드캐스트 전송 및 응답 수신을 하나의 루프에서 처리 (1초 내 탐지 보장)
    $remoteEP = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Parse($BROADCAST_IP), $PORT)
    # 메시지를 바이트 단위로 분할하여 개별 전송
    $startTime = Get-Date
    $found = @()
    $sentCount = 0
    $nextSendTime = $startTime
    while ((Get-Date) - $startTime -lt [TimeSpan]::FromMilliseconds($TIMEOUT_MS)) {
        $now = Get-Date
        # 브로드캐스트 반복 전송
        if ($sentCount -lt $SEND_COUNT -and $now -ge $nextSendTime) {
            # 현재 전송 회차 표시
            Write-Host "[전송] $($sentCount + 1)/$SEND_COUNT" -ForegroundColor Green
            # 바이트별 전송 및 % 게이지 표시
            for ($i = 0; $i -lt $message.Length; $i++) {
                $b = $message[$i]
                $udpClient.Send([byte[]]($b), 1, $remoteEP) | Out-Null
                # 진행률 계산 및 Write-Progress로 애니메이션
                $percent = [Math]::Floor((($i + 1) / $message.Length) * 100)
                # 진행률 표시: 10% 단위로만 갱신
                if ($percent % 10 -eq 0) {
                    $blocks = [Math]::Floor($percent / 10)
                    $gauge = ('#' * $blocks) + ('-' * (10 - $blocks))
                    # 한 줄에 덮어쓰기
                    Write-Host -NoNewline "`r[전송 게이지] [$gauge] $percent%"
                }
                Start-Sleep -Milliseconds $BYTE_DELAY_MS
            }
            # 최종 요약 표시 (덮어쓰기 없이, 한 줄 띄우기)
            Write-Host ""  # 게이지 후 줄 바꿈
            Write-Host "[전송 완료] 메시지 전송 완료." -ForegroundColor Green
            Write-Host ""  # 다음 반복을 위한 공백 줄
            $sentCount++
            $nextSendTime = $startTime.AddMilliseconds($sentCount * $SEND_INTERVAL_MS)
        }
        # 응답 대기 및 처리
        if ($udpClient.Client.Poll($PER_RECEIVE_TIMEOUT_MS * 1000, [System.Net.Sockets.SelectMode]::SelectRead)) {
            $refEP = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)
            $data = $udpClient.Receive([ref]$refEP)
            $text = [System.Text.Encoding]::UTF8.GetString($data)
            # APIPA 응답 제외
            if ($refEP.Address.ToString() -match '^169\.254\.') { continue }
            # 유효 패턴 응답 확인
            if ($text -match 'CN=' -and $text -match 'MD=' -and $text -match 'VR=') {
                Write-Host "[수신] $($refEP.Address): $text" -ForegroundColor Yellow
                $found += $refEP.Address
                break
            }
        }
    }
}
catch {
    Write-Host "[오류] 테스트 중 오류 발생: $_" -ForegroundColor Red
}
finally {
    if ($udpClient) {
        # 소켓 셧다운 후 닫기 및 Dispose로 자원 해제
        try { $udpClient.Client.Shutdown([System.Net.Sockets.SocketShutdown]::Both) } catch {}
        $udpClient.Close()
        $udpClient.Dispose()
    }
    # 유효한 응답이 없으면 알림
    if ($found.Count -eq 0) {
        Write-Host "[정보] 유효한 응답이 없습니다." -ForegroundColor Yellow
    }
    Write-Host "[완료] 테스트 종료" -ForegroundColor Cyan
    Read-Host -Prompt "아무 키나 누르면 종료됩니다..."
}
