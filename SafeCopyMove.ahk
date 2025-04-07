#Requires AutoHotkey v2.0

; === GUI 생성 ===
myGui := Gui("+AlwaysOnTop +Resize", "SafeFolderSwap")

myGui.Add("GroupBox", "w400 h100 Section", "폴더 경로 설정")
myGui.Add("Text", "x10 y30", "삭제할 폴더 경로:")
deleteEdit := myGui.Add("Edit", "x150 y25 w200 vDeleteEdit")
myGui.Add("Button", "x360 y25", "찾아보기").OnEvent("Click", (*) => BrowseFolder(deleteEdit))

myGui.Add("Text", "x10 y60", "복사할 폴더 경로:")
copyEdit := myGui.Add("Edit", "x150 y55 w200 vCopyEdit")
myGui.Add("Button", "x360 y55", "찾아보기").OnEvent("Click", (*) => BrowseFolder(copyEdit))

myGui.Add("Button", "x10 y120 w100", "▶ 실행").OnEvent("Click", (*) => ExecuteSwap(deleteEdit.Value, copyEdit.Value))
statusText := myGui.Add("Text", "x120 y125 w300 cBlue vStatusText", "")

myGui.OnEvent("Size", (*) => GuiResized(myGui))
myGui.Show()

; === 함수 정의 ===
BrowseFolder(targetEdit) {
    path := FileSelect("Folder", "폴더 선택")
    if path {
        targetEdit.Value := path
    } else {
        MsgBox "폴더 선택이 취소되었습니다."
    }
}

ExecuteSwap(deletePath, copySource) {
    global statusText

    if !DirExist(deletePath) {
        statusText.Value := "❌ 삭제할 폴더가 존재하지 않음!"
        MsgBox "삭제할 폴더가 존재하지 않음: " . deletePath
        return
    }

    if !DirExist(copySource) {
        statusText.Value := "❌ 복사할 폴더가 존재하지 않음!"
        MsgBox "복사할 폴더가 존재하지 않음: " . copySource
        return
    }

    if !FileRecycle(deletePath) {
        statusText.Value := "⚠ 삭제 실패: " . deletePath
        MsgBox "폴더 삭제 실패: " . deletePath
        return
    }

    Sleep(500)

    if DirCopy(copySource, deletePath, true) {
        statusText.Value := "✅ 삭제 후 복사 완료!"
        MsgBox "폴더 복사 성공: " . copySource . " → " . deletePath
    } else {
        statusText.Value := "⚠ 복사 중 오류 발생!"
        MsgBox "폴더 복사 실패: " . copySource . " → " . deletePath
    }
}

GuiResized(gui) {
    hwnd := gui.Hwnd
    rect := Buffer(16) ; 16바이트 버퍼 생성
    DllCall("GetClientRect", "ptr", hwnd, "ptr", rect)
    guiWidth := NumGet(rect, 8, "int") ; rect.right 값

    gui["DeleteEdit"].Move(, , guiWidth - 120) ; Edit 컨트롤 너비 조정
    gui["CopyEdit"].Move(, , guiWidth - 120)
    gui["StatusText"].Move(, , guiWidth - 20) ; 상태 텍스트 너비 조정
}
