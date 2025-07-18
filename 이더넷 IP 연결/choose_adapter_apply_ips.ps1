# TODO: 인터넷 연결 실패 시 동작 검증 필요 (추후 업데이트 예정)

# 콘솔 창 크기 설정
try {
	$host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(60, 15)
	$host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size(60, 300)
	$host.UI.RawUI.WindowTitle = "이더넷 IP 설정 도구"
} catch {
	# 창 크기 설정 실패시 무시
}

# 관리자 권한 체크
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
	Write-Host "이 스크립트는 관리자 권한으로 실행되어야 합니다."
	pause
	exit
}

# 메인 루프
do {
	# 어댑터 목록 표시
	$adapters = Get-NetAdapter | Where-Object Status -eq 'Up'
	if ($adapters.Count -eq 0) {
		Write-Host "사용 가능한 어댑터가 없습니다."
		pause
		exit
	}

	Write-Host "`n[어댑터] 사용 가능한 어댑터:"
	for ($i = 0; $i -lt $adapters.Count; $i++) {
		Write-Host "[$i] $($adapters[$i].Name) ($($adapters[$i].MacAddress))"
	}
	$selection = Read-Host "`n사용할 어댑터 번호를 입력하세요"
	if ($selection -notmatch '^\d+$' -or $selection -ge $adapters.Count) {
		Write-Host "잘못된 선택입니다."
		continue
	}
	$adapter = $adapters[$selection]
	Write-Host "`n[선택완료] 선택된 어댑터: $($adapter.Name)"

	# 모드 선택
	Write-Host "`n[모드선택] 동작 모드 선택:"
	Write-Host "[0] 네트워크 장비 검색 후 IP 설정"
	Write-Host "[1] 인터넷 연결 복원 (DHCP 초기화)"
	Write-Host "[2] 로봇 연결용 수동 IP 설정"
	Write-Host "[3] 어댑터 재시작"
	Write-Host "[4] 오토 재부팅 모드 (인터넷 연결 복구)"
	Write-Host "[9] 프로그램 종료"
	$mode = Read-Host "`n원하는 모드 번호를 입력하세요"
	if ($mode -notin '0','1','2','3','4','9') {
		Write-Host "잘못된 선택입니다."
		continue
	}

	# 프로그램 종료
	if ($mode -eq '9') {
		Write-Host "`n[종료] 프로그램을 종료합니다."
		break
	}

	# 어댑터 재시작 모드
	if ($mode -eq '3') {
		Write-Host "`n[재시작] 어댑터 재시작 중: $($adapter.Name)..."
		try {
			Disable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction Stop
			Start-Sleep -Seconds 2
			Enable-NetAdapter -Name $adapter.Name -ErrorAction Stop
			Write-Host "[완료] 어댑터 재시작 완료"
		} catch {
			Write-Host "어댑터 재시작 실패: $_"
		}
		Write-Host "`n[대기] 아무 키나 누르면 메뉴로 돌아갑니다..."
		pause
		continue
	}

	# 네트워크 장비 검색 모드
	if ($mode -eq '0') {
		Write-Host "`n[장비검색] 네트워크 장비 검색 시작..." -ForegroundColor Green
		
		# 브로드캐스트 설정
		$BROADCAST_IP = "255.255.255.255"
		$BROADCAST_PORT = 51417
		$LOCAL_PORT = 51417
		$message = [byte[]](0, 0, 255, 255, 0, 0, 0, 12, 0, 101, 0, 0)
		
		Write-Host "[검색중] 브로드캐스트 메시지 전송 중..." -ForegroundColor Yellow
		
		$foundDevices = @()
		
		try {
			# UDP 클라이언트 생성
			$udpClient = New-Object System.Net.Sockets.UdpClient
			$udpClient.EnableBroadcast = $true
			
			# 로컬 포트에 바인딩
			$localEndPoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, $LOCAL_PORT)
			$udpClient.Client.Bind($localEndPoint)
			$udpClient.Client.ReceiveTimeout = 3000
			
			# 브로드캐스트 메시지 전송
			$broadcastEndPoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Parse($BROADCAST_IP), $BROADCAST_PORT)
			$bytesSent = $udpClient.Send($message, $message.Length, $broadcastEndPoint)
			
			Write-Host "[전송완료] 브로드캐스트 메시지 전송 ($bytesSent 바이트)" -ForegroundColor Green
			Write-Host "[대기중] 응답 수신 중 (3초)..." -ForegroundColor Yellow
			
			$startTime = Get-Date
			
			# 응답 수신 루프
			while ((Get-Date) - $startTime -lt [TimeSpan]::FromSeconds(3)) {
				try {
					$remoteEndPoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)
					$receivedBytes = $udpClient.Receive([ref]$remoteEndPoint)
					$receivedText = [System.Text.Encoding]::UTF8.GetString($receivedBytes)
					
					# 응답 패턴 확인
					if ($receivedText -match "CN=" -and $receivedText -match "MD=" -and $receivedText -match "VR=") {
						# 장비 정보 파싱
						$deviceInfo = @{
							IP = $remoteEndPoint.Address.ToString()
							Name = ""
							Type = ""
							GPL = ""
							Node = ""
						}
						
						$sections = $receivedText -split ';'
						foreach ($section in $sections) {
							if ($section -match "CN=(.+)") { $deviceInfo.Name = $matches[1] }
							if ($section -match "MD=(.+)") { $deviceInfo.Type = $matches[1] }
							if ($section -match "VR=(.+)") { $deviceInfo.GPL = $matches[1] }
						}
						
						# MASTER/SLAVE 판정
						$lastSection = $sections[-1]
						if ($lastSection -match ",1$") {
							$deviceInfo.Node = "MASTER"
						} else {
							$deviceInfo.Node = "SLAVE"
						}
						
						# 중복 제거
						if ($foundDevices.IP -notcontains $deviceInfo.IP) {
							$foundDevices += $deviceInfo
							Write-Host "`n[발견] 새 장비 발견: $($deviceInfo.IP)" -ForegroundColor Cyan
						}
					}
				}
				catch [System.Net.Sockets.SocketException] {
					# 타임아웃 - 정상 종료
					break
				}
				catch {
					break
				}
			}
		}
		catch {
			Write-Host "[오류] 브로드캐스트 오류: $($_.Exception.Message)" -ForegroundColor Red
		}
		finally {
			if ($udpClient) {
				$udpClient.Close()
			}
		}
		
		Write-Host "`n[완료] 검색 완료! 발견된 장비: $($foundDevices.Count)개" -ForegroundColor Green
		
		if ($foundDevices.Count -eq 0) {
			Write-Host "[결과] 응답하는 장비를 찾을 수 없습니다." -ForegroundColor Yellow
			Write-Host "[대기] 아무 키나 누르면 메뉴로 돌아갑니다..."
			pause
			continue
		}
		
		# 발견된 장비 목록 표시
		Write-Host "`n[장비목록] 발견된 네트워크 장비:" -ForegroundColor Cyan
		for ($i = 0; $i -lt $foundDevices.Count; $i++) {
			$device = $foundDevices[$i]
			Write-Host "[$i] IP: $($device.IP) | $($device.Name) ($($device.Type)) [$($device.Node)]" -ForegroundColor White
		}
		
		# 장비 선택
		$deviceSelect = Read-Host "`n연결할 장비 번호를 입력하세요 (취소: Enter)"
		if ([string]::IsNullOrWhiteSpace($deviceSelect)) {
			Write-Host "[취소] 장비 선택이 취소되었습니다."
			Write-Host "[대기] 아무 키나 누르면 메뉴로 돌아갑니다..."
			pause
			continue
		}
		
		if ($deviceSelect -notmatch '^\d+$' -or $deviceSelect -ge $foundDevices.Count) {
			Write-Host "잘못된 선택입니다."
			Write-Host "[대기] 아무 키나 누르면 메뉴로 돌아갑니다..."
			pause
			continue
		}
		
		$selectedDevice = $foundDevices[$deviceSelect]
		$targetIP = $selectedDevice.IP
		
		Write-Host "`n[선택됨] $($selectedDevice.Name) ($targetIP)" -ForegroundColor Green
		
		# IP 대역 계산 (동일 서브넷으로 설정)
		$ipParts = $targetIP -split '\.'
		$baseIP = "$($ipParts[0]).$($ipParts[1]).$($ipParts[2])"
		
		# 사용 가능한 IP 제안
		$suggestedIPs = @(
			"$baseIP.80",
			"$baseIP.120"
		)
		
		Write-Host "`n[IP제안] 사용 가능한 IP 주소:" -ForegroundColor Cyan
		for ($i = 0; $i -lt $suggestedIPs.Count; $i++) {
			Write-Host "[$i] $($suggestedIPs[$i])"
		}
		Write-Host "[$($suggestedIPs.Count)] 직접 입력"
		
		$ipChoice = Read-Host "`n사용할 IP를 선택하세요"
		
		if ($ipChoice -match '^\d+$' -and $ipChoice -lt $suggestedIPs.Count) {
			$newIP = $suggestedIPs[$ipChoice]
		} elseif ($ipChoice -eq $suggestedIPs.Count) {
			$newIP = Read-Host "사용할 IP 주소를 입력하세요 (예: $baseIP.150)"
			if (-not ($newIP -match '^\d+\.\d+\.\d+\.\d+$')) {
				Write-Host "잘못된 IP 형식입니다."
				Write-Host "[대기] 아무 키나 누르면 메뉴로 돌아갑니다..."
				pause
				continue
			}
		} else {
			Write-Host "잘못된 선택입니다."
			Write-Host "[대기] 아무 키나 누르면 메뉴로 돌아갑니다..."
			pause
			continue
		}
		
		# IP 설정 실행
		$subnet = "255.255.255.0"  # 기본 서브넷
		$gateway = "$baseIP.1"     # 기본 게이트웨이
		
		Write-Host "`n[설정시작] IP 설정 적용 중..."
		Write-Host "[정보] 새 IP: $newIP"
		Write-Host "[정보] 서브넷: $subnet" 
		Write-Host "[정보] 게이트웨이: $gateway"
		Write-Host "[정보] 대상장비: $($selectedDevice.Name) ($targetIP)"
		
		# 현재 IP 표시
		$currentIP = Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue
		if ($currentIP) {
			Write-Host "[현재IP] 현재 IP: $($currentIP.IPAddress)"
		}
		
		# 기존 IP 제거
		Write-Host "[IP제거] 기존 IP 제거 중..."
		Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
		
		try {
			# netsh로 IP 설정
			Start-Process -FilePath "netsh" -ArgumentList "interface ip set address name=`"$($adapter.Name)`" static $newIP $subnet $gateway" -WindowStyle Hidden -Wait
			Start-Process -FilePath "netsh" -ArgumentList "interface ip set dns name=`"$($adapter.Name)`" source=dhcp" -WindowStyle Hidden -Wait
			
			# Interface Metric을 1로 설정 (높은 우선순위)
			Set-NetIPInterface -InterfaceAlias $adapter.Name -AutomaticMetric Disabled -ErrorAction SilentlyContinue
			Set-NetIPInterface -InterfaceAlias $adapter.Name -InterfaceMetric 1 -ErrorAction SilentlyContinue
			Write-Host "[작업중] Interface Metric을 1로 설정 완료"
			
			Write-Host "[완료] IP 설정 완료" -ForegroundColor Green
			
			# 설정 확인
			Start-Sleep -Seconds 2
			$verifyIP = Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue
			if ($verifyIP -and $verifyIP.IPAddress -eq $newIP) {
				Write-Host "[검증성공] IP 설정 검증 성공: $($verifyIP.IPAddress)" -ForegroundColor Green
				
				# 대상 장비와 연결 테스트
				Write-Host "`n[연결테스트] 대상 장비와 연결 확인 중..."
				$pingTest = Test-Connection -ComputerName $targetIP -Count 2 -Quiet -ErrorAction SilentlyContinue
				if ($pingTest) {
					Write-Host "[성공] 대상 장비 연결 성공! ($targetIP)" -ForegroundColor Green
				} else {
					Write-Host "[경고] 대상 장비 연결 실패 (네트워크 설정 확인 필요)" -ForegroundColor Yellow
				}
			} else {
				Write-Host "[경고] IP 설정 검증 실패" -ForegroundColor Yellow
			}
		} catch {
			Write-Host "[오류] IP 설정 실패: $_" -ForegroundColor Red
		}
		
		Write-Host "`n[완료] 장비 검색 및 IP 설정 완료!"
		Write-Host "[대기] 아무 키나 누르면 메뉴로 돌아갑니다..."
		pause
		continue
	}

	# DHCP 복원 모드
	if ($mode -eq '1') {
		Write-Host "`n[DHCP복원] DHCP 복원 중..."
		try {
			# 현재 IP 정보 표시
			$currentIP = Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue
			if ($currentIP) {
				Write-Host "[현재IP] 현재 IP: $($currentIP.IPAddress)"
			}

			# PowerShell 방식으로 DHCP 설정
			Write-Host "[작업중] PowerShell 방식으로 DHCP 설정 중..."
			Set-NetIPInterface -InterfaceAlias $adapter.Name -Dhcp Enabled -ErrorAction SilentlyContinue
			Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ResetServerAddresses -ErrorAction SilentlyContinue

			# netsh 방식으로 강제 적용
			Write-Host "[작업중] netsh 방식으로 강제 적용 중..."
			Start-Process -FilePath "netsh" -ArgumentList "interface ip set address name=`"$($adapter.Name)`" source=dhcp" -WindowStyle Hidden -Wait
			Start-Process -FilePath "netsh" -ArgumentList "interface ip set dns name=`"$($adapter.Name)`" source=dhcp" -WindowStyle Hidden -Wait

			# 기본 게이트웨이 라우팅 충돌 제거
			Write-Host "[작업중] 라우팅 테이블 정리 중..."
			$routes = Get-NetRoute -InterfaceAlias $adapter.Name -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue
			foreach ($route in $routes) {
				Remove-NetRoute -InterfaceAlias $adapter.Name -DestinationPrefix "0.0.0.0/0" -Confirm:$false -ErrorAction SilentlyContinue
			}

			# InterfaceMetric을 자동(기본값)으로 설정
			Set-NetIPInterface -InterfaceAlias $adapter.Name -AutomaticMetric Enabled -ErrorAction SilentlyContinue
			Write-Host "[작업중] Interface Metric 자동 설정 완료"

			Write-Host "[완료] DHCP 및 DNS 초기화 완료"

			# 잠시 대기 후 연결 확인
			Write-Host "[대기중] 네트워크 적용 대기 중..."
			Start-Sleep -Seconds 3

			Write-Host "`n[연결확인] 인터넷 연결 확인 (ping 8.8.8.8)..."
			$pingResult = Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet -ErrorAction SilentlyContinue
			if ($pingResult) {
				Write-Host "[성공] 인터넷 연결 성공"
			} else {
				Write-Host "[경고] 인터넷 연결 실패 (복구 후에도 비정상일 수 있음)"
			}

			# 복원된 IP 정보 표시
			$newIP = Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue
			if ($newIP) {
				Write-Host "[복원IP] 복원된 IP: $($newIP.IPAddress)"
			}
		} catch {
			Write-Host "DHCP 복원 실패: $_"
		}
		Write-Host "`n[대기] 아무 키나 누르면 메뉴로 돌아갑니다..."
		pause
		continue
	}

	# 수동 IP 설정 모드
	if ($mode -eq '2') {
	$ipListPath = Join-Path -Path $PSScriptRoot -ChildPath "IP___.csv"
	if (-Not (Test-Path $ipListPath)) {
		Write-Host "IP___.csv 파일을 찾을 수 없습니다: $ipListPath"
		Write-Host "[대기] 아무 키나 누르면 메뉴로 돌아갑니다..."
		pause
		continue
	}
	$ipEntries = Import-Csv -Path $ipListPath
	if ($ipEntries.Count -eq 0) {
		Write-Host "IP 목록이 비어 있습니다."
		Write-Host "[대기] 아무 키나 누르면 메뉴로 돌아갑니다..."
		pause
		continue
	}

	Write-Host "`n[IP목록] 설정 가능한 IP 목록:"
	for ($i = 0; $i -lt $ipEntries.Count; $i++) {
		$comment = if ($ipEntries[$i].Comment) { " - $($ipEntries[$i].Comment)" } else { "" }
		Write-Host "[$i] IP: $($ipEntries[$i].IP) / 서브넷: $($ipEntries[$i].SM)$comment"
	}
	$ipSelect = Read-Host "`n적용할 IP 번호를 입력하세요"
	if ($ipSelect -notmatch '^\d+$' -or $ipSelect -ge $ipEntries.Count) {
		Write-Host "잘못된 선택입니다."
		continue
	}
	$chosen = $ipEntries[$ipSelect]
	$ip = $chosen.IP
	$subnet = $chosen.SM
	$comment = if ($chosen.Comment) { $chosen.Comment } else { "설명 없음" }

	Write-Host "`n[선택한IP] $comment"

	if (-not ($ip -and $subnet)) {
		Write-Host "IP 또는 서브넷 마스크가 비어 있습니다."
		Write-Host "[대기] 아무 키나 누르면 메뉴로 돌아갑니다..."
		pause
		continue
	}

	function Get-PrefixLength($mask) {
		$binary = ($mask -split '\.') | ForEach-Object { [Convert]::ToString($_,2).PadLeft(8,'0') }
		return ($binary -join '').ToCharArray() | Where-Object { $_ -eq '1' } | Measure-Object | Select-Object -ExpandProperty Count
	}
	$prefix = Get-PrefixLength $subnet
	$gateway = ($ip -replace '\d+$','1')

	function Test-AdapterConnectivity {
		param (
			[Parameter(Mandatory=$true)]
			[string]$LocalIP,
			[string]$Target = "8.8.8.8",
			[int]$Port = 53,
			[int]$Timeout = 3000
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
	# 현재 IP 정보 표시
	$currentIP = Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue
	if ($currentIP) {
		Write-Host "`n[현재IP] 현재 IP: $($currentIP.IPAddress)"
	}

	# 어댑터의 유효 IP(169.254 제외)로 외부 TCP 연결 테스트
	$validAddr = Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 | Where-Object { $_.IPAddress -notmatch '^169\.254\.' } | Select-Object -First 1
	if ($validAddr) {
		$tcpResult = Test-AdapterConnectivity -LocalIP $validAddr.IPAddress
		Write-Host "[TCP 연결 테스트] 어댑터($($validAddr.IPAddress))로 외부 연결 성공: $tcpResult" -ForegroundColor Cyan
	} else {
		Write-Host "유효한 어댑터 IP가 없습니다." -ForegroundColor Yellow
	}
	Write-Host "`n[IP제거] 기존 IP 제거 중..."
	Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue

	Write-Host "[IP설정] IP 적용 중: $ip / $subnet (Prefix: $prefix) / Gateway: $gateway"
	try {
		# netsh로 IP 설정
		Start-Process -FilePath "netsh" -ArgumentList "interface ip set address name=`"$($adapter.Name)`" static $ip $subnet $gateway" -WindowStyle Hidden -Wait
		
		# DNS는 자동으로 설정 (DHCP)
		Start-Process -FilePath "netsh" -ArgumentList "interface ip set dns name=`"$($adapter.Name)`" source=dhcp" -WindowStyle Hidden -Wait
		
		# Interface Metric을 1로 설정 (높은 우선순위)
		Set-NetIPInterface -InterfaceAlias $adapter.Name -AutomaticMetric Disabled -ErrorAction SilentlyContinue
		Set-NetIPInterface -InterfaceAlias $adapter.Name -InterfaceMetric 1 -ErrorAction SilentlyContinue
		Write-Host "[작업중] Interface Metric을 1로 설정 완료"
		
		Write-Host "`n[완료] IP 설정 완료"
		
		# 설정 확인
		Start-Sleep -Seconds 2
		$newIP = Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue
		if ($newIP -and $newIP.IPAddress -eq $ip) {
			Write-Host "[검증성공] IP 설정 검증 성공: $($newIP.IPAddress)"
		} else {
			Write-Host "[경고] IP 설정 검증 실패 - 설정된 IP와 다름"
		}
	} catch {
		Write-Host "`nIP 설정 실패: $_"
		Write-Host "[대기] 아무 키나 누르면 메뉴로 돌아갑니다..."
		pause
		continue
	}

	Write-Host "`n[연결확인] 인터넷 연결 확인 (ping 8.8.8.8)..."
	$pingResult = Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet -ErrorAction SilentlyContinue
	if ($pingResult) {
		Write-Host "[성공] 인터넷 연결 성공"
	} else {
		Write-Host "[경고] 인터넷 연결 실패 (로컬만 연결됨)"
	}

	Write-Host "`n[완료] 모든 작업 완료!"
	Write-Host "[대기] 아무 키나 누르면 메뉴로 돌아갑니다..."
	pause
	}

	# 오토 재부팅 모드
	if ($mode -eq '4') {
	   Write-Host "`n[오토재부팅] 인터넷 연결 확인 및 자동 어댑터 재부팅 시작..." -ForegroundColor Cyan
	   function Test-AdapterConnectivity {
		   param (
			   [Parameter(Mandatory=$true)]
			   [string]$LocalIP,
			   [string]$Target = "8.8.8.8",
			   [int]$Port = 53,
			   [int]$Timeout = 3000
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
	   do {
		   # 어댑터 재부팅 (Disable -> Enable) 수행
		   Write-Host "[재부팅] 어댑터 재시작 중: $($adapter.Name)..." -ForegroundColor Yellow
		   Disable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction SilentlyContinue
		   Enable-NetAdapter -Name $adapter.Name -ErrorAction SilentlyContinue
		   Start-Sleep -Seconds 15
		   Write-Host "[대기] 재부팅 완료 후 인터넷 연결 확인 중..." -ForegroundColor Yellow

		   # --- 네트워크 연결 상태 사전 검증 및 TCP 연결 테스트 ---
		   $netAdapter = Get-NetAdapter -Name $adapter.Name -ErrorAction SilentlyContinue
		   $addrs = Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 |
					Where-Object { $_.IPAddress -notmatch '^169\.254\.' }
		   $route = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -AddressFamily IPv4 |
					Where-Object InterfaceAlias -EQ $adapter.Name
		   if ($netAdapter.Status -ne 'Up' -or $netAdapter.MediaConnectionState -ne 'Connected' -or -not $addrs -or -not $route) {
			   Write-Host "[경고] 이더넷 네트워크 미연결" -ForegroundColor Yellow
			   continue
		   }
		   $adapterIP = ($addrs | Select-Object -First 1).IPAddress
		   $tcpResult = Test-AdapterConnectivity -LocalIP $adapterIP
		   Write-Host "[TCP 연결 테스트] 어댑터($adapterIP)로 외부 연결 성공: $tcpResult" -ForegroundColor Cyan
		   if ($tcpResult) {
			   Write-Host "[성공] 유선 어댑터로 외부 인터넷 연결 확인됨" -ForegroundColor Green
			   break
		   }
	   } while ($true)
		Write-Host "`n[완료] 자동 재부팅 모드 종료, 인터넷 연결 복구됨."
		Write-Host "[대기] 아무 키나 누르면 메뉴로 돌아갑니다..."
		pause
		continue
	}

} while ($true)
