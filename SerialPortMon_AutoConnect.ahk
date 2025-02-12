#Persistent  ; 스크립트가 계속 실행되도록 유지
SetTitleMatchMode, 3  ; 창 제목을 부분적으로 매칭할 수 있도록 설정



; SerialPortMon
; ahk_class #32770
; ahk_exe SerialPortMon.exe
; ahk_pid 10432
; ahk_id 1708630
; Main code

debugMode := 1
while (true)
{
	IfWinExist, ahk_exe SerialPortMon.exe

	{
		; 핸들 최초 한번 정의
		if (!IsSet(hwnd1) || hwnd1 = 0)
		{
			showMsgWithLineNumber("SerialPortMon 창의 핸들을 가져옵니다.", A_LineNumber)
			hwnd1 := WinExist("SerialPortMon")
			ControlGet, buttonStatus, Enabled,, Button1, ahk_id %hwnd1%
			ControlGetText, buttonText, Button1, ahk_id %hwnd1%
			; WinActivate, ahk_id %hwnd1%  ; "SerialPortMon" 창을 활성화
			if !(!IsSet(hwnd1) || hwnd1 = 0)
			{
				WinGetTitle, title, ahk_id %hwnd1%
				showMsgWithLineNumber("SerialPortMon 창을 찾았습니다. 핸들: '" . title . "'", A_LineNumber)
			}
		}
		else
		{
			checkAndClickSecondWindow()
			
			IfWinActive, ahk_id %hwnd1%  ; "SerialPortMon"으로 시작하는 창을 활성화된 창으로 인식
			{
				; 첫 번째 창의 "Connect" 버튼 상태를 확인
				ControlGet, buttonStatus, Enabled,, Button1, ahk_id %hwnd1%
				ControlGetText, buttonText, Button1, ahk_id %hwnd1%
				
				if (buttonStatus = 1)
				{
					if (buttonText = "Connect")
					{
						ControlClick, Button1, ahk_id %hwnd1%
						showMsgWithLineNumber("첫 번째 창의 'Connect' 버튼을 클릭했습니다.", A_LineNumber)
						Sleep, 200
					}
					else
					{
						; 버튼이 "Close" 상태일 때 대기
						if (buttonText = "Close")
						{
							showMsgWithLineNumber("첫 번째 창의 버튼이 'Close' 상태입니다. 대기 중...", A_LineNumber)
						}
						else
						{
							showMsgWithLineNumber("첫 번째 창의 Button1 텍스트는 '" buttonText "'입니다. 대기 중...", A_LineNumber)
						}
					}
				}
				else
				{
					showMsgWithLineNumber("첫 번째 창의 Button1 텍스트는 '" buttonText "'입니다. 대기 중...", A_LineNumber)
				}
			}
			else
			{
				showMsgWithLineNumber("'" . title . "'은 활성화되지 않았습니다. 대기 중...", A_LineNumber)
			}
		}
	}
	else
	{
		showMsgWithLineNumber("SerialPortMon 창이 존재하지 않아서 프로그램을 종료합니다.", A_LineNumber)
		ExitApp  ; 첫 번째 창이 없으면 프로그램을 종료
	}
}


; 연결 대화상자
; ahk_class #32770
; ahk_exe SerialPortMon.exe
; ahk_pid 10432
; ahk_id 922960
; 두 번째 창을 확인하고 버튼을 클릭하는 함수
checkAndClickSecondWindow() {
	; 새로 열린 연결 대화상자 확인 (ahk_class #32770)
	; IfWinExist, ahk_exe SerialPortMon.exe ahk_pid 10432 ; 창의 존재 확인
	IfWinExist, 연결 대화상자
	{
		; 핸들 최초 한번 정의
		If (!IsSet(hwnd2) || hwnd2 = 0)
		{
			hwnd2 := WinExist("연결 대화상자")
			WinGetTitle, title, ahk_id ahk_id %hwnd2%
			ControlGet, buttonStatus, Enabled,, Button1, ahk_id %hwnd2%
			ControlGetText, buttonText, Button1, ahk_id %hwnd2%
			showMsgWithLineNumber("SerialPortMon 창을 찾았습니다. 핸들: '" . title . "'", A_LineNumber)
		}
		
		If !(!IsSet(hwnd2) || hwnd2 = 0)
		{
			; WinActivate
			WinActivate, ahk_id %hwnd2%
			showMsgWithLineNumber("두 번째 창이 열렸습니다. 'Connect' 버튼을 클릭하려고 합니다.", A_LineNumber)

			; 두 번째 창이 열려 있을 때 계속해서 버튼을 클릭
			while (WinExist("ahk_id " . hwnd2))  ; 2번째 창이 존재하는 동안 반복
			{
				WinActivate, ahk_id %hwnd2%
				; 두 번째 창에서 "Connect" 버튼 클릭 (Button5)
				; ControlGetText, buttonText, Button5, ahk_class #32770
				ControlGet, buttonStatus, Enabled,, Button5, ahk_id %hwnd2%
				ControlGetText, buttonText, Button5, ahk_id %hwnd2%
				If (buttonStatus = 1)
				{
					if (buttonText = "Connect")
					{
						; ControlClick, Button5, ahk_class #32770
						ControlClick, Button5, ahk_id %hwnd2%
						showMsgWithLineNumber("두 번째 창에서 'Connect' 버튼을 클릭했습니다.", A_LineNumber)
						Sleep, 200
					}
					else
					{
						showMsgWithLineNumber("두 번째 창에서 버튼 텍스트는 '" buttonText "'입니다. 대기 중...", A_LineNumber)
					}
				}
				else
				{
					showMsgWithLineNumber("두 번째 창에서 Button5는 활성화되지 않았습니다. 대기 중...", A_LineNumber)
				}
			}
		}
	}
}


; 메세지 박스를 줄 번호와 함께 출력하는 함수 (툴팁 버전)
showMsgWithLineNumber(msg, lineNumber) {
	global lastMessage, lastLineNumber
	global lastOutputTime, timeLimit
	global debugMode
	
	if (!IsSet(lastOutputTime))
	{
		lastOutputTime = 0
		timeLimit = 100
	}
	
	
	; 동일한지 확인
	if (msg = lastMessage && lineNumber = lastLineNumber || debugMode = 0)
	{
			return  ; 동일하면 로그 기록을 건너뛰고 함수 종료
	}
	else
	{
		lastMessage := msg
		lastLineNumber := lineNumber
		
		while (A_TickCount - lastOutputTime < timeLimit)
		{
			Sleep, (timeLimit - (A_TickCount - lastOutputTime))
		}
		FileAppend, % "L(" lineNumber "):" msg "`n", debug_log.txt
		lastOutputTime := A_TickCount
	}
}
