@echo off
:: 관리자 권한 확인
net session >nul 2>&1
if %errorlevel% neq 0 (
	echo 관리자 권한으로 재시작합니다...
	powershell -Command "Start-Process '%~f0' -Verb runAs"
	exit /b
)

:: 현재 디렉토리 기준으로 .ps1 실행
set scriptpath=%~dp0choose_adapter_apply_ips.ps1
powershell.exe -ExecutionPolicy Bypass -File "%scriptpath%"
