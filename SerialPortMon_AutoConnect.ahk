#Persistent  ; ��ũ��Ʈ�� ��� ����ǵ��� ����
SetTitleMatchMode, 1  ; â ������ �κ������� ��Ī�� �� �ֵ��� ����


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
		; �ڵ� ���� �ѹ� ����
		if (!IsSet(hwnd) || hwnd = 0)
		{
			hwnd1 := WinExist()
			WinGetTitle, title, ahk_id hwnd1
			ControlGet, buttonStatus, Enabled,, Button1, hwnd1
			ControlGetText, buttonText, Button1, hwnd1
			showMsgWithLineNumber("SerialPortMon â�� ã�ҽ��ϴ�. �ڵ�: '" title "'", A_LineNumber)
			; WinActivate, ahk_id %hwnd1%  ; "SerialPortMon" â�� Ȱ��ȭ
		}
		else
		{
			checkAndClickSecondWindow()
			
			IfWinActive, SerialPortMon  ; "SerialPortMon"���� �����ϴ� â�� Ȱ��ȭ�� â���� �ν�
			{
				; ù ��° â�� "Connect" ��ư ���¸� Ȯ��
				ControlGet, buttonStatus, Enabled,, Button1, hwnd1
				ControlGetText, buttonText, Button1, hwnd1
				
				if (buttonStatus = 1)
				{
					if (buttonText = "Connect")
					{
						ControlClick, Button1, SerialPortMon
						showMsgWithLineNumber("ù ��° â�� 'Connect' ��ư�� Ŭ���߽��ϴ�.", A_LineNumber)
						Sleep, 20  ; Ŭ�� �� ��� ���
					}
					else
					{
						; ��ư�� "Close" ������ �� ���
						if (buttonText = "Close")
						{
							showMsgWithLineNumber("ù ��° â�� ��ư�� 'Close' �����Դϴ�. ��� ��...", A_LineNumber)
							Sleep, 20  ; ��� �� �ٽ� Ȯ��
						}
						else
						{
							showMsgWithLineNumber("ù ��° â�� Button1 �ؽ�Ʈ�� '" buttonText "'�Դϴ�. ��� ��...", A_LineNumber)
							Sleep, 20  ; ��� �� �ٽ� Ȯ��
						}
					}
				}
				else
				{
					showMsgWithLineNumber("ù ��° â�� Button1 �ؽ�Ʈ�� '" buttonText "'�Դϴ�. ��� ��...", A_LineNumber)
					Sleep, 20  ; ��� �� �ٽ� Ȯ��
				}
			}
			else
			{
				showMsgWithLineNumber("Button1�� Ȱ��ȭ���� �ʾҽ��ϴ�. ��� ��...", A_LineNumber)
				Sleep, 20
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
	IfWinExist, ahk_exe SerialPortMon.exe ahk_pid 10432 ; â�� ���� Ȯ��
	{
		; �ڵ� ���� �ѹ� ����
		If (!IsSet(hwnd_ahk_class) || hwnd_ahk_class = 0)
		{
			hwnd_ahk_class := WinExist("���� ��ȭ����")
		}
		
		If !(!IsSet(hwnd_ahk_class) || hwnd_ahk_class = 0)
		{
			; WinActivate
			WinActivate, ahk_id %hwnd_ahk_class%
			showMsgWithLineNumber("�� ��° â�� ���Ƚ��ϴ�. 'Connect' ��ư�� Ŭ���Ϸ��� �մϴ�.", A_LineNumber)

			; �� ��° â�� ���� ���� �� ����ؼ� ��ư�� Ŭ��
			while (WinExist("���� ��ȭ����"))  ; 2��° â�� �����ϴ� ���� �ݺ�
			{
				WinActivate, ahk_id %hwnd_ahk_class%
				; �� ��° â���� "Connect" ��ư Ŭ�� (Button5)
				; ControlGetText, buttonText, Button5, ahk_class #32770
				ControlGet, buttonStatus, Enabled,, Button5, ahk_id %hwnd_ahk_class%
				ControlGetText, buttonText, Button5, ahk_id %hwnd_ahk_class%
				If (buttonStatus = 1)
				{
					if (buttonText = "Connect")
					{
						; ControlClick, Button5, ahk_class #32770
						ControlClick, Button5, ahk_id %hwnd_ahk_class%
						showMsgWithLineNumber("�� ��° â���� 'Connect' ��ư�� Ŭ���߽��ϴ�.", A_LineNumber)
						Sleep, 20  ; Ŭ�� �� ��� ���
					}
					else
					{
						showMsgWithLineNumber("�� ��° â���� ��ư �ؽ�Ʈ�� '" buttonText "'�Դϴ�. ��� ��...", A_LineNumber)
						Sleep, 20
					}
				}
				else
				{
					showMsgWithLineNumber("�� ��° â���� Button5�� Ȱ��ȭ���� �ʾҽ��ϴ�. ��� ��...", A_LineNumber)
				}
			}
		}
	}
	else
	{
		showMsgWithLineNumber("���� ��ȭ���ڰ� ������ �ʾҽ��ϴ�. ��� �� ù ��° â Ȯ��.", A_LineNumber)
		Sleep, 20  ; ���� ��ȭ���ڰ� ������ ������ ��� �� �ٽ� ù ��° â ���¸� Ȯ��
	}
}


; �޼��� �ڽ��� �� ��ȣ�� �Բ� ����ϴ� �Լ� (���� ����)
showMsgWithLineNumber(msg, lineNumber) {
	global lastMessage, lastLineNumber
	global lastOutputTime, timeLimit
	
	if (!IsSet(lastOutputTime))
	{
		lastOutputTime = 0
		timeLimit = 500
	}
	
	
	; ���� �޽����� �� ��ȣ�� ���� ����� �Ͱ� �������� Ȯ��
	if (msg = lastMessage && lineNumber = lastLineNumber)
	{
			return  ; �����ϸ� �α� ����� �ǳʶٰ� �Լ� ����
	}
	else
	{
		; �ֱ� ����� �޽����� �� ��ȣ�� ������Ʈ
		lastMessage := msg
		lastLineNumber := lineNumber
		
		; MsgBox, % "���� �� ��ȣ: " lineNumber "`n" msg
		
		while (A_TickCount - lastOutputTime < timeLimit)
		{
			Sleep, (A_TickCount - lastOutputTime)
		}
		; �α� ���Ͽ� ���
		FileAppend, % "���� �� ��ȣ: " lineNumber "`n" msg "`n", debug_log.txt
		lastOutputTime := A_TickCount
		; Sleep, 100
		; �ܼ� ��� �� (����� �ܼ�)
		; OutputDebug, % "���� �� ��ȣ: " lineNumber "`n" msg
	}
}
