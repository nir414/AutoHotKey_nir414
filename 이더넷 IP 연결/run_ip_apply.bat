@echo off
:: ������ ���� Ȯ��
net session >nul 2>&1
if %errorlevel% neq 0 (
	echo ������ �������� ������մϴ�...
	powershell -Command "Start-Process '%~f0' -Verb runAs"
	exit /b
)

:: ���� ���丮 �������� .ps1 ����
set scriptpath=%~dp0choose_adapter_apply_ips.ps1
powershell.exe -ExecutionPolicy Bypass -File "%scriptpath%"
