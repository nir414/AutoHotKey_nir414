#Persistent
SetBatchLines, -1
#UseHook On
SendMode, Input

toggleWalk := false
wDown := false
altDown := false
targetExe := "nightreign.exe"
currentExe := ""

; �� GUI �ʱ�ȭ ��
Gui, +AlwaysOnTop -SysMenu +ToolWindow -Caption -Theme
Gui, Margin, 4, 2
Gui, Font, s8, Consolas

Gui, Add, Text, vStatusText w100, �� ����
Gui, Add, Text, vProcText w100, ���μ���: (�� �� ����)
Gui, Show, x10 y1010 NoActivate

SetTimer, WatchActiveWindow, 500

; �� ���� ǥ�� ���� �Լ� ��
UpdateDebug() {
	global wDown, altDown, toggleWalk, currentExe
	GuiControl,, StatusText, % (toggleWalk ? "�� �̵�" : "�� ����")
	GuiControl,, ProcText, % "���μ���: " . currentExe
}

; �� Ȱ�� â ���� (ProcessName ĳ��) ��
WatchActiveWindow:
	WinGet, currentExe, ProcessName, A
	UpdateDebug()
return

; �� �̵� ���� / �ߴ� ��
StartRunning() {
	global toggleWalk
	toggleWalk := true
	GuiControl,, StatusText, ����: �̵� ��
	UpdateDebug()
	Sleep, 10
	SendInput, {Alt down}
	Sleep, 10
	SendInput, {y down}
	Sleep, 10
	SendInput, {Alt up}
}

; �� �ڵ� �̵� �ߴ� ��
StopRunning() {
	global toggleWalk
	toggleWalk := false
	GuiControl,, StatusText, ����: ����
	UpdateDebug()
}

; �� Ÿ�� â Ȯ�� ��
IsTargetWindow() {
	global targetExe
	WinGet, exeName, ProcessName, A
	altDown := false
	return (exeName = targetExe)
}


; �� Alt Ű ���� ���� �� ���� ��� ��
~*Alt::
	if !IsTargetWindow()
		return
	altDown := true
	if toggleWalk
		StopRunning()
	else
		if (wDown)
			StartRunning()
	UpdateDebug()
return

~*Alt up::
	if !IsTargetWindow()
		return
	altDown := false
	UpdateDebug()
return

; �� WASD �� YGHJ ���� ��
~*w::
	if !IsTargetWindow()
		return
	wDown := true
	if toggleWalk
		StopRunning()
	else
		if (altDown)
			StartRunning()
	SendInput, {y down}
	UpdateDebug()
return

~*w up::
	if !IsTargetWindow()
		return
	wDown := false
	if !toggleWalk
		SendInput, {y up}
	UpdateDebug()
return

~*a::
	if IsTargetWindow()
	SendInput, {g down}
return

~*a up::
	if IsTargetWindow()
	SendInput, {g up}
return

~*s::
	if !IsTargetWindow()
		return
	if toggleWalk
		StopRunning()
		SendInput, {y Down}
		SendInput, {y up}
	SendInput, {h down}
	UpdateDebug()
return

~*s up::
	if IsTargetWindow()
	SendInput, {h up}
return

~*d::
	if IsTargetWindow()
	SendInput, {j down}
return

~*d up::
	if IsTargetWindow()
	SendInput, {j up}
return
