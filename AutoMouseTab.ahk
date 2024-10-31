; Alt+Tab 기능 유지, Alt가 떨어지면 마우스를 선택된 창으로 이동 (Alt 단독은 무시)

; Alt+Tab 조합 여부를 추적하는 플래그
AltTabPressed := false

; 마우스 좌표 모드 절대 좌표
CoordMode, Mouse, Screen

~LAlt & Tab::
	Send, {Alt down}{Tab}
	KeyWait, Tab, D		; Tab 키가 눌려 있는 동안 계속 기다림
	
	if (!AltTabPressed) {
		; 주 디스플레이 해상도
		width := DllCall("GetSystemMetrics", "int", 0) // 2
		height := DllCall("GetSystemMetrics", "int", 1) // 2
		MouseMove, %width%, %height%
	}
	
	AltTabPressed := true  ; Alt+Tab이 눌렸음을 표시
	return

~LAlt Up::
	; Alt 키가 놓일 때 Alt+Tab 조합이 사용된 경우에만 마우스 이동
	if (AltTabPressed) {
		; 플래그 초기화
		AltTabPressed := false		; 플래그 초기화
		Send, {Alt up}						; Alt 릴리스
		; Sleep, 10									; 창 전환 후 마우스 이동을 위해 잠시 대기
		MouseMoveToActiveWindow()
	}
	return

; 마우스 좌클릭 시 마우스 이동 트리거
~LAlt & LButton::
	if (AltTabPressed) {
		; 플래그 초기화
		AltTabPressed := false
		Send {Blind}{LButton}		; Alt 상태에서 클릭을 허용
		Send, {Alt up}					; Alt 릴리스
		; Sleep, 10								; 창 전환 후 마우스 이동을 위해 잠시 대기
		MouseMoveToActiveWindow()
	}
	return

MouseMoveToActiveWindow()
{  
	; 0.5초 대기 제한 설정
	maxWaitTime := 500
	startTime := A_TickCount
	; 메모리 공간을 40바이트 크기로 할당
	VarSetCapacity(monitorInfo, 40), NumPut(40, monitorInfo)

	; 창의 위치와 크기를 가져올 때까지 대기, 최대 0.5초
	WinGetPos, winX, winY, winW, winH, A
	while (winX = "" or winY = "" winW = "" or winH = "") {
		if (A_TickCount - startTime > maxWaitTime) {
			MsgBox, 창의 위치나 크기를 가져오지 못했습니다. 마우스 이동을 취소합니다.
			return  ; 마우스 이동 취소
		}
		; Sleep, 10
		WinGetPos, winX, winY, winW, winH, A
	}
	
	; 현재 창이 어느 모니터에 있는지 확인
	winHandle := WinExist("A")
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
	
	; 창 중앙위치 계산 및 보정
	WinGetPos, winX, winY, winW, winH, A
	; centerX := Round((winX + winW / 2) * (width / (workRight - workLeft)))
	; centerY := Round((winY + winH / 2) * (height / (workBottom - workTop)))

	; 마우스를 해당 모니터의 중앙으로 이동
	; 시작점과 끝점 설정
	MouseGetPos, startX, startY
	endX := winX + winW // 2, endY := winY + winH // 2
	
	; 이동에 걸릴 총 시간 (0.1초 = 100ms)
	totalTime := 80

	; 총 이동 거리 계산
	totalDistanceX := endX - startX
	totalDistanceY := endY - startY

	; 이동 시작 시간 기록
	startTime := A_TickCount

	Loop
	{
		; 경과 시간 계산
		elapsedTime := A_TickCount - startTime

		; t는 경과 시간을 기준으로 0에서 1까지 변화
		t := elapsedTime / totalTime
		if (t > 1)  ; 목표에 도달하면 루프 종료
			break

		; 가속 곡선을 적용하여 t 값 증가 (여기서는 easeInQuad 형태의 가속 사용)
		t := t * t

		; t에 따라 현재 위치 계산
		currentX := startX + totalDistanceX * t
		currentY := startY + totalDistanceY * t

		; 마우스 위치 업데이트
		DllCall("User32.dll\SetCursorPos", "int", Round(currentX * (width / (workRight - workLeft))), "int", Round(currentY * (height / (workBottom - workTop))))

		; 짧은 딜레이 추가로 부드러운 이동
		Sleep, 1
	}

	; MouseMove, %centerX%, %centerY%
}
