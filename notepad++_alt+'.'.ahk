#Persistent  ; ��ũ��Ʈ�� ������� �ʰ� ��� ����ǵ��� ����
#SingleInstance Force  ; ���� ��ũ��Ʈ�� ����� ���, ���� �ν��Ͻ��� �����ϰ� ���ο� �ν��Ͻ��� ����

global count := 0  ; Ű �Է� Ƚ�� ���� (0 ~ 4 �ݺ�)
global threshold := 5  ; �ִ� ī��Ʈ �� (5�� �Է� �� 0���� �ʱ�ȭ)
winTitle := "ahk_class Notepad++"  ; Notepad++������ �۵��ϵ��� ����

; Alt + NumPad '.' ���� (Notepad++������ ���� �Է� ����, �ٸ� ���α׷������� ���� ��� ����)
!NumpadDot::
    if WinActive(winTitle) {
	count := (count + 1) mod threshold  ; 0~4���� �ݺ�
	ToolTip, ���� ī��Ʈ: %count%  ; ���� ī��Ʈ ���� ǥ��

	; count ���� �´� NumPad Ű ����
	keyToSend := "Numpad" (count + 1)

	; Alt + NumpadX �Է�
	Send, {Alt Down}{%keyToSend%}{Alt Up}

	return  ; ? Notepad++������ ���� �Է� ���� �� ����
    }
    else {
	; �ٸ� ���α׷������� Alt + NumPad '.' �Է��� ���������� �����ϵ��� ����
	Send, {Alt Down}{NumpadDot}{Alt Up}
    }
return

; ���� ���� ��ƾ (���� ȣ�� �� ����)
RemoveToolTip:
    ToolTip  ; ������ �� ������ �����Ͽ� ȭ�鿡�� ����
return
