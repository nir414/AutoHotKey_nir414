@echo off
echo ������ ���� �˻�
if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin & exit /b)
setlocal enabledelayedexpansion
	cd "%~dp0"
	netsh interface ipv4 show addresses name="�̴���"
	for /f "tokens=2,*" %%a in ('netsh interface ipv4 show addresses name^="�̴���" ^| find "DHCP ���"') do set "cmdOutput=%%b"
	echo ������ �̴����� DHCP ��� ����: !cmdOutput!
	
	if "!cmdOutput!"=="No" goto AutoDHCP
	if "!cmdOutput!"=="Yes" goto ManuDHCP
	goto Error
	
	:AutoDHCP
		set /p input=DHCP�� ����Ͻðڽ��ϱ�?(y/n): 
		if "!input!"=="y" (
			echo DHCP '���'���� ����õ�
			netsh interface ipv4 set address name="�̴���" DHCP
		) else if "!input!"=="n" (
			echo �źε�
			goto End
		) else (
			echo ����
			goto End
		)
		goto IPStatusAfterChange
	:ManuDHCP
		echo IPV4�� �������� ��ü �մϴ�.
		for /f "tokens=1 delims=:" %%a in (�̴���_IP.txt) do set IPFile=%%a
		echo 1: �ֱ� ����� IP: !IPFile!
		echo 2: IP���� �Է�
		set /p input=��ü ����� �����ϼ���: 
		if "!input!"=="1" (
			echo !IPFile! IP��ü �õ�
			netsh interface ipv4 set address name="�̴���" static !IPFile!
		) else if "!input!"=="2" (
			goto SelectIPMode
		) else (
			echo ����
			goto End
		)
		goto IPStatusAfterChange
	:SelectIPMode
		set /p inputIP=IP�� �Է��ϼ���(����:192.168.0.80 255.255.255.0): 
		echo !inputIP! IP��ü �õ�
		netsh interface ipv4 set address name="�̴���" static !inputIP!
		set /p input=����� IP�� ��ü �Ͻðڽ��ϱ�?(y/n): 
		if "!input!"=="y" (
			echo ���� ���� �õ�
			echo !inputIP! > �̴���_IP.txt
		) else if "!input!"=="n" (
			echo �źε�
			goto End
		) else (
			echo ����
			goto End
		)
		goto IPStatusAfterChange
	:Error
		echo ����
		goto End
	
	REM if "!cmdOutput!"=="No" (
		REM set /p input=DHCP�� ����Ͻðڽ��ϱ�?(y/n): 
		REM if "!input!"=="n" (
			REM echo DHCP '���'���� ����õ�
			REM netsh interface ipv4 set address name="�̴���" DHCP
		REM ) else if "!input!"=="n" (
			REM echo �źε�
			REM goto End
		REM ) else (
			REM echo ����
			REM goto End
		REM )
	REM ) else if "!cmdOutput!"=="Yes" (
		REM echo IPV4�� �������� ��ü �մϴ�.
		REM for /f "tokens=1 delims=:" %%a in (�̴���_IP.txt) do set IPFile=%%a
		REM echo 1: �ֱ� ����� IP: !IPFile!
		REM echo 2: IP���� �Է�
		REM set /p input=��ü ����� �����ϼ���(y/n): 
		REM if "!input!"=="1" (
			REM echo !IPFile! IP��ü �õ�
			REM netsh interface ipv4 set address name="�̴���" static !IPFile!
		REM ) else if "!input!"=="2" (
			REM set /p inputIP=IP�� �Է��ϼ���(����:192.168.0.80 255.255.255.0): 
			REM echo !inputIP! IP��ü �õ�
			REM netsh interface ipv4 set address name="�̴���" static !inputIP!
			REM set /p ����� IP�� ��ü �Ͻðڽ��ϱ�?(y/n): 
			REM if "!input!"=="y" (
				REM echo "!inputIP!">�̴���_IP.txt
			REM ) else if "!input!"=="n"(
				REM echo �źε�
			REM ) else (
				REM echo ����
				REM goto End
			REM )
		REM ) else (
			REM echo ����
			REM goto End
		REM )
	REM ) else (
		REM echo ����
		REM goto End
	REM )
:IPStatusAfterChange
	netsh interface ipv4 show addresses name="�̴���"
	REM for /f "tokens=2,*" %%a in ('netsh interface ipv4 show addresses name^="�̴���" ^| find "DHCP ���"') do set "cmdOutput=%%b"
	REM echo ������ �̴����� DHCP ��� ����: !cmdOutput!

endlocal
:End
PAUSE
REM cmd /k