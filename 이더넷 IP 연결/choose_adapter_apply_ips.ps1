# ������ ���� üũ
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
	Write-Host "? �� ��ũ��Ʈ�� ������ �������� ����Ǿ�� �մϴ�."
	pause
	exit
}

# ���� ����
do {
	# ����� ��� ǥ��
	$adapters = Get-NetAdapter | Where-Object Status -eq 'Up'
	if ($adapters.Count -eq 0) {
		Write-Host "? ��� ������ ����Ͱ� �����ϴ�."
		pause
		exit
	}

	Write-Host "`n[�����] ��� ������ �����:"
	for ($i = 0; $i -lt $adapters.Count; $i++) {
		Write-Host "[$i] $($adapters[$i].Name) ($($adapters[$i].MacAddress))"
	}
	$selection = Read-Host "`n����� ����� ��ȣ�� �Է��ϼ���"
	if ($selection -notmatch '^\d+$' -or $selection -ge $adapters.Count) {
		Write-Host "? �߸��� �����Դϴ�."
		continue
	}
	$adapter = $adapters[$selection]
	Write-Host "`n[���ÿϷ�] ���õ� �����: $($adapter.Name)"

	# ��� ����
	Write-Host "`n[��弱��] ���� ��� ����:"
	Write-Host "[0] �κ� ����� ���� IP ����"
	Write-Host "[1] ���ͳ� ���� ���� (DHCP �ʱ�ȭ)"
	Write-Host "[2] ����� �����"
	Write-Host "[9] ���α׷� ����"
	$mode = Read-Host "`n���ϴ� ��� ��ȣ�� �Է��ϼ���"
	if ($mode -notin '0','1','2','9') {
		Write-Host "? �߸��� �����Դϴ�."
		continue
	}

	# ���α׷� ����
	if ($mode -eq '9') {
		Write-Host "`n[����] ���α׷��� �����մϴ�."
		break
	}

	# ����� ����� ���
	if ($mode -eq '2') {
		Write-Host "`n[�����] ����� ����� ��: $($adapter.Name)..."
		try {
			Disable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction Stop
			Start-Sleep -Seconds 2
			Enable-NetAdapter -Name $adapter.Name -ErrorAction Stop
			Write-Host "[�Ϸ�] ����� ����� �Ϸ�"
		} catch {
			Write-Host "? ����� ����� ����: $_"
		}
		Write-Host "`n[���] �ƹ� Ű�� ������ �޴��� ���ư��ϴ�..."
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

			# InterfaceMetric �ʱ�ȭ
			Set-NetIPInterface -InterfaceAlias $adapter.Name -InterfaceMetric 0 -ErrorAction SilentlyContinue
			Write-Host "[�۾���] Interface Metric �ʱ�ȭ �Ϸ�"

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
			Write-Host "? DHCP ���� ����: $_"
		}
		Write-Host "`n[���] �ƹ� Ű�� ������ �޴��� ���ư��ϴ�..."
		pause
		continue
	}

	# ���� IP ���� ���
	$ipListPath = Join-Path -Path $PSScriptRoot -ChildPath "IP___.csv"
	if (-Not (Test-Path $ipListPath)) {
		Write-Host "? IP___.csv ������ ã�� �� �����ϴ�: $ipListPath"
		Write-Host "[���] �ƹ� Ű�� ������ �޴��� ���ư��ϴ�..."
		pause
		continue
	}
	$ipEntries = Import-Csv -Path $ipListPath
	if ($ipEntries.Count -eq 0) {
		Write-Host "? IP ����� ��� �ֽ��ϴ�."
		Write-Host "[���] �ƹ� Ű�� ������ �޴��� ���ư��ϴ�..."
		pause
		continue
	}

	Write-Host "`n[IP���] ���� ������ IP ���:"
	for ($i = 0; $i -lt $ipEntries.Count; $i++) {
		Write-Host "[$i] IP: $($ipEntries[$i].IP) / �����: $($ipEntries[$i].SM)"
	}
	$ipSelect = Read-Host "`n������ IP ��ȣ�� �Է��ϼ���"
	if ($ipSelect -notmatch '^\d+$' -or $ipSelect -ge $ipEntries.Count) {
		Write-Host "? �߸��� �����Դϴ�."
		continue
	}
	$chosen = $ipEntries[$ipSelect]
	$ip = $chosen.IP
	$subnet = $chosen.SM

	if (-not ($ip -and $subnet)) {
		Write-Host "? IP �Ǵ� ����� ����ũ�� ��� �ֽ��ϴ�."
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
		Write-Host "`n? IP ���� ����: $_"
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

} while ($true)
