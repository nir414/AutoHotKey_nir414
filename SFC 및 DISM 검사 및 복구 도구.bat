@echo off
mode con cols=20 lines=2
title SFC 및 DISM 검사 및 복구 도구
echo 관리자 권한 검사
if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin & exit /b)
mode con cols=65 lines=15
powershell -Command "$Host.UI.RawUI.BufferSize = New-Object Management.Automation.Host.Size(100, 9999)"

cls
echo =================================================================
echo                SFC 및 DISM 검사 및 복구 도구 시작
echo =================================================================
echo.

:: SFC 검사 결과 로그 저장
REM echo 1. 시스템 파일 검사 (SFC) 시작...
@echo on
sfc /scannow
REM sfc /scannow > "%temp%\sfc_result.log"
@echo off
echo.

:: DISM 복구 결과 로그 저장
REM echo 2. DISM 도구를 통한 시스템 복구 시작...
@echo on
DISM /Online /Cleanup-Image /RestoreHealth
REM DISM /Online /Cleanup-Image /RestoreHealth > "%temp%\dism_result.log"
@echo off
echo.

:: 최종 결과 출력
REM cls
REM echo ============================================
REM echo      최종 SFC 및 DISM 검사 결과
REM echo ============================================

REM echo SFC 검사 결과:
REM type "%temp%\sfc_result.log"
REM echo.

REM echo DISM 검사 결과:
REM type "%temp%\dism_result.log"
REM echo.

echo =================================================================
echo                  모든 작업이 완료되었습니다.
echo =================================================================
pause







REM @echo off
REM mode con cols=20 lines=2
REM title SFC 및 DISM 검사 및 복구 도구
REM echo 관리자 권한 검사
REM if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin & exit /b)
REM mode con cols=65 lines=15
REM cls
REM echo ============================================
REM echo      SFC 및 DISM 검사 및 복구 도구 시작
REM echo ============================================
REM echo.

REM :: 관리자 권한으로 실행 확인
REM net session >nul 2>&1
REM if %errorLevel% NEQ 0 (
    REM echo 이 스크립트는 관리자 권한이 필요합니다.
    REM echo 관리자 권한으로 다시 실행해 주세요.
    REM pause
    REM exit
REM )

REM echo 1. 시스템 파일 검사 (SFC) 시작...
REM sfc /scannow
REM echo.

REM echo 2. DISM 도구를 통한 시스템 복구 시작...
REM DISM /Online /Cleanup-Image /RestoreHealth
REM echo.

REM echo ============================================
REM echo      모든 작업이 완료되었습니다.
REM echo ============================================
REM pause


