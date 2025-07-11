# �ܼ� â ũ�� ����
try {
	$host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(60, 15)
	$host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size(60, 300)
	$host.UI.RawUI.WindowTitle = "�̴��� IP ���� ����"
} catch {
	# â ũ�� ���� ���н� ����
}

# ������ ���� üũ
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
	Write-Host "�� ��ũ��Ʈ�� ������ �������� ����Ǿ�� �մϴ�."
	pause
	exit
}

# ���� ����
do {
	# ����� ��� ǥ��
	$adapters = Get-NetAdapter | Where-Object Status -eq 'Up'
	if ($adapters.Count -eq 0) {
		Write-Host "��� ������ ����Ͱ� �����ϴ�."
		pause
		exit
	}

	Write-Host "`n[�����] ��� ������ �����:"
	for ($i = 0; $i -lt $adapters.Count; $i++) {
		Write-Host "[$i] $($adapters[$i].Name) ($($adapters[$i].MacAddress))"
	}
	$selection = Read-Host "`n����� ����� ��ȣ�� �Է��ϼ���"
	if ($selection -notmatch '^\d+$' -or $selection -ge $adapters.Count) {
		Write-Host "�߸��� �����Դϴ�."
		continue
	}
	$adapter = $adapters[$selection]
	Write-Host "`n[���ÿϷ�] ���õ� �����: $($adapter.Name)"

	# ��� ����
	Write-Host "`n[��弱��] ���� ��� ����:"
	Write-Host "[0] ��Ʈ��ũ ��� �˻� �� IP ����"
	Write-Host "[1] ���ͳ� ���� ���� (DHCP �ʱ�ȭ)"
	Write-Host "[2] �κ� ����� ���� IP ����"
	Write-Host "[3] ����� �����"
	Write-Host "[9] ���α׷� ����"
	$mode = Read-Host "`n���ϴ� ��� ��ȣ�� �Է��ϼ���"
	if ($mode -notin '0','1','2','3','9') {
		Write-Host "�߸��� �����Դϴ�."
		continue
	}

	# ���α׷� ����
	if ($mode -eq '9') {
		Write-Host "`n[����] ���α׷��� �����մϴ�."
		break
	}

	# ����� ����� ���
	if ($mode -eq '3') {
		Write-Host "`n[�����] ����� ����� ��: $($adapter.Name)..."
		try {
			Disable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction Stop
			Start-Sleep -Seconds 2
			Enable-NetAdapter -Name $adapter.Name -ErrorAction Stop
			Write-Host "[�Ϸ�] ����� ����� �Ϸ�"
		} catch {
			Write-Host "����� ����� ����: $_"
		}
		Write-Host "`n[���] �ƹ� Ű�� ������ �޴��� ���ư��ϴ�..."
		pause
		continue
	}

	# ��Ʈ��ũ ��� �˻� ���
	if ($mode -eq '0') {
		Write-Host "`n[���˻�] ��Ʈ��ũ ��� �˻� ����..." -ForegroundColor Green
		
		# ��ε�ĳ��Ʈ ����
		$BROADCAST_IP = "255.255.255.255"
		$BROADCAST_PORT = 51417
		$LOCAL_PORT = 51417
		$message = [byte[]](0, 0, 255, 255, 0, 0, 0, 12, 0, 101, 0, 0)
		
		Write-Host "[�˻���] ��ε�ĳ��Ʈ �޽��� ���� ��..." -ForegroundColor Yellow
		
		$foundDevices = @()
		
		try {
			# UDP Ŭ���̾�Ʈ ����
			$udpClient = New-Object System.Net.Sockets.UdpClient
			$udpClient.EnableBroadcast = $true
			
			# ���� ��Ʈ�� ���ε�
			$localEndPoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, $LOCAL_PORT)
			$udpClient.Client.Bind($localEndPoint)
			$udpClient.Client.ReceiveTimeout = 3000
			
			# ��ε�ĳ��Ʈ �޽��� ����
			$broadcastEndPoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Parse($BROADCAST_IP), $BROADCAST_PORT)
			$bytesSent = $udpClient.Send($message, $message.Length, $broadcastEndPoint)
			
			Write-Host "[���ۿϷ�] ��ε�ĳ��Ʈ �޽��� ���� ($bytesSent ����Ʈ)" -ForegroundColor Green
			Write-Host "[�����] ���� ���� �� (3��)..." -ForegroundColor Yellow
			
			$startTime = Get-Date
			
			# ���� ���� ����
			while ((Get-Date) - $startTime -lt [TimeSpan]::FromSeconds(3)) {
				try {
					$remoteEndPoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)
					$receivedBytes = $udpClient.Receive([ref]$remoteEndPoint)
					$receivedText = [System.Text.Encoding]::UTF8.GetString($receivedBytes)
					
					# ���� ���� Ȯ��
					if ($receivedText -match "CN=" -and $receivedText -match "MD=" -and $receivedText -match "VR=") {
						# ��� ���� �Ľ�
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
						
						# MASTER/SLAVE ����
						$lastSection = $sections[-1]
						if ($lastSection -match ",1$") {
							$deviceInfo.Node = "MASTER"
						} else {
							$deviceInfo.Node = "SLAVE"
						}
						
						# �ߺ� ����
						if ($foundDevices.IP -notcontains $deviceInfo.IP) {
							$foundDevices += $deviceInfo
							Write-Host "`n[�߰�] �� ��� �߰�: $($deviceInfo.IP)" -ForegroundColor Cyan
						}
					}
				}
				catch [System.Net.Sockets.SocketException] {
					# Ÿ�Ӿƿ� - ���� ����
					break
				}
				catch {
					break
				}
			}
		}
		catch {
			Write-Host "[����] ��ε�ĳ��Ʈ ����: $($_.Exception.Message)" -ForegroundColor Red
		}
		finally {
			if ($udpClient) {
				$udpClient.Close()
			}
		}
		
		Write-Host "`n[�Ϸ�] �˻� �Ϸ�! �߰ߵ� ���: $($foundDevices.Count)��" -ForegroundColor Green
		
		if ($foundDevices.Count -eq 0) {
			Write-Host "[���] �����ϴ� ��� ã�� �� �����ϴ�." -ForegroundColor Yellow
			Write-Host "[���] �ƹ� Ű�� ������ �޴��� ���ư��ϴ�..."
			pause
			continue
		}
		
		# �߰ߵ� ��� ��� ǥ��
		Write-Host "`n[�����] �߰ߵ� ��Ʈ��ũ ���:" -ForegroundColor Cyan
		for ($i = 0; $i -lt $foundDevices.Count; $i++) {
			$device = $foundDevices[$i]
			Write-Host "[$i] IP: $($device.IP) | $($device.Name) ($($device.Type)) [$($device.Node)]" -ForegroundColor White
		}
		
		# ��� ����
		$deviceSelect = Read-Host "`n������ ��� ��ȣ�� �Է��ϼ��� (���: Enter)"
		if ([string]::IsNullOrWhiteSpace($deviceSelect)) {
			Write-Host "[���] ��� ������ ��ҵǾ����ϴ�."
			Write-Host "[���] �ƹ� Ű�� ������ �޴��� ���ư��ϴ�..."
			pause
			continue
		}
		
		if ($deviceSelect -notmatch '^\d+$' -or $deviceSelect -ge $foundDevices.Count) {
			Write-Host "�߸��� �����Դϴ�."
			Write-Host "[���] �ƹ� Ű�� ������ �޴��� ���ư��ϴ�..."
			pause
			continue
		}
		
		$selectedDevice = $foundDevices[$deviceSelect]
		$targetIP = $selectedDevice.IP
		
		Write-Host "`n[���õ�] $($selectedDevice.Name) ($targetIP)" -ForegroundColor Green
		
		# IP �뿪 ��� (���� ��������� ����)
		$ipParts = $targetIP -split '\.'
		$baseIP = "$($ipParts[0]).$($ipParts[1]).$($ipParts[2])"
		
		# ��� ������ IP ����
		$suggestedIPs = @(
			"$baseIP.80",
			"$baseIP.120"
		)
		
		Write-Host "`n[IP����] ��� ������ IP �ּ�:" -ForegroundColor Cyan
		for ($i = 0; $i -lt $suggestedIPs.Count; $i++) {
			Write-Host "[$i] $($suggestedIPs[$i])"
		}
		Write-Host "[$($suggestedIPs.Count)] ���� �Է�"
		
		$ipChoice = Read-Host "`n����� IP�� �����ϼ���"
		
		if ($ipChoice -match '^\d+$' -and $ipChoice -lt $suggestedIPs.Count) {
			$newIP = $suggestedIPs[$ipChoice]
		} elseif ($ipChoice -eq $suggestedIPs.Count) {
			$newIP = Read-Host "����� IP �ּҸ� �Է��ϼ��� (��: $baseIP.150)"
			if (-not ($newIP -match '^\d+\.\d+\.\d+\.\d+$')) {
				Write-Host "�߸��� IP �����Դϴ�."
				Write-Host "[���] �ƹ� Ű�� ������ �޴��� ���ư��ϴ�..."
				pause
				continue
			}
		} else {
			Write-Host "�߸��� �����Դϴ�."
			Write-Host "[���] �ƹ� Ű�� ������ �޴��� ���ư��ϴ�..."
			pause
			continue
		}
		
		# IP ���� ����
		$subnet = "255.255.255.0"  # �⺻ �����
		$gateway = "$baseIP.1"     # �⺻ ����Ʈ����
		
		Write-Host "`n[��������] IP ���� ���� ��..."
		Write-Host "[����] �� IP: $newIP"
		Write-Host "[����] �����: $subnet" 
		Write-Host "[����] ����Ʈ����: $gateway"
		Write-Host "[����] ������: $($selectedDevice.Name) ($targetIP)"
		
		# ���� IP ǥ��
		$currentIP = Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue
		if ($currentIP) {
			Write-Host "[����IP] ���� IP: $($currentIP.IPAddress)"
		}
		
		# ���� IP ����
		Write-Host "[IP����] ���� IP ���� ��..."
		Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
		
		try {
			# netsh�� IP ����
			Start-Process -FilePath "netsh" -ArgumentList "interface ip set address name=`"$($adapter.Name)`" static $newIP $subnet $gateway" -WindowStyle Hidden -Wait
			Start-Process -FilePath "netsh" -ArgumentList "interface ip set dns name=`"$($adapter.Name)`" source=dhcp" -WindowStyle Hidden -Wait
			
			# Interface Metric�� 1�� ���� (���� �켱����)
			Set-NetIPInterface -InterfaceAlias $adapter.Name -AutomaticMetric Disabled -ErrorAction SilentlyContinue
			Set-NetIPInterface -InterfaceAlias $adapter.Name -InterfaceMetric 1 -ErrorAction SilentlyContinue
			Write-Host "[�۾���] Interface Metric�� 1�� ���� �Ϸ�"
			
			Write-Host "[�Ϸ�] IP ���� �Ϸ�" -ForegroundColor Green
			
			# ���� Ȯ��
			Start-Sleep -Seconds 2
			$verifyIP = Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue
			if ($verifyIP -and $verifyIP.IPAddress -eq $newIP) {
				Write-Host "[��������] IP ���� ���� ����: $($verifyIP.IPAddress)" -ForegroundColor Green
				
				# ��� ���� ���� �׽�Ʈ
				Write-Host "`n[�����׽�Ʈ] ��� ���� ���� Ȯ�� ��..."
				$pingTest = Test-Connection -ComputerName $targetIP -Count 2 -Quiet -ErrorAction SilentlyContinue
				if ($pingTest) {
					Write-Host "[����] ��� ��� ���� ����! ($targetIP)" -ForegroundColor Green
				} else {
					Write-Host "[���] ��� ��� ���� ���� (��Ʈ��ũ ���� Ȯ�� �ʿ�)" -ForegroundColor Yellow
				}
			} else {
				Write-Host "[���] IP ���� ���� ����" -ForegroundColor Yellow
			}
		} catch {
			Write-Host "[����] IP ���� ����: $_" -ForegroundColor Red
		}
		
		Write-Host "`n[�Ϸ�] ��� �˻� �� IP ���� �Ϸ�!"
		Write-Host "[���] �ƹ� Ű�� ������ �޴��� ���ư��ϴ�..."
		pause
		continue
	}

	# DHCP ���� ���
	if ($mode -eq '1') {
		Write-Host "`n[DHCP����] DHCP ���� ��..."
		try {
			# ���� IP ���� ǥ��
			$currentIP = Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue
			if ($currentIP) {
				Write-Host "[����IP] ���� IP: $($currentIP.IPAddress)"
			}

			# PowerShell ������� DHCP ����
			Write-Host "[�۾���] PowerShell ������� DHCP ���� ��..."
			Set-NetIPInterface -InterfaceAlias $adapter.Name -Dhcp Enabled -ErrorAction SilentlyContinue
			Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ResetServerAddresses -ErrorAction SilentlyContinue

			# netsh ������� ���� ����
			Write-Host "[�۾���] netsh ������� ���� ���� ��..."
			Start-Process -FilePath "netsh" -ArgumentList "interface ip set address name=`"$($adapter.Name)`" source=dhcp" -WindowStyle Hidden -Wait
			Start-Process -FilePath "netsh" -ArgumentList "interface ip set dns name=`"$($adapter.Name)`" source=dhcp" -WindowStyle Hidden -Wait

			# �⺻ ����Ʈ���� ����� �浹 ����
			Write-Host "[�۾���] ����� ���̺� ���� ��..."
			$routes = Get-NetRoute -InterfaceAlias $adapter.Name -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue
			foreach ($route in $routes) {
				Remove-NetRoute -InterfaceAlias $adapter.Name -DestinationPrefix "0.0.0.0/0" -Confirm:$false -ErrorAction SilentlyContinue
			}

			# InterfaceMetric�� �ڵ�(�⺻��)���� ����
			Set-NetIPInterface -InterfaceAlias $adapter.Name -AutomaticMetric Enabled -ErrorAction SilentlyContinue
			Write-Host "[�۾���] Interface Metric �ڵ� ���� �Ϸ�"

			Write-Host "[�Ϸ�] DHCP �� DNS �ʱ�ȭ �Ϸ�"

			# ��� ��� �� ���� Ȯ��
			Write-Host "[�����] ��Ʈ��ũ ���� ��� ��..."
			Start-Sleep -Seconds 3

			Write-Host "`n[����Ȯ��] ���ͳ� ���� Ȯ�� (ping 8.8.8.8)..."
			$pingResult = Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet -ErrorAction SilentlyContinue
			if ($pingResult) {
				Write-Host "[����] ���ͳ� ���� ����"
			} else {
				Write-Host "[���] ���ͳ� ���� ���� (���� �Ŀ��� �������� �� ����)"
			}

			# ������ IP ���� ǥ��
			$newIP = Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue
			if ($newIP) {
				Write-Host "[����IP] ������ IP: $($newIP.IPAddress)"
			}
		} catch {
			Write-Host "DHCP ���� ����: $_"
		}
		Write-Host "`n[���] �ƹ� Ű�� ������ �޴��� ���ư��ϴ�..."
		pause
		continue
	}

	# ���� IP ���� ���
	if ($mode -eq '2') {
	$ipListPath = Join-Path -Path $PSScriptRoot -ChildPath "IP___.csv"
	if (-Not (Test-Path $ipListPath)) {
		Write-Host "IP___.csv ������ ã�� �� �����ϴ�: $ipListPath"
		Write-Host "[���] �ƹ� Ű�� ������ �޴��� ���ư��ϴ�..."
		pause
		continue
	}
	$ipEntries = Import-Csv -Path $ipListPath
	if ($ipEntries.Count -eq 0) {
		Write-Host "IP ����� ��� �ֽ��ϴ�."
		Write-Host "[���] �ƹ� Ű�� ������ �޴��� ���ư��ϴ�..."
		pause
		continue
	}

	Write-Host "`n[IP���] ���� ������ IP ���:"
	for ($i = 0; $i -lt $ipEntries.Count; $i++) {
		$comment = if ($ipEntries[$i].Comment) { " - $($ipEntries[$i].Comment)" } else { "" }
		Write-Host "[$i] IP: $($ipEntries[$i].IP) / �����: $($ipEntries[$i].SM)$comment"
	}
	$ipSelect = Read-Host "`n������ IP ��ȣ�� �Է��ϼ���"
	if ($ipSelect -notmatch '^\d+$' -or $ipSelect -ge $ipEntries.Count) {
		Write-Host "�߸��� �����Դϴ�."
		continue
	}
	$chosen = $ipEntries[$ipSelect]
	$ip = $chosen.IP
	$subnet = $chosen.SM
	$comment = if ($chosen.Comment) { $chosen.Comment } else { "���� ����" }

	Write-Host "`n[������IP] $comment"

	if (-not ($ip -and $subnet)) {
		Write-Host "IP �Ǵ� ����� ����ũ�� ��� �ֽ��ϴ�."
		Write-Host "[���] �ƹ� Ű�� ������ �޴��� ���ư��ϴ�..."
		pause
		continue
	}

	function Get-PrefixLength($mask) {
		$binary = ($mask -split '\.') | ForEach-Object { [Convert]::ToString($_,2).PadLeft(8,'0') }
		return ($binary -join '').ToCharArray() | Where-Object { $_ -eq '1' } | Measure-Object | Select-Object -ExpandProperty Count
	}
	$prefix = Get-PrefixLength $subnet
	$gateway = ($ip -replace '\d+$','1')

	# ���� IP ���� ǥ��
	$currentIP = Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue
	if ($currentIP) {
		Write-Host "`n[����IP] ���� IP: $($currentIP.IPAddress)"
	}

	Write-Host "`n[IP����] ���� IP ���� ��..."
	Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue

	Write-Host "[IP����] IP ���� ��: $ip / $subnet (Prefix: $prefix) / Gateway: $gateway"
	try {
		# netsh�� IP ����
		Start-Process -FilePath "netsh" -ArgumentList "interface ip set address name=`"$($adapter.Name)`" static $ip $subnet $gateway" -WindowStyle Hidden -Wait
		
		# DNS�� �ڵ����� ���� (DHCP)
		Start-Process -FilePath "netsh" -ArgumentList "interface ip set dns name=`"$($adapter.Name)`" source=dhcp" -WindowStyle Hidden -Wait
		
		# Interface Metric�� 1�� ���� (���� �켱����)
		Set-NetIPInterface -InterfaceAlias $adapter.Name -AutomaticMetric Disabled -ErrorAction SilentlyContinue
		Set-NetIPInterface -InterfaceAlias $adapter.Name -InterfaceMetric 1 -ErrorAction SilentlyContinue
		Write-Host "[�۾���] Interface Metric�� 1�� ���� �Ϸ�"
		
		Write-Host "`n[�Ϸ�] IP ���� �Ϸ�"
		
		# ���� Ȯ��
		Start-Sleep -Seconds 2
		$newIP = Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue
		if ($newIP -and $newIP.IPAddress -eq $ip) {
			Write-Host "[��������] IP ���� ���� ����: $($newIP.IPAddress)"
		} else {
			Write-Host "[���] IP ���� ���� ���� - ������ IP�� �ٸ�"
		}
	} catch {
		Write-Host "`nIP ���� ����: $_"
		Write-Host "[���] �ƹ� Ű�� ������ �޴��� ���ư��ϴ�..."
		pause
		continue
	}

	Write-Host "`n[����Ȯ��] ���ͳ� ���� Ȯ�� (ping 8.8.8.8)..."
	$pingResult = Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet -ErrorAction SilentlyContinue
	if ($pingResult) {
		Write-Host "[����] ���ͳ� ���� ����"
	} else {
		Write-Host "[���] ���ͳ� ���� ���� (���ø� �����)"
	}

	Write-Host "`n[�Ϸ�] ��� �۾� �Ϸ�!"
	Write-Host "[���] �ƹ� Ű�� ������ �޴��� ���ư��ϴ�..."
	pause
	}

} while ($true)
