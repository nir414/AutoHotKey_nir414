@echo off
mode con cols=20 lines=2
title SFC �� DISM �˻� �� ���� ����
echo ������ ���� �˻�
if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin & exit /b)
mode con cols=65 lines=15
powershell -Command "$Host.UI.RawUI.BufferSize = New-Object Management.Automation.Host.Size(100, 9999)"

cls
echo =================================================================
echo                SFC �� DISM �˻� �� ���� ���� ����
echo =================================================================
echo.

:: SFC �˻� ��� �α� ����
REM echo 1. �ý��� ���� �˻� (SFC) ����...
@echo on
sfc /scannow
REM sfc /scannow > "%temp%\sfc_result.log"
@echo off
echo.

:: DISM ���� ��� �α� ����
REM echo 2. DISM ������ ���� �ý��� ���� ����...
@echo on
DISM /Online /Cleanup-Image /RestoreHealth
REM DISM /Online /Cleanup-Image /RestoreHealth > "%temp%\dism_result.log"
@echo off
echo.

:: ���� ��� ���
REM cls
REM echo ============================================
REM echo      ���� SFC �� DISM �˻� ���
REM echo ============================================

REM echo SFC �˻� ���:
REM type "%temp%\sfc_result.log"
REM echo.

REM echo DISM �˻� ���:
REM type "%temp%\dism_result.log"
REM echo.

echo =================================================================
echo                  ��� �۾��� �Ϸ�Ǿ����ϴ�.
echo =================================================================
pause







REM @echo off
REM mode con cols=20 lines=2
REM title SFC �� DISM �˻� �� ���� ����
REM echo ������ ���� �˻�
REM if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin & exit /b)
REM mode con cols=65 lines=15
REM cls
REM echo ============================================
REM echo      SFC �� DISM �˻� �� ���� ���� ����
REM echo ============================================
REM echo.

REM :: ������ �������� ���� Ȯ��
REM net session >nul 2>&1
REM if %errorLevel% NEQ 0 (
    REM echo �� ��ũ��Ʈ�� ������ ������ �ʿ��մϴ�.
    REM echo ������ �������� �ٽ� ������ �ּ���.
    REM pause
    REM exit
REM )

REM echo 1. �ý��� ���� �˻� (SFC) ����...
REM sfc /scannow
REM echo.

REM echo 2. DISM ������ ���� �ý��� ���� ����...
REM DISM /Online /Cleanup-Image /RestoreHealth
REM echo.

REM echo ============================================
REM echo      ��� �۾��� �Ϸ�Ǿ����ϴ�.
REM echo ============================================
REM pause


