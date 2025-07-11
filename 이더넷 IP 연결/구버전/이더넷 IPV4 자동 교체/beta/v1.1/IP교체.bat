@echo off
echo IP��ü v1.1.26
REM echo ������ ���� �˻�
if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin & exit /b)
cd "%~dp0"
setlocal enabledelayedexpansion
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
		echo ^|
		echo ---- IPV4�� �������� ��ü �մϴ� ----
		call :ReadIp
		REM for /f "tokens=1 delims=:" %%a in (�̴���_IP.txt) do set IPFile=%%a
		REM echo 1: �ֱ� ����� IP: !IPFile!
		REM echo 2: IP���� �Է�
		set /p input=IP�� ������ �ּ���(���ο� IP�Է��� 0��): 
		
		if !input! GEQ 1 (
			if !input! LEQ !ipArrayCount! (
				echo !ipArray[%input%]! IP��ü �õ�
				netsh interface ipv4 set address name="�̴���" static !ipArray[%input%]!
				echo errorlevel: %errorlevel%
				if %errorlevel% neq 0 (
					echo ����
					goto End
				)
			) else (
				echo ����
				goto End
			)
		) else if "!input!" EQU "0" (
			goto SelectIPMode
		
		REM if "!input!"=="1" (
			REM echo !IPFile! IP��ü �õ�
			REM netsh interface ipv4 set address name="�̴���" static !IPFile!
		REM ) else if "!input!"=="2" (
			REM goto SelectIPMode
		
		) else (
			echo ����
			goto End
		)
		goto IPStatusAfterChange
	:SelectIPMode
		set /p inputIP=IP�� �Է��ϼ���(����:192.168.0.80 255.255.255.0): 
		set "SPACE= "
		if "!inputIP:%SPACE%=!"=="%inputIP%" (
			set inputIP=!inputIP! 255.255.255.0
		)
		echo !inputIP! IP��ü �õ�
		netsh interface ipv4 set address name="�̴���" static !inputIP!
		echo errorlevel: %errorlevel%
		if %errorlevel% neq 0 (
			echo ����
			goto End
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
					echo ���� !outputIP!
					goto End
				)
			)
			echo �߰���:!outputIP!
			echo !outputIP! >> "�̴���_IP.txt"
		) else if "!input!"=="n" (
			echo �źε�
			goto End
		) else (
			echo ����
			goto End
		)
		goto IPStatusAfterChange
		
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
			set output=[ %%i ]
			for %%j in (!ipArray[%%i]!) do (
				set /a ipType+=1
				if "!ipType!"=="1" (
					set output=  !output! IP:%%j
				) else if "!ipType!"=="2" (
					set output=!output! SM:%%j
				) else (
					set output=!output! ??:%%j
				)
			)
			echo !output!
		)
	goto :eof
		
	:Error
		echo ����
		goto End
	:IPStatusAfterChange
		netsh interface ipv4 show addresses name="�̴���"
		for /f "tokens=2,*" %%a in ('netsh interface ipv4 show addresses name^="�̴���" ^| find "DHCP ���"') do set "cmdOutput=%%b"
		echo ������ �̴����� DHCP ��� ����: !cmdOutput!

endlocal
:End
PAUSE
REM cmd /k

REM EQU - equal,  ����
REM NEQ - not equal,  �ٸ���
REM LSS - less than,  ������ (�̸�)
REM LEQ - less than or equal �۰ų� ������ (����)
REM GTR - greater than, ũ�� (�ʰ�)
REM GEQ - greater than or equal, ũ�ų� ������(�̻�)