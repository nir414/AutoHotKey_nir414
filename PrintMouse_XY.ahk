; GUI 창 생성 및 마우스 좌표, 활성 창의 좌표와 크기, 모니터 정보 출력
Gui, Add, Text, x10 y10 w300 h20 vMousePosText, Mouse Position (Relative): 
Gui, Add, Text, x10 y40 w300 h20 vMouseAbsPosText, Mouse Position (Absolute): 
Gui, Add, Text, x10 y70 w300 h20 vWinPosText, Active Window: 
Gui, Add, Text, x10 y100 w300 h20 vMonitorInfoText, Monitor Work Area: 
Gui, Show, w400 h180, Mouse & Window Tracker

SetTimer, UpdatePositions, 100  ; 100ms마다 마우스 및 창의 위치, 모니터 정보 갱신
Return

UpdatePositions:
{
		; 마우스 상대 좌표 가져오기
		MouseGetPos, xpos, ypos  
		GuiControl,, MousePosText, Mouse Position (Relative): X%xpos% Y%ypos%  ; 마우스 좌표 갱신

		; 마우스 절대 좌표 가져오기
		CoordMode, Mouse, Screen  ; 절대 좌표 모드 설정
		MouseGetPos, absXpos, absYpos
		GuiControl,, MouseAbsPosText, Mouse Position (Absolute): X%absXpos% Y%absYpos%
		CoordMode, Mouse, Relative  ; 다시 상대 좌표 모드로 설정
		
		; 활성 창의 좌표와 크기 가져오기
		WinGetPos, winX, winY, winW, winH, A
		GuiControl,, WinPosText, Active Window: X%winX% Y%winY% W%winW% H%winH%  ; 활성 창 좌표 및 크기 갱신

		; 활성 창의 핸들 가져오기
		winHandle := WinExist("A")
		; 모니터 정보를 가져오기 위한 준비
		VarSetCapacity(monitorInfo, 40), NumPut(40, monitorInfo)
		; 활성 창이 어느 모니터에 있는지 확인
		monitorHandle := DllCall("MonitorFromWindow", "Ptr", winHandle, "UInt", 0x2)
		DllCall("GetMonitorInfo", "Ptr", monitorHandle, "Ptr", &monitorInfo)
		; 모니터 작업 영역 좌표 가져오기
		workLeft := NumGet(monitorInfo, 20, "Int")
		workTop := NumGet(monitorInfo, 24, "Int")
		workRight := NumGet(monitorInfo, 28, "Int")
		workBottom := NumGet(monitorInfo, 32, "Int")

		; 모니터 정보 GUI에 출력
		GuiControl,, MonitorInfoText, Monitor Work Area: L%workLeft% T%workTop% R%workRight% B%workBottom%
}
Return

GuiClose:
ExitApp  ; GUI 창을 닫으면 스크립트 종료
