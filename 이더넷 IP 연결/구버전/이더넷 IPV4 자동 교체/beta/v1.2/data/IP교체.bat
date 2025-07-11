@echo off
set IpChVer=IP��ü v1.2.6
mode con cols=20 lines=2
title %IpChVer%
echo ������ ���� �˻�
if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin & exit /b)
mode con cols=80 lines=20
cls
echo %IpChVer%
cd "%~dp0"
setlocal enabledelayedexpansion
	echo ====+====+====
	netsh interface ipv4 show addresses name="�̴���"
	for /f "tokens=2,*" %%a in ('netsh interface ipv4 show addresses name^="�̴���" ^| find "DHCP ���"') do set "cmdOutput=%%b"
	REM echo ������ �̴����� DHCP ��� ����: !cmdOutput!
	if "!cmdOutput!"=="No" (
		call :AutoDHCP
	) else if "!cmdOutput!"=="Yes" (
		call :ManuDHCP
	) else (
		goto Error
	)
	call :PrintIpStatus
	endlocal
:End
PAUSE
exit

:AutoDHCP
	set /p input=DHCP�� ����Ͻðڽ��ϱ�?(y/n): 
	if "!input!"=="y" (
		echo DHCP '���'���� ����õ�
		netsh interface ipv4 set address name="�̴���" DHCP
		netsh interface ipv4 set interface "�̴���" metric=auto
	) else if "!input!"=="n" (
		echo �źε�
		echo.
		call :ManuDHCP
	) else (
		goto Error
	)
goto :eof

:ManuDHCP
	REM echo ^|
	echo ---- IPV4�� �������� ��ü �մϴ� ----
	call :ReadIp
	set /p input=IP�� ������ �ּ���(���ο� IP�Է��� 0��): 
	
	if !input! GEQ 1 (
		if !input! LEQ !ipArrayCount! (
			echo !ipArray[%input%]! IP��ü �õ�
			netsh interface ipv4 set address name="�̴���" static !ipArray[%input%]!
			netsh interface ipv4 set interface "�̴���" metric=100
			echo errorlevel: %errorlevel%
			if %errorlevel% neq 0 (
				goto Error
			)
		) else (
			goto Error
		)
	) else if "!input!"=="0" (
		goto SelectIPMode
	) else (
		goto Error
	)
goto :eof
	
:SelectIPMode
	set /p inputIP=IP�� �Է��ϼ���(����:192.168.0.80 255.255.255.0): 
	set "SPACE= "
	if "!inputIP:%SPACE%=!"=="%inputIP%" (
		set inputIP=!inputIP! 255.255.255.0
	)
	echo !inputIP! IP��ü �õ�
	netsh interface ipv4 set address name="�̴���" static !inputIP!
	netsh interface ipv4 set interface "Ethernet" metric=100
	echo errorlevel: %errorlevel%
	if %errorlevel% neq 0 (
		goto Error
	)
	
	set /p input=�ֱ� ��� IP�� �߰� �Ͻðڽ��ϱ�?(y/n): 
	if "!input!"=="y" (
		echo ���� ���� �õ�
		set "ipType=0"
		for %%i in (!inputIP!) do (
			set /a ipType+=1
			if !ipType! equ 1 (
				set outputIP=IP:%%i
			) else if !ipType! equ 2 (
				set outputIP=!outputIP! SM:%%i
			) else (
				REM echo ���� !outputIP!
				goto Error
			)
		)
		echo �߰���:!outputIP!
		echo !outputIP! >> "�̴���_IP.txt"
	) else if "!input!"=="n" (
		echo �źε�
	) else (
		goto Error
	)
goto :eof

:ReadIp
	set "lineCount=0"
	for /f "usebackq tokens=* delims=" %%a in ("�̴���_IP.txt") do (
		set /a lineCount+=1
		set "line[!lineCount!]=%%a"
	)
	set "ipArrayCount=0"
	for /l %%i in (1, 1, !lineCount!) do (
		set "currentLine=!line[%%i]!"
		echo !currentLine! | findstr /i /c:"IP:" >nul && (
			set "currentLine=!currentLine:IP:=!"
			set "currentLine=!currentLine:SM:=!"
			set /a ipArrayCount+=1
			set "ipArray[!ipArrayCount!]=!currentLine!"
		)
	)
	for /l %%i in (1, 1, !ipArrayCount!) do (
		set "ipType=0"
		set output=[%%i]
		for %%j in (!ipArray[%%i]!) do (
			set /a ipType+=1
			if "!ipType!"=="1" (
				set output= !output! IP:%%j
			) else if "!ipType!"=="2" (
				set output=!output! SM:%%j
			) else (
				set output=!output! ??:%%j
			)
		)
		echo !output!
	)
goto :eof

:PrintIpStatus
	cls
	echo ====+====+====+====+====+====+====
	call :IPStatusAfterChange
	echo ====+====+====+====+====+====+====
goto :eof

:Error
	echo ����
goto End

:IPStatusAfterChange
	netsh interface ipv4 show addresses name="�̴���"
	for /f "tokens=2,*" %%a in ('netsh interface ipv4 show addresses name^="�̴���" ^| find "DHCP ���"') do set "cmdOutput=%%b"
	echo ������ �̴����� DHCP ��� ����: !cmdOutput!
goto :eof


REM EQU - equal,  ����
REM NEQ - not equal,  �ٸ���
REM LSS - less than,  ������ (�̸�)
REM LEQ - less than or equal �۰ų� ������ (����)
REM GTR - greater than, ũ�� (�ʰ�)
REM GEQ - greater than or equal, ũ�ų� ������(�̻�)
REM netsh interface ipv4 show interfaces
REM netsh interface ipv4 show config
REM netsh interface ipv4 set interface "Ethernet" metric=auto