@echo off
echo IP교체 v1.1.26
REM echo 관리자 권한 검사
if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin & exit /b)
cd "%~dp0"
setlocal enabledelayedexpansion
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
		echo ^|
		echo ---- IPV4를 수동으로 교체 합니다 ----
		call :ReadIp
		REM for /f "tokens=1 delims=:" %%a in (이더넷_IP.txt) do set IPFile=%%a
		REM echo 1: 최근 사용한 IP: !IPFile!
		REM echo 2: IP수동 입력
		set /p input=IP를 선택해 주세요(새로운 IP입력은 0번): 
		
		if !input! GEQ 1 (
			if !input! LEQ !ipArrayCount! (
				echo !ipArray[%input%]! IP교체 시도
				netsh interface ipv4 set address name="이더넷" static !ipArray[%input%]!
				echo errorlevel: %errorlevel%
				if %errorlevel% neq 0 (
					echo 오류
					goto End
				)
			) else (
				echo 오류
				goto End
			)
		) else if "!input!" EQU "0" (
			goto SelectIPMode
		
		REM if "!input!"=="1" (
			REM echo !IPFile! IP교체 시도
			REM netsh interface ipv4 set address name="이더넷" static !IPFile!
		REM ) else if "!input!"=="2" (
			REM goto SelectIPMode
		
		) else (
			echo 오류
			goto End
		)
		goto IPStatusAfterChange
	:SelectIPMode
		set /p inputIP=IP를 입력하세요(예시:192.168.0.80 255.255.255.0): 
		set "SPACE= "
		if "!inputIP:%SPACE%=!"=="%inputIP%" (
			set inputIP=!inputIP! 255.255.255.0
		)
		echo !inputIP! IP교체 시도
		netsh interface ipv4 set address name="이더넷" static !inputIP!
		echo errorlevel: %errorlevel%
		if %errorlevel% neq 0 (
			echo 오류
			goto End
		)
		
		set /p input=최근 사용 IP에 추가 하시겠습니까?(y/n): 
		if "!input!"=="y" (
			echo 파일 저장 시도
			set "ipType=0"
			for %%i in (!inputIP!) do (
				set /a ipType+=1
				if !ipType! equ 1 (
					set outputIP=IP:%%i
				) else if !ipType! equ 2 (
					set outputIP=!outputIP! SM:%%i
				) else (
					echo 오류 !outputIP!
					goto End
				)
			)
			echo 추가됨:!outputIP!
			echo !outputIP! >> "이더넷_IP.txt"
		) else if "!input!"=="n" (
			echo 거부됨
			goto End
		) else (
			echo 오류
			goto End
		)
		goto IPStatusAfterChange
		
	:ReadIp
		set "lineCount=0"
		for /f "usebackq tokens=* delims=" %%a in ("이더넷_IP.txt") do (
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
		echo 오류
		goto End
	:IPStatusAfterChange
		netsh interface ipv4 show addresses name="이더넷"
		for /f "tokens=2,*" %%a in ('netsh interface ipv4 show addresses name^="이더넷" ^| find "DHCP 사용"') do set "cmdOutput=%%b"
		echo 변경후 이더넷의 DHCP 사용 상태: !cmdOutput!

endlocal
:End
PAUSE
REM cmd /k

REM EQU - equal,  같음
REM NEQ - not equal,  다르면
REM LSS - less than,  작으면 (미만)
REM LEQ - less than or equal 작거나 같으면 (이하)
REM GTR - greater than, 크면 (초과)
REM GEQ - greater than or equal, 크거나 같으면(이상)