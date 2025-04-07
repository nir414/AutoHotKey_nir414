#Requires AutoHotkey v2.0
; 프로그램명: SafeFolderSwap (v2 버전)

; === GUI 생성 ===
myGui := Gui("+AlwaysOnTop", "SafeFolderSwap")

myGui.Add("Text", , "삭제할 폴더 경로:")
deleteEdit := myGui.Add("Edit", "w300")
myGui.Add("Button", "yp x+5", "찾아보기").OnEvent("Click", (*) => BrowseFolder(deleteEdit))

myGui.Add("Text", , "복사할 폴더 경로:")
copyEdit := myGui.Add("Edit", "w300")
myGui.Add("Button", "yp x+5", "찾아보기").OnEvent("Click", (*) => BrowseFolder(copyEdit))

myGui.Add("Button", "w100 Section", "▶ 실행").OnEvent("Click", (*) => ExecuteSwap(deleteEdit.Value, copyEdit.Value))
statusText := myGui.Add("Text", "xs w400 cBlue", "")

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

    ; 디버깅 메시지 추가
    MsgBox "ExecuteSwap 함수 호출됨!"

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

    ; 폴더 삭제 (휴지통으로 이동)
    if !FileRecycle(deletePath) {
        statusText.Value := "⚠ 삭제 실패: " . deletePath
        MsgBox "폴더 삭제 실패: " . deletePath
        return
    }

    Sleep(500)

    ; 폴더 복사 (DirCopy)
    if DirCopy(copySource, deletePath, true) {
        statusText.Value := "✅ 삭제 후 복사 완료!"
        MsgBox "폴더 복사 성공: " . copySource . " → " . deletePath
    } else {
        statusText.Value := "⚠ 복사 중 오류 발생!"
        MsgBox "폴더 복사 실패: " . copySource . " → " . deletePath
    }
}
