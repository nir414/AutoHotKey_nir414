#Persistent  ; ��ũ��Ʈ�� ��� ����ǵ��� ����
SetTitleMatchMode, 2  ; â ������ �κ������� ��Ī�� �� �ֵ��� ����

; ù ��° â�� ã�� (â ������ �Ϻθ� ��Ī)
IfWinExist, SerialPortMon
{
	; ���� ����
	while (true)  ; ���� ������ ��� ������ ��ư ���¸� Ȯ���ϰ� Ŭ��
	{
		if (!WinExist("SerialPortMon"))
		{
			showMsgWithLineNumber("SerialPortMon â�� �������� �ʾƼ� ���α׷��� �����մϴ�.", A_LineNumber)
			ExitApp  ; ù ��° â�� ������ ���α׷��� ����
		}
		; â�� Ȱ��ȭ�Ǿ� �ִ��� Ȯ��
		IfWinActive, SerialPortMon  ; "SerialPortMon"���� �����ϴ� â�� Ȱ��ȭ�� â���� �ν�
		{
			; ù ��° â�� "Connect" ��ư ���¸� Ȯ��
			ControlGet, buttonStatus, Enabled,, Button1, SerialPortMon
			ControlGetText, buttonText, Button1, SerialPortMon
			
			; ��ư �ؽ�Ʈ�� "Connect"�̸� Ŭ��
			if (buttonText = "Connect")
			{
				ControlClick, Button1, SerialPortMon
				showMsgWithLineNumber("ù ��° â�� 'Connect' ��ư�� Ŭ���߽��ϴ�.", A_LineNumber)
				Sleep, 20  ; Ŭ�� �� ��� ���
				checkAndClickSecondWindow()  ; ���� ���� ���� ��ȭ���� Ȯ���ϰ� ��ư Ŭ��
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
					showMsgWithLineNumber("ù ��° â�� ��ư �ؽ�Ʈ�� '" buttonText "'�Դϴ�. ��� ��...", A_LineNumber)
					Sleep, 20  ; ��� �� �ٽ� Ȯ��
				}
			}


		}
		else
		{
			showMsgWithLineNumber("ù ��° â�� Ȱ��ȭ���� �ʾҽ��ϴ�. ��� ��...", A_LineNumber)
			Sleep, 20  ; â�� Ȱ��ȭ���� ������ ��� �� �ٽ� Ȯ��
		}
	}
}
else
{
	showMsgWithLineNumber("ù ��° â�� ã�� �� �����ϴ�.", A_LineNumber)
}


   
; �� ��° â�� Ȯ���ϰ� ��ư�� Ŭ���ϴ� �Լ�
checkAndClickSecondWindow() {
	; ���� ���� ���� ��ȭ���� Ȯ�� (ahk_class #32770)
	IfWinExist, ahk_class #32770
	{
		WinActivate  
		showMsgWithLineNumber("�� ��° â�� ���Ƚ��ϴ�. 'Connect' ��ư�� Ŭ���Ϸ��� �մϴ�.", A_LineNumber)

		; �� ��° â�� ���� ���� �� ����ؼ� ��ư�� Ŭ��
		while (WinExist("ahk_class #32770"))  ; 2��° â�� �����ϴ� ���� �ݺ�
		{
			; �� ��° â���� "Connect" ��ư Ŭ�� (Button5)
			ControlGetText, buttonText, Button5, ahk_class #32770
			if (buttonText = "Connect")
			{
				ControlClick, Button5, ahk_class #32770  ; �� ��° â���� "Connect" ��ư Ŭ��
				showMsgWithLineNumber("�� ��° â���� 'Connect' ��ư�� Ŭ���߽��ϴ�.", A_LineNumber)
				Sleep, 20  ; Ŭ�� �� ��� ���
			}
			else
			{
				showMsgWithLineNumber("�� ��° â���� ��ư �ؽ�Ʈ�� '" buttonText "'�Դϴ�. ��� ��...", A_LineNumber)
				Sleep, 20
				break  ; �� ��° â���� ��ư �ؽ�Ʈ�� "Connect"�� �ƴϸ� ���� Ż��
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
	; ���� ��� ��
	MsgBox, % "���� �� ��ȣ: " lineNumber "`n" msg

	; Tooltip, % "���� �� ��ȣ: " lineNumber "`n" msg
	; Sleep, 500  ; 2�ʰ� ������ ȭ�鿡 ǥ��
	; Tooltip  ; ������ �ݽ��ϴ�.
	
	; �α� ���Ͽ� ����ϴ� ��
	FileAppend, % "���� �� ��ȣ: " lineNumber "`n" msg "`n", debug_log.txt
	; �ܼ� ��� �� (����� �ܼ�)
	; OutputDebug, % "���� �� ��ȣ: " lineNumber "`n" msg
}
