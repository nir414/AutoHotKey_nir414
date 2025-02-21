#Persistent
#SingleInstance Force

global count := 0
global threshold := 5 ; 트리거될 카운트 수
global resetTime := 10000 ; 카운트 초기화 시간 (10초)

; 특정 프로그램에서만 작동하도록 설정
SetTitleMatchMode, 2
winTitle := "ahk_exe Program.exe" ; 특정 프로그램 실행 파일명으로 감지

; 단축키 감지
~^+a::
    if WinActive(winTitle) {
        count++
        ToolTip, 현재 카운트: %count%

        if (count >= threshold) {
            Sleep, 500 ; 0.5초 대기
            Send, !b ; Alt + B 입력
            count := 0 ; 카운트 초기화
            ToolTip, 카운트 리셋됨!
            SetTimer, RemoveToolTip, 2000
        }
        SetTimer, ResetCounter, %resetTime%
    }
return

; 일정 시간이 지나면 카운트 리셋
ResetCounter:
    count := 0
    ToolTip, 자동 리셋됨!
    SetTimer, RemoveToolTip, 2000
return

; 툴팁 제거
RemoveToolTip:
    ToolTip
return
