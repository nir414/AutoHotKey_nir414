#Persistent  ; ��ũ��Ʈ�� ��� ����ǵ��� ����
SetTitleMatchMode, 3  ; â ������ �κ������� ��Ī�� �� �ֵ��� ����



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
		; �ڵ� ���� �ѹ� ����
		if (!IsSet(hwnd1) || hwnd1 = 0)
		{
			showMsgWithLineNumber("SerialPortMon â�� �ڵ��� �����ɴϴ�.", A_LineNumber)
			hwnd1 := WinExist("SerialPortMon")
			ControlGet, buttonStatus, Enabled,, Button1, ahk_id %hwnd1%
			ControlGetText, buttonText, Button1, ahk_id %hwnd1%
			; WinActivate, ahk_id %hwnd1%  ; "SerialPortMon" â�� Ȱ��ȭ
			if !(!IsSet(hwnd1) || hwnd1 = 0)
			{
				WinGetTitle, title, ahk_id %hwnd1%
				showMsgWithLineNumber("SerialPortMon â�� ã�ҽ��ϴ�. �ڵ�: '" . title . "'", A_LineNumber)
			}
		}
		else
		{
			checkAndClickSecondWindow()
			
			IfWinActive, ahk_id %hwnd1%  ; "SerialPortMon"���� �����ϴ� â�� Ȱ��ȭ�� â���� �ν�
			{
				; ù ��° â�� "Connect" ��ư ���¸� Ȯ��
				ControlGet, buttonStatus, Enabled,, Button1, ahk_id %hwnd1%
				ControlGetText, buttonText, Button1, ahk_id %hwnd1%
				
				if (buttonStatus = 1)
				{
					if (buttonText = "Connect")
					{
						ControlClick, Button1, ahk_id %hwnd1%
						showMsgWithLineNumber("ù ��° â�� 'Connect' ��ư�� Ŭ���߽��ϴ�.", A_LineNumber)
						Sleep, 200
					}
					else
					{
						; ��ư�� "Close" ������ �� ���
						if (buttonText = "Close")
						{
							showMsgWithLineNumber("ù ��° â�� ��ư�� 'Close' �����Դϴ�. ��� ��...", A_LineNumber)
						}
						else
						{
							showMsgWithLineNumber("ù ��° â�� Button1 �ؽ�Ʈ�� '" buttonText "'�Դϴ�. ��� ��...", A_LineNumber)
						}
					}
				}
				else
				{
					showMsgWithLineNumber("ù ��° â�� Button1 �ؽ�Ʈ�� '" buttonText "'�Դϴ�. ��� ��...", A_LineNumber)
				}
			}
			else
			{
				showMsgWithLineNumber("'" . title . "'�� Ȱ��ȭ���� �ʾҽ��ϴ�. ��� ��...", A_LineNumber)
			}
		}
	}
	else
	{
		showMsgWithLineNumber("SerialPortMon â�� �������� �ʾƼ� ���α׷��� �����մϴ�.", A_LineNumber)
		ExitApp  ; ù ��° â�� ������ ���α׷��� ����
	}
}


; ���� ��ȭ����
; ahk_class #32770
; ahk_exe SerialPortMon.exe
; ahk_pid 10432
; ahk_id 922960
; �� ��° â�� Ȯ���ϰ� ��ư�� Ŭ���ϴ� �Լ�
checkAndClickSecondWindow() {
	; ���� ���� ���� ��ȭ���� Ȯ�� (ahk_class #32770)
	; IfWinExist, ahk_exe SerialPortMon.exe ahk_pid 10432 ; â�� ���� Ȯ��
	IfWinExist, ���� ��ȭ����
	{
		; �ڵ� ���� �ѹ� ����
		If (!IsSet(hwnd2) || hwnd2 = 0)
		{
			hwnd2 := WinExist("���� ��ȭ����")
			WinGetTitle, title, ahk_id ahk_id %hwnd2%
			ControlGet, buttonStatus, Enabled,, Button1, ahk_id %hwnd2%
			ControlGetText, buttonText, Button1, ahk_id %hwnd2%
			showMsgWithLineNumber("SerialPortMon â�� ã�ҽ��ϴ�. �ڵ�: '" . title . "'", A_LineNumber)
		}
		
		If !(!IsSet(hwnd2) || hwnd2 = 0)
		{
			; WinActivate
			WinActivate, ahk_id %hwnd2%
			showMsgWithLineNumber("�� ��° â�� ���Ƚ��ϴ�. 'Connect' ��ư�� Ŭ���Ϸ��� �մϴ�.", A_LineNumber)

			; �� ��° â�� ���� ���� �� ����ؼ� ��ư�� Ŭ��
			while (WinExist("ahk_id " . hwnd2))  ; 2��° â�� �����ϴ� ���� �ݺ�
			{
				WinActivate, ahk_id %hwnd2%
				; �� ��° â���� "Connect" ��ư Ŭ�� (Button5)
				; ControlGetText, buttonText, Button5, ahk_class #32770
				ControlGet, buttonStatus, Enabled,, Button5, ahk_id %hwnd2%
				ControlGetText, buttonText, Button5, ahk_id %hwnd2%
				If (buttonStatus = 1)
				{
					if (buttonText = "Connect")
					{
						; ControlClick, Button5, ahk_class #32770
						ControlClick, Button5, ahk_id %hwnd2%
						showMsgWithLineNumber("�� ��° â���� 'Connect' ��ư�� Ŭ���߽��ϴ�.", A_LineNumber)
						Sleep, 200
					}
					else
					{
						showMsgWithLineNumber("�� ��° â���� ��ư �ؽ�Ʈ�� '" buttonText "'�Դϴ�. ��� ��...", A_LineNumber)
					}
				}
				else
				{
					showMsgWithLineNumber("�� ��° â���� Button5�� Ȱ��ȭ���� �ʾҽ��ϴ�. ��� ��...", A_LineNumber)
				}
			}
		}
	}
}


; �޼��� �ڽ��� �� ��ȣ�� �Բ� ����ϴ� �Լ� (���� ����)
showMsgWithLineNumber(msg, lineNumber) {
	global lastMessage, lastLineNumber
	global lastOutputTime, timeLimit
	global debugMode
	
	if (!IsSet(lastOutputTime))
	{
		lastOutputTime = 0
		timeLimit = 100
	}
	
	
	; �������� Ȯ��
	if (msg = lastMessage && lineNumber = lastLineNumber || debugMode = 0)
	{
			return  ; �����ϸ� �α� ����� �ǳʶٰ� �Լ� ����
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
