; Alt+Tab 기능 유지, Alt가 떨어지면 마우스를 선택된 창으로 이동 (Alt 단독은 무시)

; Alt+Tab 조합 여부를 추적하는 플래그
AltTabPressed := false

; 마우스 좌표 모드 절대 좌표
CoordMode, Mouse, Screen

~LAlt & Tab::
	AltTabPressed := true  ; Alt+Tab이 눌렸음을 표시
	Send, {Alt down}{Tab}
	KeyWait, Tab, D        ; Tab 키가 눌려 있는 동안 계속 기다림
	
	; 주 디스플레이 해상도
	width := DllCall("GetSystemMetrics", "int", 0) // 2
	height := DllCall("GetSystemMetrics", "int", 1) // 2
	MouseMove, %width%, %height%
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
	; 메모리 공간을 40바이트 크기로 할당
	VarSetCapacity(monitorInfo, 40), NumPut(40, monitorInfo)

	; 활성 창의 핸들을 가져옴
	winHandle := WinExist("A")
	
	; 현재 창이 어느 모니터에 있는지 확인
	monitorHandle := DllCall("MonitorFromWindow", "Ptr", winHandle, "UInt", 0x2)
	DllCall("GetMonitorInfo", "Ptr", monitorHandle, "Ptr", &monitorInfo)
	
	; 모니터의 작업 영역 좌표 가져오기
	workLeft := NumGet(monitorInfo, 20, "Int")
	workTop := NumGet(monitorInfo, 24, "Int")
	workRight := NumGet(monitorInfo, 28, "Int")
	workBottom := NumGet(monitorInfo, 32, "Int")
	
	; 주 디스플레이 해상도
	width := DllCall("GetSystemMetrics", "int", 0)  
	height := DllCall("GetSystemMetrics", "int", 1)
	
	; 창 중앙위치 계산및 보정
	WinGetPos, winX, winY, winW, winH, A
	centerX := Round((winX + winW / 2) * (width / (workRight - workLeft)))
	centerY := Round((winY + winH / 2) * (height / (workBottom - workTop)))

	; 마우스를 해당 모니터의 중앙으로 이동
	MouseMove, %centerX%, %centerY%
}
