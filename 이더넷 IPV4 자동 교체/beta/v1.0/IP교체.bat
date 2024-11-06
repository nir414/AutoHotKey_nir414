@echo off
echo 관리자 권한 검사
if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin & exit /b)
setlocal enabledelayedexpansion
	cd "%~dp0"
	netsh interface ipv4 show addresses name="이더넷"
	for /f "tokens=2,*" %%a in ('netsh interface ipv4 show addresses name^="이더넷" ^| find "DHCP 사용"') do set "cmdOutput=%%b"
	echo 변경전 이더넷의 DHCP 사용 상태: !cmdOutput!
	
	if "!cmdOutput!"=="No" goto AutoDHCP
	if "!cmdOutput!"=="Yes" goto ManuDHCP
	goto Error
	
	:AutoDHCP
		set /p input=DHCP를 사용하시겠습니까?(y/n): 
		if "!input!"=="y" (
			echo DHCP '사용'으로 변경시도
			netsh interface ipv4 set address name="이더넷" DHCP
		) else if "!input!"=="n" (
			echo 거부됨
			goto End
		) else (
			echo 오류
			goto End
		)
		goto IPStatusAfterChange
	:ManuDHCP
		echo IPV4를 수동으로 교체 합니다.
		for /f "tokens=1 delims=:" %%a in (이더넷_IP.txt) do set IPFile=%%a
		echo 1: 최근 사용한 IP: !IPFile!
		echo 2: IP수동 입력
		set /p input=교체 방법을 선택하세요: 
		if "!input!"=="1" (
			echo !IPFile! IP교체 시도
			netsh interface ipv4 set address name="이더넷" static !IPFile!
		) else if "!input!"=="2" (
			goto SelectIPMode
		) else (
			echo 오류
			goto End
		)
		goto IPStatusAfterChange
	:SelectIPMode
		set /p inputIP=IP를 입력하세요(예시:192.168.0.80 255.255.255.0): 
		echo !inputIP! IP교체 시도
		netsh interface ipv4 set address name="이더넷" static !inputIP!
		set /p input=저장된 IP를 교체 하시겠습니까?(y/n): 
		if "!input!"=="y" (
			echo 파일 저장 시도
			echo !inputIP! > 이더넷_IP.txt
		) else if "!input!"=="n" (
			echo 거부됨
			goto End
		) else (
			echo 오류
			goto End
		)
		goto IPStatusAfterChange
	:Error
		echo 오류
		goto End
	
	REM if "!cmdOutput!"=="No" (
		REM set /p input=DHCP를 사용하시겠습니까?(y/n): 
		REM if "!input!"=="n" (
			REM echo DHCP '사용'으로 변경시도
			REM netsh interface ipv4 set address name="이더넷" DHCP
		REM ) else if "!input!"=="n" (
			REM echo 거부됨
			REM goto End
		REM ) else (
			REM echo 오류
			REM goto End
		REM )
	REM ) else if "!cmdOutput!"=="Yes" (
		REM echo IPV4를 수동으로 교체 합니다.
		REM for /f "tokens=1 delims=:" %%a in (이더넷_IP.txt) do set IPFile=%%a
		REM echo 1: 최근 사용한 IP: !IPFile!
		REM echo 2: IP수동 입력
		REM set /p input=교체 방법을 선택하세요(y/n): 
		REM if "!input!"=="1" (
			REM echo !IPFile! IP교체 시도
			REM netsh interface ipv4 set address name="이더넷" static !IPFile!
		REM ) else if "!input!"=="2" (
			REM set /p inputIP=IP를 입력하세요(예시:192.168.0.80 255.255.255.0): 
			REM echo !inputIP! IP교체 시도
			REM netsh interface ipv4 set address name="이더넷" static !inputIP!
			REM set /p 저장된 IP를 교체 하시겠습니까?(y/n): 
			REM if "!input!"=="y" (
				REM echo "!inputIP!">이더넷_IP.txt
			REM ) else if "!input!"=="n"(
				REM echo 거부됨
			REM ) else (
				REM echo 오류
				REM goto End
			REM )
		REM ) else (
			REM echo 오류
			REM goto End
		REM )
	REM ) else (
		REM echo 오류
		REM goto End
	REM )
:IPStatusAfterChange
	netsh interface ipv4 show addresses name="이더넷"
	REM for /f "tokens=2,*" %%a in ('netsh interface ipv4 show addresses name^="이더넷" ^| find "DHCP 사용"') do set "cmdOutput=%%b"
	REM echo 변경후 이더넷의 DHCP 사용 상태: !cmdOutput!

endlocal
:End
PAUSE
REM cmd /k