#Persistent  ; 스크립트가 계속 실행되도록 유지
SetTitleMatchMode, 2  ; 창 제목을 부분적으로 매칭할 수 있도록 설정

; 첫 번째 창을 찾기 (창 제목의 일부만 매칭)
IfWinExist, SerialPortMon
{
	; 무한 루프
	while (true)  ; 무한 루프를 계속 돌려서 버튼 상태를 확인하고 클릭
	{
		if (!WinExist("SerialPortMon"))
		{
			showMsgWithLineNumber("SerialPortMon 창이 존재하지 않아서 프로그램을 종료합니다.", A_LineNumber)
			ExitApp  ; 첫 번째 창이 없으면 프로그램을 종료
		}
		; 창이 활성화되어 있는지 확인
		IfWinActive, SerialPortMon  ; "SerialPortMon"으로 시작하는 창을 활성화된 창으로 인식
		{
			; 첫 번째 창의 "Connect" 버튼 상태를 확인
			ControlGet, buttonStatus, Enabled,, Button1, SerialPortMon
			ControlGetText, buttonText, Button1, SerialPortMon
			
			; 버튼 텍스트가 "Connect"이면 클릭
			if (buttonText = "Connect")
			{
				ControlClick, Button1, SerialPortMon
				showMsgWithLineNumber("첫 번째 창의 'Connect' 버튼을 클릭했습니다.", A_LineNumber)
				Sleep, 20  ; 클릭 후 잠시 대기
				checkAndClickSecondWindow()  ; 새로 열린 연결 대화상자 확인하고 버튼 클릭
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
					showMsgWithLineNumber("첫 번째 창의 버튼 텍스트는 '" buttonText "'입니다. 대기 중...", A_LineNumber)
					Sleep, 20  ; 대기 후 다시 확인
				}
			}


		}
		else
		{
			showMsgWithLineNumber("첫 번째 창이 활성화되지 않았습니다. 대기 중...", A_LineNumber)
			Sleep, 20  ; 창이 활성화되지 않으면 대기 후 다시 확인
		}
	}
}
else
{
	showMsgWithLineNumber("첫 번째 창을 찾을 수 없습니다.", A_LineNumber)
}


   
; 두 번째 창을 확인하고 버튼을 클릭하는 함수
checkAndClickSecondWindow() {
	; 새로 열린 연결 대화상자 확인 (ahk_class #32770)
	IfWinExist, ahk_class #32770
	{
		WinActivate  
		showMsgWithLineNumber("두 번째 창이 열렸습니다. 'Connect' 버튼을 클릭하려고 합니다.", A_LineNumber)

		; 두 번째 창이 열려 있을 때 계속해서 버튼을 클릭
		while (WinExist("ahk_class #32770"))  ; 2번째 창이 존재하는 동안 반복
		{
			; 두 번째 창에서 "Connect" 버튼 클릭 (Button5)
			ControlGetText, buttonText, Button5, ahk_class #32770
			if (buttonText = "Connect")
			{
				ControlClick, Button5, ahk_class #32770  ; 두 번째 창에서 "Connect" 버튼 클릭
				showMsgWithLineNumber("두 번째 창에서 'Connect' 버튼을 클릭했습니다.", A_LineNumber)
				Sleep, 20  ; 클릭 후 잠시 대기
			}
			else
			{
				showMsgWithLineNumber("두 번째 창에서 버튼 텍스트는 '" buttonText "'입니다. 대기 중...", A_LineNumber)
				Sleep, 20
				break  ; 두 번째 창에서 버튼 텍스트가 "Connect"가 아니면 루프 탈출
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
	; 툴팁 사용 예
	MsgBox, % "실행 줄 번호: " lineNumber "`n" msg

	; Tooltip, % "실행 줄 번호: " lineNumber "`n" msg
	; Sleep, 500  ; 2초간 툴팁을 화면에 표시
	; Tooltip  ; 툴팁을 닫습니다.
	
	; 로그 파일에 기록하는 예
	FileAppend, % "실행 줄 번호: " lineNumber "`n" msg "`n", debug_log.txt
	; 콘솔 출력 예 (디버그 콘솔)
	; OutputDebug, % "실행 줄 번호: " lineNumber "`n" msg
}
