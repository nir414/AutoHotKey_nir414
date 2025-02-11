#Persistent  ; 스크립트가 계속 실행되도록 유지
SetTitleMatchMode, 1  ; 창 제목을 부분적으로 매칭할 수 있도록 설정


; SerialPortMon
; ahk_class #32770
; ahk_exe SerialPortMon.exe
; ahk_pid 10432
; ahk_id 1708630
; Main code
while (true)
{
	IfWinExist, SerialPortMon
	{
		; 핸들 최초 한번 정의
		if (!IsSet(hwnd) || hwnd = 0)
		{
			hwnd1 := WinExist()
			WinGetTitle, title, ahk_id hwnd1
			ControlGet, buttonStatus, Enabled,, Button1, hwnd1
			ControlGetText, buttonText, Button1, hwnd1
			showMsgWithLineNumber("SerialPortMon 창을 찾았습니다. 핸들: '" title "'", A_LineNumber)
			; WinActivate, ahk_id %hwnd1%  ; "SerialPortMon" 창을 활성화
		}
		else
		{
			checkAndClickSecondWindow()
			
			IfWinActive, SerialPortMon  ; "SerialPortMon"으로 시작하는 창을 활성화된 창으로 인식
			{
				; 첫 번째 창의 "Connect" 버튼 상태를 확인
				ControlGet, buttonStatus, Enabled,, Button1, hwnd1
				ControlGetText, buttonText, Button1, hwnd1
				
				if (buttonStatus = 1)
				{
					if (buttonText = "Connect")
					{
						ControlClick, Button1, SerialPortMon
						showMsgWithLineNumber("첫 번째 창의 'Connect' 버튼을 클릭했습니다.", A_LineNumber)
						Sleep, 20  ; 클릭 후 잠시 대기
					}
					else
					{
						; 버튼이 "Close" 상태일 때 대기
						if (buttonText = "Close")
						{
							showMsgWithLineNumber("첫 번째 창의 버튼이 'Close' 상태입니다. 대기 중...", A_LineNumber)
							Sleep, 20  ; 대기 후 다시 확인
						}
						else
						{
							showMsgWithLineNumber("첫 번째 창의 Button1 텍스트는 '" buttonText "'입니다. 대기 중...", A_LineNumber)
							Sleep, 20  ; 대기 후 다시 확인
						}
					}
				}
				else
				{
					showMsgWithLineNumber("첫 번째 창의 Button1 텍스트는 '" buttonText "'입니다. 대기 중...", A_LineNumber)
					Sleep, 20  ; 대기 후 다시 확인
				}
			}
			else
			{
				showMsgWithLineNumber("Button1은 활성화되지 않았습니다. 대기 중...", A_LineNumber)
				Sleep, 20
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
	IfWinExist, ahk_exe SerialPortMon.exe ahk_pid 10432 ; 창의 존재 확인
	{
		; 핸들 최초 한번 정의
		If (!IsSet(hwnd_ahk_class) || hwnd_ahk_class = 0)
		{
			hwnd_ahk_class := WinExist("연결 대화상자")
		}
		
		If !(!IsSet(hwnd_ahk_class) || hwnd_ahk_class = 0)
		{
			; WinActivate
			WinActivate, ahk_id %hwnd_ahk_class%
			showMsgWithLineNumber("두 번째 창이 열렸습니다. 'Connect' 버튼을 클릭하려고 합니다.", A_LineNumber)

			; 두 번째 창이 열려 있을 때 계속해서 버튼을 클릭
			while (WinExist("연결 대화상자"))  ; 2번째 창이 존재하는 동안 반복
			{
				WinActivate, ahk_id %hwnd_ahk_class%
				; 두 번째 창에서 "Connect" 버튼 클릭 (Button5)
				; ControlGetText, buttonText, Button5, ahk_class #32770
				ControlGet, buttonStatus, Enabled,, Button5, ahk_id %hwnd_ahk_class%
				ControlGetText, buttonText, Button5, ahk_id %hwnd_ahk_class%
				If (buttonStatus = 1)
				{
					if (buttonText = "Connect")
					{
						; ControlClick, Button5, ahk_class #32770
						ControlClick, Button5, ahk_id %hwnd_ahk_class%
						showMsgWithLineNumber("두 번째 창에서 'Connect' 버튼을 클릭했습니다.", A_LineNumber)
						Sleep, 20  ; 클릭 후 잠시 대기
					}
					else
					{
						showMsgWithLineNumber("두 번째 창에서 버튼 텍스트는 '" buttonText "'입니다. 대기 중...", A_LineNumber)
						Sleep, 20
					}
				}
				else
				{
					showMsgWithLineNumber("두 번째 창에서 Button5는 활성화되지 않았습니다. 대기 중...", A_LineNumber)
				}
			}
		}
	}
	else
	{
		showMsgWithLineNumber("연결 대화상자가 열리지 않았습니다. 대기 후 첫 번째 창 확인.", A_LineNumber)
		Sleep, 20  ; 연결 대화상자가 열리지 않으면 대기 후 다시 첫 번째 창 상태를 확인
	}
}


; 메세지 박스를 줄 번호와 함께 출력하는 함수 (툴팁 버전)
showMsgWithLineNumber(msg, lineNumber) {
	global lastMessage, lastLineNumber
	global lastOutputTime, timeLimit
	
	if (!IsSet(lastOutputTime))
	{
		lastOutputTime = 0
		timeLimit = 500
	}
	
	
	; 현재 메시지와 줄 번호가 이전 출력한 것과 동일한지 확인
	if (msg = lastMessage && lineNumber = lastLineNumber)
	{
			return  ; 동일하면 로그 기록을 건너뛰고 함수 종료
	}
	else
	{
		; 최근 출력한 메시지와 줄 번호를 업데이트
		lastMessage := msg
		lastLineNumber := lineNumber
		
		; MsgBox, % "실행 줄 번호: " lineNumber "`n" msg
		
		while (A_TickCount - lastOutputTime < timeLimit)
		{
			Sleep, (A_TickCount - lastOutputTime)
		}
		; 로그 파일에 기록
		FileAppend, % "실행 줄 번호: " lineNumber "`n" msg "`n", debug_log.txt
		lastOutputTime := A_TickCount
		; Sleep, 100
		; 콘솔 출력 예 (디버그 콘솔)
		; OutputDebug, % "실행 줄 번호: " lineNumber "`n" msg
	}
}
