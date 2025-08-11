MsgBox, %A_AhkVersion%
; #Persistent
; SetTimer, CheckTabAndMouse, 10
; return

; CheckTabAndMouse:
;     MouseGetPos, mouseX, mouseY
;     if (mouseY < 200) {
;         MouseMove, mouseX, 200, 0 ; 마우스 Y좌표가 200 미만이면 200으로 이동
;     }
; return