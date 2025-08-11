#Persistent
SetBatchLines, -1
#UseHook On
SendMode, Input

toggleWalk := false
wDown := false
altDown := false
targetExe := "nightreign.exe"
currentExe := ""

; ─ GUI 초기화 ─
Gui, +AlwaysOnTop -SysMenu +ToolWindow -Caption -Theme
Gui, Margin, 4, 2
Gui, Font, s8, Consolas

Gui, Add, Text, vStatusText w100, ● 중지
Gui, Add, Text, vProcText w100, 프로세스: (알 수 없음)
Gui, Show, x10 y1010 NoActivate

SetTimer, WatchActiveWindow, 500

; ─ 상태 표시 갱신 함수 ─
UpdateDebug() {
	global wDown, altDown, toggleWalk, currentExe
	GuiControl,, StatusText, % (toggleWalk ? "● 이동" : "● 중지")
	GuiControl,, ProcText, % "프로세스: " . currentExe
}

; ─ 활성 창 감시 (ProcessName 캐싱) ─
WatchActiveWindow:
	WinGet, currentExe, ProcessName, A
	UpdateDebug()
return

; ─ 이동 시작 / 중단 ─
StartRunning() {
	global toggleWalk
	toggleWalk := true
	GuiControl,, StatusText, 상태: 이동 중
	UpdateDebug()
	Sleep, 10
	SendInput, {Alt down}
	Sleep, 10
	SendInput, {y down}
	Sleep, 10
	SendInput, {Alt up}
}

; ─ 자동 이동 중단 ─
StopRunning() {
	global toggleWalk
	toggleWalk := false
	GuiControl,, StatusText, 상태: 중지
	UpdateDebug()
}

; ─ 타겟 창 확인 ─
IsTargetWindow() {
	global targetExe
	WinGet, exeName, ProcessName, A
	altDown := false
	return (exeName = targetExe)
}


; ─ Alt 키 상태 추적 및 동작 토글 ─
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

; ─ WASD → YGHJ 매핑 ─
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
