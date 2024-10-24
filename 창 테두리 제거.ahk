; DllCall을 사용해 DWM을 통해 창의 테두리를 조정하는 스크립트
!F1::
    WinGet, hWnd, ID, A  ; 현재 활성 창의 핸들을 얻습니다.
    WinGet, Style, Style, ahk_id %hWnd% ; 현재 창의 스타일을 가져옵니다.

    ; WS_BORDER와 WS_DLGFRAME 비트를 확인합니다.
    if (Style & 0x00C00000) {
        ; 테두리가 있으면 없앱니다 (DWM을 사용).
        DllCall("dwmapi\DwmExtendFrameIntoClientArea", "ptr", hWnd, "int64P", -1)
    } else {
        ; 테두리가 없으면 복구합니다 (원래 상태로).
        DllCall("dwmapi\DwmExtendFrameIntoClientArea", "ptr", hWnd, "int64P", 0)
    }

    ; 창을 갱신합니다.
    WinMove, ahk_id %hWnd%, , , , , , 
return
