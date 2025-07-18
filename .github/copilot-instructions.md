# GitHub Copilot Instructions for AutoHotKey_nir414

## 개요

- 리포지토리 `AutoHotKey_nir414`에는 Windows 자동화 스크립트가 포함되어 있습니다:
  - 루트 및 하위 폴더에 있는 AutoHotKey(`*.ahk`) 유틸리티
  - `이더넷 IP 연결/` 폴더의 PowerShell 네트워크 도구

- 주요 네트워크 구성 진입점:
  - `이더넷 IP 연결/choose_adapter_apply_ips.ps1` — 어댑터 선택, IP 할당(Static/DHCP), 어댑터 재시작 및 Auto-reboot 모드를 제공하는 대화형 PowerShell 스크립트
  - `이더넷 IP 연결/run_ip_apply.bat` — 관리자 권한 상승 후 PS1 파일을 실행하는 배치 스크립트
  - 수동 IP 모드를 위한 CSV 소스: `이더넷 IP 연결/IP___.csv`

## 주요 패턴 및 규칙

- PowerShell 파일은 4칸 들여쓰기를 사용하고, cmdlet 및 .NET 호출을 `Try/Catch/Finally` 블록으로 명시적으로 감쌉니다.
- `Write-Host`에 `-ForegroundColor` 옵션을 사용하여 로그 수준별로 색상을 구분: Green, Yellow, Red, Cyan
- `$mode` 숫자 코드(0: device search, 1: DHCP restore, 2: manual IP, 3: restart, 4: auto-reboot, 9: exit)로 동작 모드를 분기합니다.
- APIPA(169.254.x.x) 제외: `Get-NetIPAddress` 결과를 regex `'^169\.254\.'`로 필터링합니다.
- 모드 2, 4에서는 `Test-AdapterConnectivity` 함수를 인라인 정의하여 소켓을 `$LocalIP`에 바인딩하고 `8.8.8.8:53`에 TCP 연결을 시도합니다.
- `Start-Sleep -Seconds`로 어댑터 재시작 및 라우팅 전파 대기 시간을 제어합니다.

## 자주 수행하는 AI 작업

- **새 모드 추가**: 기존 `$mode` 분기를 참고해 구조를 복제하고 `Write-Host`, `pause`를 사용해 일관성 유지
- **타임아웃 조정**: 모드 4의 `Start-Sleep` 값 또는 `Test-AdapterConnectivity`의 `$Timeout` 파라미터를 수정
- **연결 검증 확장**: `Test-AdapterConnectivity` 로직을 업데이트하거나 대체하되, 로컬 엔드포인트 바인딩 방식을 유지
- **에러 핸들링 강화**: 핵심 `Get-Net*`, `netsh` 호출을 `-ErrorAction Stop` 및 `Try/Catch`로 감싸기

## 실행 및 디버깅

- Windows 파일 탐색기나 PowerShell에서 `run_ip_apply.bat`을 실행하면 관리자 권한으로 `choose_adapter_apply_ips.ps1`이 실행됩니다.
- VS Code 통합 터미널에서 `choose_adapter_apply_ips.ps1`을 열고 실행해 결과 로그를 확인합니다.
- 색상별 `Write-Host` 메시지를 통해 어댑터 상태, TCP 테스트 결과 등을 추적합니다.

## CI 및 테스트 없음

- 이 프로젝트에는 자동화된 테스트나 CI 설정이 없으므로 실제 네트워크 환경에서 수동으로 검증해야 합니다.

---

이 지침을 검토한 후, Copilot이 더 효과적으로 작업할 수 있도록 이 리포지토리에 특화된 누락된 컨텍스트나 패턴이 있으면 제안해 주세요.
