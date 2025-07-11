# 관리자 권한 체크
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
	Write-Host "? 이 스크립트는 관리자 권한으로 실행되어야 합니다."
	pause
	exit
}

# 메인 루프
do {
	# 어댑터 목록 표시
	$adapters = Get-NetAdapter | Where-Object Status -eq 'Up'
	if ($adapters.Count -eq 0) {
		Write-Host "? 사용 가능한 어댑터가 없습니다."
		pause
		exit
	}

	Write-Host "`n[어댑터] 사용 가능한 어댑터:"
	for ($i = 0; $i -lt $adapters.Count; $i++) {
		Write-Host "[$i] $($adapters[$i].Name) ($($adapters[$i].MacAddress))"
	}
	$selection = Read-Host "`n사용할 어댑터 번호를 입력하세요"
	if ($selection -notmatch '^\d+$' -or $selection -ge $adapters.Count) {
		Write-Host "? 잘못된 선택입니다."
		continue
	}
	$adapter = $adapters[$selection]
	Write-Host "`n[선택완료] 선택된 어댑터: $($adapter.Name)"

	# 모드 선택
	Write-Host "`n[모드선택] 동작 모드 선택:"
	Write-Host "[0] 로봇 연결용 수동 IP 설정"
	Write-Host "[1] 인터넷 연결 복원 (DHCP 초기화)"
	Write-Host "[2] 어댑터 재시작"
	Write-Host "[9] 프로그램 종료"
	$mode = Read-Host "`n원하는 모드 번호를 입력하세요"
	if ($mode -notin '0','1','2','9') {
		Write-Host "? 잘못된 선택입니다."
		continue
	}

	# 프로그램 종료
	if ($mode -eq '9') {
		Write-Host "`n[종료] 프로그램을 종료합니다."
		break
	}

	# 어댑터 재시작 모드
	if ($mode -eq '2') {
		Write-Host "`n[재시작] 어댑터 재시작 중: $($adapter.Name)..."
		try {
			Disable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction Stop
			Start-Sleep -Seconds 2
			Enable-NetAdapter -Name $adapter.Name -ErrorAction Stop
			Write-Host "[완료] 어댑터 재시작 완료"
		} catch {
			Write-Host "? 어댑터 재시작 실패: $_"
		}
		Write-Host "`n[대기] 아무 키나 누르면 메뉴로 돌아갑니다..."
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

			# InterfaceMetric 초기화
			Set-NetIPInterface -InterfaceAlias $adapter.Name -InterfaceMetric 0 -ErrorAction SilentlyContinue
			Write-Host "[작업중] Interface Metric 초기화 완료"

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
			Write-Host "? DHCP 복원 실패: $_"
		}
		Write-Host "`n[대기] 아무 키나 누르면 메뉴로 돌아갑니다..."
		pause
		continue
	}

	# 수동 IP 설정 모드
	$ipListPath = Join-Path -Path $PSScriptRoot -ChildPath "IP___.csv"
	if (-Not (Test-Path $ipListPath)) {
		Write-Host "? IP___.csv 파일을 찾을 수 없습니다: $ipListPath"
		Write-Host "[대기] 아무 키나 누르면 메뉴로 돌아갑니다..."
		pause
		continue
	}
	$ipEntries = Import-Csv -Path $ipListPath
	if ($ipEntries.Count -eq 0) {
		Write-Host "? IP 목록이 비어 있습니다."
		Write-Host "[대기] 아무 키나 누르면 메뉴로 돌아갑니다..."
		pause
		continue
	}

	Write-Host "`n[IP목록] 설정 가능한 IP 목록:"
	for ($i = 0; $i -lt $ipEntries.Count; $i++) {
		Write-Host "[$i] IP: $($ipEntries[$i].IP) / 서브넷: $($ipEntries[$i].SM)"
	}
	$ipSelect = Read-Host "`n적용할 IP 번호를 입력하세요"
	if ($ipSelect -notmatch '^\d+$' -or $ipSelect -ge $ipEntries.Count) {
		Write-Host "? 잘못된 선택입니다."
		continue
	}
	$chosen = $ipEntries[$ipSelect]
	$ip = $chosen.IP
	$subnet = $chosen.SM

	if (-not ($ip -and $subnet)) {
		Write-Host "? IP 또는 서브넷 마스크가 비어 있습니다."
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

	# 현재 IP 정보 표시
	$currentIP = Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue
	if ($currentIP) {
		Write-Host "`n[현재IP] 현재 IP: $($currentIP.IPAddress)"
	}

	Write-Host "`n[IP제거] 기존 IP 제거 중..."
	Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue

	Write-Host "[IP설정] IP 적용 중: $ip / $subnet (Prefix: $prefix) / Gateway: $gateway"
	try {
		# netsh로 IP 설정
		Start-Process -FilePath "netsh" -ArgumentList "interface ip set address name=`"$($adapter.Name)`" static $ip $subnet $gateway" -WindowStyle Hidden -Wait
		
		# DNS는 자동으로 설정 (DHCP)
		Start-Process -FilePath "netsh" -ArgumentList "interface ip set dns name=`"$($adapter.Name)`" source=dhcp" -WindowStyle Hidden -Wait
		
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
		Write-Host "`n? IP 설정 실패: $_"
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

} while ($true)
