#Persistent  ; 스크립트가 종료되지 않고 계속 실행되도록 설정
#SingleInstance Force  ; 같은 스크립트가 실행될 경우, 기존 인스턴스를 종료하고 새로운 인스턴스를 실행

global count := 0  ; 키 입력 횟수를 저장하는 변수 (초기값: 0)
global threshold := 5  ; 최대 카운트 값 (5번 입력 시 0으로 초기화)
winTitle := "ahk_class Notepad++"  ; 특정 프로그램 (Notepad++)에서만 작동하도록 설정

; Alt + NumPad '.' 감지 (Notepad++에서는 차단, 다른 프로그램에서는 원래 기능 유지)
!NumpadDot::
	if WinActive(winTitle) {
		count := (count + 1) mod threshold  ; 카운트 증가 (0~4까지 반복)
		ToolTip, 현재 카운트: %count%  ; 현재 카운트 값을 툴팁으로 표시

		; count 값에 따라 Alt + NumPad1~5 입력
		keyToSend := ""
		if (count == 0) {
			keyToSend := "Numpad1"
		} else if (count == 1) {
			keyToSend := "Numpad2"
		} else if (count == 2) {
			keyToSend := "Numpad3"
		} else if (count == 3) {
			keyToSend := "Numpad4"
		} else if (count == 4) {
			keyToSend := "Numpad5"
		}

		; Alt + NumpadX 입력
		if (keyToSend != "") {
			Send, {Alt Down}{%keyToSend%}{Alt Up}
		}
		return  ; ⭐ Notepad++에서는 원래 입력을 차단하고 여기서 종료
	}
	else {
		; 다른 프로그램에서는 Alt + NumPad '.' 입력이 정상적으로 동작하도록 함
		Send, {Alt Down}{NumpadDot}{Alt Up}
	}
return

; 툴팁 제거 루틴 (별도 호출 시 실행)
RemoveToolTip:
	ToolTip  ; 툴팁을 빈 값으로 설정하여 화면에서 제거
return
