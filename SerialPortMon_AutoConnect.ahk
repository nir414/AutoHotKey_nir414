#Persistent  ; ��ũ��Ʈ�� ��� ����ǵ��� ����
SetTitleMatchMode, 2  ; â ������ �κ������� ��Ī�� �� �ֵ��� ����

; ù ��° â�� ã��
IfWinExist, SerialPortMon
{
	; ���� ����
	while (true)  ; ���� ������ ��� ������ ��ư ���¸� Ȯ���ϰ� Ŭ��
	{
		; â�� Ȱ��ȭ�Ǿ� �ִ��� Ȯ��
		IfWinActive, SerialPortMon
		{
			; ù ��° â�� "Connect" ��ư ���¸� Ȯ��
			ControlGet, buttonStatus, Enabled,, Button1, SerialPortMon
			ControlGetText, buttonText, Button1, SerialPortMon
			
			; ��ư �ؽ�Ʈ�� "Connect"�̸� Ŭ��
			if (buttonText = "Connect")
			{
				ControlClick, Button1, SerialPortMon
				;MsgBox, ù ��° â�� "Connect" ��ư�� Ŭ���߽��ϴ�.
				Sleep, 20  ; Ŭ�� �� ��� ���
				; ���� ���� ���� ��ȭ���� Ȯ���ϰ� ��ư Ŭ��
				checkAndClickSecondWindow()
				IfWinExist, SerialPortMon
				{
					ExitApp  ; ù ��° â�� ������ ���α׷��� ����
				}
			}
			else
			{
				; ��ư�� "Close" ������ �� ���
				if (buttonText = "Close")
				{
					;MsgBox, ù ��° â�� ��ư�� "Close" �����Դϴ�. ��� ��...
					Sleep, 20  ; ��� �� �ٽ� Ȯ��
				}
				else
				{
					;MsgBox, ù ��° â�� ��ư �ؽ�Ʈ�� "%buttonText%"�Դϴ�. ��� ��...
					Sleep, 20  ; ��� �� �ٽ� Ȯ��
				}
			}


		}
		else
		{
			;MsgBox, ù ��° â�� Ȱ��ȭ���� �ʾҽ��ϴ�. ��� ��...
			Sleep, 20  ; â�� Ȱ��ȭ���� ������ ��� �� �ٽ� Ȯ��
		}
	}
}
else
{
	;MsgBox, ù ��° â�� ã�� �� �����ϴ�.
}



; �� ��° â�� Ȯ���ϰ� ��ư�� Ŭ���ϴ� �Լ�
checkAndClickSecondWindow() {
	; ���� ���� ���� ��ȭ���� Ȯ�� (ahk_class #32770)
	IfWinExist, ahk_class #32770
	{
		WinActivate  
		;MsgBox, �� ��° â�� ���Ƚ��ϴ�. "Connect" ��ư�� Ŭ���Ϸ��� �մϴ�.

		; �� ��° â�� ���� ���� �� ����ؼ� ��ư�� Ŭ��
		while (WinExist("ahk_class #32770"))  ; 2��° â�� �����ϴ� ���� �ݺ�
		{
			; �� ��° â���� "Connect" ��ư Ŭ�� (Button5)
			ControlGetText, buttonText, Button5, ahk_class #32770
			if (buttonText = "Connect")
			{
				ControlClick, Button5, ahk_class #32770  ; �� ��° â���� "Connect" ��ư Ŭ��
				;MsgBox, �� ��° â���� "Connect" ��ư�� Ŭ���߽��ϴ�.
				Sleep, 20  ; Ŭ�� �� ��� ���
			}
			else
			{
				;MsgBox, �� ��° â���� ��ư �ؽ�Ʈ�� "%buttonText%"�Դϴ�. ��� ��...
				Sleep, 20
				break  ; �� ��° â���� ��ư �ؽ�Ʈ�� "Connect"�� �ƴϸ� ���� Ż��
			}
		}
	}
	else
	{
		;MsgBox, ���� ��ȭ���ڰ� ������ �ʾҽ��ϴ�. ��� �� ù ��° â Ȯ��.
		Sleep, 20  ; ���� ��ȭ���ڰ� ������ ������ ��� �� �ٽ� ù ��° â ���¸� Ȯ��
	}
}

