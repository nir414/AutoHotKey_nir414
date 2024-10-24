; Alt+Tab 기능 유지, Alt가 떨어지면 마우스를 선택된 창으로 이동 (Alt 단독은 무시)

; Alt+Tab 조합 여부를 추적하는 플래그
AltTabPressed := false

~LAlt & Tab::
    AltTabPressed := true  ; Alt+Tab이 눌렸음을 표시
    Send, {Alt down}{Tab}
    KeyWait, Tab, D        ; Tab 키가 눌려 있는 동안 계속 기다림
    return

~LAlt Up::
    ; Alt 키가 놓일 때 Alt+Tab 조합이 사용된 경우에만 마우스 이동
    if (AltTabPressed) {
        AltTabPressed := false  ; 플래그 초기화
        Send, {Alt up}          ; Alt 릴리스
        Sleep, 10              ; 창 전환 후 마우스 이동을 위해 잠시 대기
        MouseMoveToActiveWindow()
    }
    return

MouseMoveToActiveWindow()
{
    ; 활성화된 창의 위치와 크기 가져오기
    WinGetPos, X, Y, Width, Height, A
    ; 창 중앙으로 마우스 이동
    MouseMove, % X + (Width / 2), % Y + (Height / 2)
}

; MouseMoveToActiveWindow()
; {
;     ; 활성화된 창의 핸들 가져오기
;     WinGet, hwnd, ID, A
; 
;     ; 전체 창의 위치와 크기 가져오기
;     VarSetCapacity(rect, 16)
;     DllCall("GetWindowRect", "ptr", hwnd, "ptr", &rect)
; 
;     left := NumGet(rect, 0, "Int")
;     top := NumGet(rect, 4, "Int")
;     right := NumGet(rect, 8, "Int")
;     bottom := NumGet(rect, 12, "Int")
; 
;     ; 창의 너비와 높이 계산
;     windowWidth := right - left
;     windowHeight := bottom - top
; 
;     ; 창의 중앙 좌표 계산
;     centerX := left + (windowWidth / 2)
;     centerY := top + (windowHeight / 2)
; 
;     ; 마우스를 창의 중앙으로 이동
;     MouseMove, %centerX%, %centerY%, 2  ; 속도 10
; }
