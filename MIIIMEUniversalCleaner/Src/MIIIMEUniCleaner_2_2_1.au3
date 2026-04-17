#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=App.ico
#AutoIt3Wrapper_Outfile=..\MIIIMEUniCleaner.exe
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Description=MIIIME Universal Cleaner
#AutoIt3Wrapper_Res_Fileversion=2.2.1.0
#AutoIt3Wrapper_Res_ProductName=MIIIME Universal Cleaner
#AutoIt3Wrapper_Res_ProductVersion=2.2.1.0
#AutoIt3Wrapper_Res_LegalCopyright=MIIIME
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

; =================================================================================================
; MIIIME Universal Cleaner
; © 2026 MIIIME  /  Version 2.2.1
;
; 목적  : 지정한 경로(하위 경로)의 파일/폴더를 선택적으로 삭제하는 클리닝 도구.
;         MHL(미메런쳐)과 연동하거나, 독립 실행하여 사용합니다.
;
; ─────────────────────────────────────────────────────────────────────────────
; 실행 모드 결정 순서
; ─────────────────────────────────────────────────────────────────────────────
; 1. OwnIni (MIIIMEUniCleaner.ini) 는 어떤 모드에서도 반드시 존재해야 합니다.
;    없으면 에러 메시지 후 즉시 종료합니다.
;
; 2. OwnIni 의 [CleanupExclude] 또는 [CleanupDelete] 에 실제 경로 항목이
;    1개 이상 있으면 → [독립 모드]
;    해당 항목을 그대로 실행합니다.
;
; 3. OwnIni 에 두 섹션 모두 항목이 없으면 → *_M.ini 탐색 → [연동 모드]
;    - *_M.ini 가 0개 : 에러 메시지 후 종료
;    - *_M.ini 가 1개 : 해당 ini 의 [CleanupExclude] / [CleanupDelete] 로 클리닝.
;    - *_M.ini 가 2개 이상 : 에러 메시지 후 종료
;
; 4. 연동 모드에서는 *_M.ini 의 [Directories] 를 읽어 {Dat}, {Run} 등
;    런처 전용 경로 매크로를 계산합니다.
;
; ─────────────────────────────────────────────────────────────────────────────
; 실행 조건 (독립/연동 공통)
; ─────────────────────────────────────────────────────────────────────────────
; 각 섹션은 항목이 1개 이상 있으면 무조건 실행합니다.
; Enable, SmartSkip 등 제어 키는 항목으로 간주하지 않습니다.
; (런처의 SmartSkip 등 조건 키는 런처 자체에서 판단 후 클리너를 호출하는 구조)
; =================================================================================================

#NoTrayIcon
#include <File.au3>
#include <FileConstants.au3>
#include <GUIConstantsEx.au3>
#include <ButtonConstants.au3>
#include <WindowsConstants.au3>

Opt('MustDeclareVars', 1)

; =================================================================================================
; [Constants] 에러 코드
; =================================================================================================
Global Const $ERR_INI_NOT_FOUND  = 1010
Global Const $ERR_MULTI_M_INI    = 1011
Global Const $ERR_NO_M_INI       = 1012
Global Const $ERR_FILE_DELETE    = 2004

; =================================================================================================
; [Theme] MIIIME 다크·각진 테마 함수 블록  (MIIIME_DarkSquareTheme_Guide_1_4 준거)
; =================================================================================================

; Win11 DWM 둥근 모서리 → 각지게 강제 설정
Func _ApplySquareCorners($hWnd)
    DllCall("dwmapi.dll", "long", "DwmSetWindowAttribute", _
        "hwnd",  $hWnd, _
        "dword", 33,   _
        "dword*", 1,   _
        "dword", 4)
EndFunc

; 컨트롤 UxTheme(Fluent/라운딩 효과) 제거 → 각진 클래식 스타일 강제
Func _DisableTheme($hCtrl)
    DllCall("uxtheme.dll", "int", "SetWindowTheme", _
        "hwnd", $hCtrl, _
        "wstr", "",     _
        "wstr", "")
EndFunc

; 다크·각진 메시지 창  ($iType: 16=에러, 48=경고, 64=정보)
Func _MsgBoxSquare($iType, $sTitle, $sText)
    Local $hMsgGUI = GUICreate($sTitle, 400, 170, -1, -1, _
        BitOR($WS_CAPTION, $WS_POPUP), $WS_EX_TOPMOST)
    GUISetFont(10, 400, 0, "", $hMsgGUI)   ; 창 핸들 명시 — Label에 GUICtrlSetFont 절대 금지
    GUISetBkColor(0x212121, $hMsgGUI)      ; 창 핸들 명시
    _ApplySquareCorners($hMsgGUI)

    Local $iTextColor = 0xE0E0E0
    If $iType = 16 Then $iTextColor = 0xFF5252
    If $iType = 48 Then $iTextColor = 0xFFD740

    Local $lblMsg = GUICtrlCreateLabel($sText, 20, 20, 360, 90)
    GUICtrlSetColor($lblMsg, $iTextColor)
    GUICtrlSetBkColor($lblMsg, 0x212121)
    ; GUICtrlSetFont 호출 금지 — 리페인트 시 WM_CTLCOLORSTATIC 색상 조회 실패 원인

    Local $btnOk = GUICtrlCreateButton("OK", 160, 125, 80, 28)
    _DisableTheme(GUICtrlGetHandle($btnOk))
    ; GUICtrlSetColor / GUICtrlSetFont 호출 금지 — 테마 재적용으로 둥근 버튼 원인
    GUICtrlSetState($btnOk, $GUI_FOCUS)

    GUISetState(@SW_SHOW, $hMsgGUI)
    While 1
        Local $mMsg = GUIGetMsg()
        If $mMsg = $GUI_EVENT_CLOSE Or $mMsg = $btnOk Then ExitLoop
    WEnd
    GUIDelete($hMsgGUI)
EndFunc

; =================================================================================================
; [Global] Context 객체 생성
; =================================================================================================
Global $g_oCtx = ObjCreate("Scripting.Dictionary")
If Not IsObj($g_oCtx) Then
    MsgBox(16, "Fatal Error", "Failed to create context object (Scripting.Dictionary).")
    Exit
EndIf

; =================================================================================================
; 메인 흐름 시작
; =================================================================================================
_Init_Context()
_Load_Config()

; 관리자 권한 재실행
If $g_oCtx.Item("ForceAdmin") And Not IsAdmin() Then
    Local $sParams = ""
    If $CmdLine[0] > 0 Then
        Local $iCli
        For $iCli = 1 To $CmdLine[0]
            $sParams &= ' "' & $CmdLine[$iCli] & '"'
        Next
    EndIf
    ShellExecute(@ScriptFullPath, $sParams, @ScriptDir, "runas")
    Exit
EndIf

; --debug 커맨드라인 처리
If $CmdLine[0] > 0 Then
    Local $iCli2
    For $iCli2 = 1 To $CmdLine[0]
        If $CmdLine[$iCli2] = "--debug" Then
            $g_oCtx.Item("LogLevel") = 2
        EndIf
    Next
EndIf

; 로그 세션 시작
_Log("CORE", "========== [Session Started] ==========", "INFO")
_Log("CORE", "[Init] Mode: " & $g_oCtx.Item("RunMode"), "INFO")
_Log("CORE", "[Init] OwnIni: " & $g_oCtx.Item("OwnIniFile"), "INFO")
_Log("CORE", "[Init] CleanupIni: " & $g_oCtx.Item("CleanupIniFile"), "INFO")

; 클리닝 실행
_Run_Cleanup()

; 로그 세션 종료
_Log("CORE", "========== [Session Terminated] ==========", "INFO")

; 완료 메시지
If $g_oCtx.Item("ShowFinishMsg") Then
    _MsgBoxSquare(64, $g_oCtx.Item("AppName"), $g_oCtx.Item("FinishText"))
EndIf

Exit

; =================================================================================================
; [1] 초기화 함수
; =================================================================================================

; -------------------------------------------------------------------------------------------------
; Function: _Init_Context
; 실행 파일명 기반 경로 설정 및 실행 모드(독립/연동) 결정
;
; - OwnIni(MIIIMEUniCleaner.ini)가 없으면 즉시 에러 종료.
; - OwnIni 의 [CleanupExclude] / [CleanupDelete] 에 경로 항목이 있으면 독립 모드.
; - 항목이 없으면 *_M.ini 를 탐색하여 연동 모드 결정.
; -------------------------------------------------------------------------------------------------
Func _Init_Context()
    ; ── 기본 경로 ──
    $g_oCtx.Item("DirBase") = @ScriptDir
    Local $sBaseName = StringRegExpReplace(@ScriptFullPath, "\.[^.]*$", "")
    $g_oCtx.Item("OwnIniFile") = $sBaseName & ".ini"
    $g_oCtx.Item("LogFile")    = $sBaseName & ".log"

    ; ── OwnIni 필수 존재 확인 ──
    If Not FileExists($g_oCtx.Item("OwnIniFile")) Then
        _MsgBoxSquare(16, "Error", "Configuration file not found:" & @CRLF & _
            $g_oCtx.Item("OwnIniFile") & @CRLF & "(Code: " & $ERR_INI_NOT_FOUND & ")")
        Exit
    EndIf

    ; ── 기본값 초기화 ──
    $g_oCtx.Item("RunMode")        = "Standalone"
    $g_oCtx.Item("CleanupIniFile") = $g_oCtx.Item("OwnIniFile")

    ; ── OwnIni 의 CleanupExclude / CleanupDelete 에 실제 항목이 있는지 확인 ──
    Local $bOwnHasItems = _HasCleanupEntries($g_oCtx.Item("OwnIniFile"))

    If $bOwnHasItems Then
        ; ── 독립 모드: OwnIni 의 항목 사용 ──
        $g_oCtx.Item("RunMode")        = "Standalone"
        $g_oCtx.Item("CleanupIniFile") = $g_oCtx.Item("OwnIniFile")
    Else
        ; ── 연동 모드 탐색: 동일 폴더의 *_M.ini 검색 ──
        Local $aFound[20]
        Local $iFoundCount = 0
        Local $hSearch = FileFindFirstFile(@ScriptDir & "\*_M.ini")
        If $hSearch <> -1 Then
            While 1
                Local $sFound = FileFindNextFile($hSearch)
                If @error Then ExitLoop
                $aFound[$iFoundCount] = $sFound
                $iFoundCount += 1
                If $iFoundCount >= 20 Then ExitLoop
            WEnd
            FileClose($hSearch)
        EndIf

        If $iFoundCount = 0 Then
            _MsgBoxSquare(16, "Error", "No *_M.ini found in the same folder." & @CRLF & _
                "Add cleanup entries to MIIIMEUniCleaner.ini, or place a *_M.ini here." & @CRLF & _
                "(Code: " & $ERR_NO_M_INI & ")")
            Exit
        ElseIf $iFoundCount > 1 Then
            _MsgBoxSquare(16, "Error", "Multiple *_M.ini files found in the same folder." & @CRLF & _
                "Please keep only one *_M.ini. (Code: " & $ERR_MULTI_M_INI & ")")
            Exit
        Else
            ; 1개: 연동 모드
            Local $sLinkedIni = @ScriptDir & "\" & $aFound[0]
            $g_oCtx.Item("RunMode")        = "Linked"
            $g_oCtx.Item("CleanupIniFile") = $sLinkedIni
            ; *_M.ini 의 [Directories] 에서 런처 경로 매크로 계산
            _Load_Launcher_Paths($sLinkedIni)
        EndIf
    EndIf
EndFunc

; -------------------------------------------------------------------------------------------------
; Function: _HasCleanupEntries
; 지정 INI 의 [CleanupExclude] 또는 [CleanupDelete] 에
; 제어 키(숫자값만 가진 키)를 제외한 실제 경로 항목이 1개 이상 있으면 True 반환.
;
; 제어 키 판별 기준: 값이 순수 정수(숫자만)인 키는 제어 키로 간주합니다.
;   예) Enable=1, SmartSkip=2 → 제어 키 (건너뜀)
;       01=C:\some\path       → 경로 항목 (카운트)
; -------------------------------------------------------------------------------------------------
Func _HasCleanupEntries($sIni)
    Local $aSections[2] = ["CleanupExclude", "CleanupDelete"]
    Local $iS
    For $iS = 0 To 1
        Local $aData = IniReadSection($sIni, $aSections[$iS])
        If @error Then ContinueLoop
        Local $iK
        For $iK = 1 To $aData[0][0]
            If $aData[$iK][1] = "" Then ContinueLoop
            ; 값이 순수 정수(제어 키)이면 건너뜀
            If StringRegExp($aData[$iK][1], "^\d+$") Then ContinueLoop
            Return True
        Next
    Next
    Return False
EndFunc

; -------------------------------------------------------------------------------------------------
; Function: _Load_Launcher_Paths
; *_M.ini 의 [Directories] 를 읽어 런처 전용 경로 매크로를 Context 에 저장.
; TargetApp_M 의 _GetAbsPath / _Load_Config 로직을 동일하게 이식.
;
; 저장되는 키:
;   Linked_DirBase   : *_M.ini 가 있는 폴더 (런처의 @ScriptDir)
;   Linked_DirRun    : {RunPath}    → {Dat}, {Run} 등의 기준
;   Linked_DirDat    : {DataPath}
;   Linked_DirExt    : {ExtPath}
;   Linked_DirAst    : {ExtPath}\Ast
;   Linked_DirSys    : {ExtPath}\Sys
;   Linked_DirRes    : {ExtPath}\Res
; -------------------------------------------------------------------------------------------------
Func _Load_Launcher_Paths($sLinkedIni)
    Local $sLBase = StringRegExpReplace($sLinkedIni, "\\[^\\]*$", "")

    Local $sRunRel = IniRead($sLinkedIni, "Directories", "RunPath",     "App\TargetApp")
    Local $sDatRel = IniRead($sLinkedIni, "Directories", "DataPath",    "Dat")
    Local $sExtRel = IniRead($sLinkedIni, "Directories", "ExtPath",     "App\Ext")

    $g_oCtx.Item("Linked_DirBase") = $sLBase
    $g_oCtx.Item("Linked_DirRun")  = _AbsPath($sLBase, $sRunRel)
    $g_oCtx.Item("Linked_DirDat")  = _AbsPath($sLBase, $sDatRel)
    $g_oCtx.Item("Linked_DirExt")  = _AbsPath($sLBase, $sExtRel)
    $g_oCtx.Item("Linked_DirAst")  = $g_oCtx.Item("Linked_DirExt") & "\Ast"
    $g_oCtx.Item("Linked_DirSys")  = $g_oCtx.Item("Linked_DirExt") & "\Sys"
    $g_oCtx.Item("Linked_DirRes")  = $g_oCtx.Item("Linked_DirExt") & "\Res"

    _Log("CORE", "[Init] Linked_DirBase: " & $g_oCtx.Item("Linked_DirBase"), "DEBUG")
    _Log("CORE", "[Init] Linked_DirRun : " & $g_oCtx.Item("Linked_DirRun"),  "DEBUG")
    _Log("CORE", "[Init] Linked_DirDat : " & $g_oCtx.Item("Linked_DirDat"),  "DEBUG")
    _Log("CORE", "[Init] Linked_DirExt : " & $g_oCtx.Item("Linked_DirExt"),  "DEBUG")
    _Log("CORE", "[Init] Linked_DirAst : " & $g_oCtx.Item("Linked_DirAst"),  "DEBUG")
    _Log("CORE", "[Init] Linked_DirSys : " & $g_oCtx.Item("Linked_DirSys"),  "DEBUG")
    _Log("CORE", "[Init] Linked_DirRes : " & $g_oCtx.Item("Linked_DirRes"),  "DEBUG")
EndFunc

; -------------------------------------------------------------------------------------------------
; Function: _Load_Config
; OwnIni 에서 모든 동작 설정을 읽어 Context 에 저장.
; [CleanupExclude] / [CleanupDelete] 의 경로는 CleanupIniFile 에서 읽습니다.
; -------------------------------------------------------------------------------------------------
Func _Load_Config()
    Local $sOwnIni = $g_oCtx.Item("OwnIniFile")

    ; --- [Launch] ---
    $g_oCtx.Item("AppName") = IniRead($sOwnIni, "Launch", "AppName", "MIIIME Universal Cleaner")

    ; --- [Settings] ---
    $g_oCtx.Item("ForceAdmin")    = (Number(IniRead($sOwnIni, "Settings", "RunAsAdmin",    "0")) = 1)
    $g_oCtx.Item("ShowFinishMsg") = (Number(IniRead($sOwnIni, "Settings", "ShowFinishMsg", "1")) = 1)
    $g_oCtx.Item("FinishText")    = "Cleanup is complete."

    ; --- [Options] ---
    $g_oCtx.Item("LogLevel") = Number(IniRead($sOwnIni, "Options", "LogLevel", "0"))

    ; --- [Advanced] ---
    $g_oCtx.Item("Adv_RetryLimit")    = Number(IniRead($sOwnIni, "Advanced", "RetryLimit",      "10"))
    $g_oCtx.Item("Adv_RetryDelay")    = Number(IniRead($sOwnIni, "Advanced", "RetryDelay",      "50"))
    $g_oCtx.Item("Adv_LogRotateSize") = Number(IniRead($sOwnIni, "Advanced", "LogRotationSize", "5242880"))

    ; 안전장치
    If $g_oCtx.Item("Adv_RetryLimit")    <= 0 Then $g_oCtx.Item("Adv_RetryLimit")    = 10
    If $g_oCtx.Item("Adv_LogRotateSize") <= 0 Then $g_oCtx.Item("Adv_LogRotateSize") = 5242880
EndFunc

; =================================================================================================
; [2] 클리닝 메인 함수
; =================================================================================================

; -------------------------------------------------------------------------------------------------
; Function: _Run_Cleanup
; CleanupIniFile 의 [CleanupExclude] / [CleanupDelete] 를 처리합니다.
;
; [CleanupExclude]
;   INI 형식 : 키=보존할 항목의 전체 경로 (한 줄에 하나, 매크로 지원)
;   - 같은 부모 폴더를 가진 항목들을 자동으로 그룹핑합니다.
;   - 각 부모 폴더 안에서 나열되지 않은 파일/폴더는 모두 삭제됩니다.
;   - 경로 항목이 1개 이상 있으면 무조건 실행합니다.
;
; [CleanupDelete]
;   INI 형식 : 키=삭제할 항목의 전체 경로 (매크로, 와일드카드 * ? # 지원)
;   - 경로 항목이 1개 이상 있으면 무조건 실행합니다.
;
; 실행 조건(Enable, SmartSkip 등)은 호출 측(런처 또는 사용자)이 판단합니다.
; 클리너 자체는 항목이 있으면 실행합니다.
;
; ※ CleanupExclude 를 반드시 먼저 실행합니다.
;    (보존 우선 처리 후 Delete 가 실행되어야 보존 대상이 실수로 삭제되지 않음)
; -------------------------------------------------------------------------------------------------
Func _Run_Cleanup()

    ; ─────────────────────────────────────────────────────────────────────────
    ; [Step 1] CleanupExclude
    ; ─────────────────────────────────────────────────────────────────────────
    Local $aExclude[0], $iExCount = 0
    _LoadIniSection_Values("CleanupExclude", $aExclude, $iExCount)

    If $iExCount = 0 Then
        _Log("FS", "[CleanupExclude] No entries. Skipped.", "INFO")
    Else
        _Log("FS", "[CleanupExclude] Section loaded: " & $iExCount & " entries.", "INFO")

        Local $oGroups = ObjCreate("Scripting.Dictionary")
        If Not IsObj($oGroups) Then
            _Log("FS", "[CleanupExclude] Failed to create group dictionary.", "WARN")
        Else
            Local $i
            For $i = 0 To $iExCount - 1
                Local $sFullPath = _ExpandMacros($aExclude[$i])
                Local $sParent   = StringRegExpReplace($sFullPath, "\\[^\\]+$", "")
                Local $sItem     = StringRegExpReplace($sFullPath, "^.*\\",     "")

                If $sParent = "" Or $sItem = "" Then
                    _Log("FS", "[CleanupExclude] Invalid path (skipped): " & $aExclude[$i], "WARN")
                    ContinueLoop
                EndIf

                If $oGroups.Exists($sParent) Then
                    $oGroups.Item($sParent) = $oGroups.Item($sParent) & "|" & $sItem
                Else
                    $oGroups.Add($sParent, $sItem)
                EndIf
            Next

            Local $aParents = $oGroups.Keys()
            Local $iG
            For $iG = 0 To UBound($aParents) - 1
                Local $sBaseDir  = $aParents[$iG]
                Local $sKeepList = $oGroups.Item($sBaseDir)

                If Not FileExists($sBaseDir) Then
                    _Log("FS", "[CleanupExclude] Dir not found (skipped): " & $sBaseDir, "INFO")
                    ContinueLoop
                EndIf

                Local $aItems = _FileListToArray($sBaseDir, "*", 0)
                If @error Then
                    _Log("FS", "[CleanupExclude] Dir is empty or unreadable: " & $sBaseDir, "INFO")
                    ContinueLoop
                EndIf

                Local $j
                For $j = 1 To $aItems[0]
                    Local $sItemName  = $aItems[$j]
                    Local $sFullPath2 = $sBaseDir & "\" & $sItemName

                    If _WildcardMatchList($sItemName, $sKeepList) Then
                        _Log("FS", "[CleanupExclude] Kept: " & $sFullPath2, "DEBUG")
                        ContinueLoop
                    EndIf

                    _RobustDelete($sFullPath2)
                    _Log("FS", "[CleanupExclude] Deleted: " & $sFullPath2, "INFO")
                Next
            Next

            $oGroups.RemoveAll()
        EndIf

        _Log("FS", "[CleanupExclude] Done.", "INFO")
    EndIf

    ; ─────────────────────────────────────────────────────────────────────────
    ; [Step 2] CleanupDelete
    ; ─────────────────────────────────────────────────────────────────────────
    Local $aDelete[0], $iDelCount = 0
    _LoadIniSection_Values("CleanupDelete", $aDelete, $iDelCount)

    If $iDelCount = 0 Then
        _Log("FS", "[CleanupDelete] No entries. Skipped.", "INFO")
    Else
        _Log("FS", "[CleanupDelete] Section loaded: " & $iDelCount & " entries.", "INFO")

        Local $i2
        For $i2 = 0 To $iDelCount - 1
            Local $sTarget = _ExpandMacros($aDelete[$i2])

            ; 와일드카드 처리 (*, ?, # 중 하나라도 포함되면 패턴 검색)
            If StringInStr($sTarget, "*") Or StringInStr($sTarget, "?") Or StringInStr($sTarget, "#") Then
                ; # 는 FileFindFirstFile 이 이해하지 못하므로 ? 로 변환하여 OS 검색
                ; _WildcardMatch 로 2차 필터링하여 hex 조건을 정확히 적용
                Local $sSearchPat   = StringReplace($sTarget, "#", "?")
                Local $sPatternOnly = StringRegExpReplace($sTarget, "^.*\\", "")
                Local $hWcSearch    = FileFindFirstFile($sSearchPat)
                If $hWcSearch = -1 Then
                    _Log("FS", "[CleanupDelete] Not found (skipped): " & $sTarget, "DEBUG")
                Else
                    Local $sParentDir = StringLeft($sSearchPat, StringInStr($sSearchPat, "\", 0, -1))
                    While 1
                        Local $sFoundItem = FileFindNextFile($hWcSearch)
                        If @error Then ExitLoop
                        ; # 패턴이 포함된 경우 _WildcardMatch 로 정확히 재검증
                        If StringInStr($sPatternOnly, "#") And Not _WildcardMatch($sFoundItem, $sPatternOnly) Then
                            ContinueLoop
                        EndIf
                        Local $sFullTarget = $sParentDir & $sFoundItem
                        _RobustDelete($sFullTarget)
                        _Log("FS", "[CleanupDelete] Wildcard Deleted: " & $sFullTarget, "INFO")
                    WEnd
                    FileClose($hWcSearch)
                EndIf
            Else
                If FileExists($sTarget) Then
                    _RobustDelete($sTarget)
                    _Log("FS", "[CleanupDelete] Deleted: " & $sTarget, "INFO")
                Else
                    _Log("FS", "[CleanupDelete] Not found (skipped): " & $sTarget, "DEBUG")
                EndIf
            EndIf
        Next

        _Log("FS", "[CleanupDelete] Done.", "INFO")
    EndIf
EndFunc

; =================================================================================================
; [3] 유틸리티 함수
; =================================================================================================

; -------------------------------------------------------------------------------------------------
; Function: _LoadIniSection_Values
; CleanupIniFile 의 지정 섹션에서 경로 값만 배열로 로드.
; 값이 순수 정수인 항목(Enable=1, SmartSkip=2 등 제어 키)과 빈 항목은 건너뜁니다.
; -------------------------------------------------------------------------------------------------
Func _LoadIniSection_Values($sSection, ByRef $aArray, ByRef $iCount)
    Local $sIni = $g_oCtx.Item("CleanupIniFile")
    If $sIni = "" Or Not FileExists($sIni) Then
        $iCount = 0
        Return
    EndIf

    Local $aData = IniReadSection($sIni, $sSection)
    If @error Then
        $iCount = 0
        Return
    EndIf

    ReDim $aArray[$aData[0][0]]
    $iCount = 0
    Local $i
    For $i = 1 To $aData[0][0]
        If $aData[$i][1] = "" Then ContinueLoop
        ; 값이 순수 정수이면 제어 키로 간주하고 건너뜀
        If StringRegExp($aData[$i][1], "^\d+$") Then ContinueLoop
        $aArray[$iCount] = $aData[$i][1]
        $iCount += 1
    Next
EndFunc

; -------------------------------------------------------------------------------------------------
; Function: _RobustDelete
; 재시도를 통한 안정적인 파일/폴더 삭제 (읽기전용 속성 해제 후 시도)
; -------------------------------------------------------------------------------------------------
Func _RobustDelete($sTarget)
    Local $iLimit = $g_oCtx.Exists("Adv_RetryLimit") ? $g_oCtx.Item("Adv_RetryLimit") : 10
    Local $iDelay = $g_oCtx.Exists("Adv_RetryDelay") ? $g_oCtx.Item("Adv_RetryDelay") : 50

    FileSetAttrib($sTarget, "-R", 1)

    Local $iTry = 0
    While $iTry < $iLimit
        If Not FileExists($sTarget) Then Return True
        If StringInStr(FileGetAttrib($sTarget), "D") Then
            If DirRemove($sTarget, 1) Then Return True
        Else
            If FileDelete($sTarget) Then Return True
        EndIf
        Sleep($iDelay)
        $iTry += 1
    WEnd
    _Log("FS", "[Error] Delete failed: " & $sTarget & " Code: " & $ERR_FILE_DELETE, "ERROR")
    Return False
EndFunc

; -------------------------------------------------------------------------------------------------
; Function: _AbsPath
; 상대 경로를 절대 경로로 변환 (지정 기준 디렉토리 사용)
; TargetApp_M 의 _GetAbsPath 로직과 동일
; -------------------------------------------------------------------------------------------------
Func _AbsPath($sBase, $sPath)
    If $sPath = "" Then Return ""
    If StringInStr($sPath, ":") Or StringLeft($sPath, 2) = "\\" Then Return $sPath

    Local $sAbs
    If StringLeft($sPath, 1) = "\" Then
        $sAbs = $sBase & $sPath
    Else
        $sAbs = $sBase & "\" & $sPath
    EndIf

    ; .. 정규화
    If StringInStr($sAbs, "\..")  Then
        Local $aParts = StringSplit($sAbs, "\", 2)
        Local $aRes[UBound($aParts)]
        Local $iR = 0, $iP
        For $iP = 0 To UBound($aParts) - 1
            If $aParts[$iP] = ".." Then
                If $iR > 1 Then $iR -= 1
            ElseIf $aParts[$iP] <> "." Then
                $aRes[$iR] = $aParts[$iP]
                $iR += 1
            EndIf
        Next
        Local $sOut = ""
        Local $iJ
        For $iJ = 0 To $iR - 1
            $sOut &= ($iJ = 0 ? "" : "\") & $aRes[$iJ]
        Next
        Return $sOut
    EndIf

    Return $sAbs
EndFunc

; -------------------------------------------------------------------------------------------------
; Function: _ExpandMacros
; 경로 매크로를 실제 경로로 치환합니다.
;
; 독립 모드 / 연동 모드 공통:
;   {Base}         → 독립 모드: MIIIMEUniCleaner.exe 가 있는 폴더
;                    연동 모드: *_M.ini 가 있는 폴더 (런처의 @ScriptDir)
;   {Windows}      → %SystemRoot%
;   {System32}     → %SystemRoot%\System32
;   {SysWOW64}     → %SystemRoot%\SysWOW64
;   {ProgramFiles} → %ProgramFiles%
;   {ProgramData}  → %ProgramData%
;   {UserProfile}  → %USERPROFILE%
;   {Docs}         → %USERPROFILE%\Documents
;   {Desktop}      → @DesktopDir
;   {Local}        → %LOCALAPPDATA%
;   {Roaming}      → %APPDATA%
;   {LocalLow}     → %USERPROFILE%\AppData\LocalLow
;   {Temp}         → %TEMP%
;   {StartMenu}    → @StartMenuDir
;   {Programs}     → @ProgramsDir
;   {CommonStartMenu} → %ProgramData%\Microsoft\Windows\Start Menu
;   {CommonPrograms}  → %ProgramData%\Microsoft\Windows\Start Menu\Programs
;
; 연동 모드 추가 (Linked_Dir* 가 설정된 경우):
;   {Run}          → 런처의 RunPath (타겟 앱 실행 폴더)
;   {Dat}          → 런처의 DataPath (데이터 폴더)
;   {Ext}          → 런처의 ExtPath
;   {Ast}          → {Ext}\Ast
;   {Sys}          → {Ext}\Sys
;   {Res}          → {Ext}\Res
;
; %환경변수% 형식도 지원합니다.
; -------------------------------------------------------------------------------------------------
Func _ExpandMacros($sText)
    ; ── 런처 전용 매크로 (연동 모드에서만 의미 있음, 키 없으면 빈 문자열 치환) ──
    If $g_oCtx.Exists("Linked_DirBase") Then
        $sText = StringReplace($sText, "{Base}", $g_oCtx.Item("Linked_DirBase"))
        $sText = StringReplace($sText, "{Run}",  $g_oCtx.Item("Linked_DirRun"))
        $sText = StringReplace($sText, "{Dat}",  $g_oCtx.Item("Linked_DirDat"))
        $sText = StringReplace($sText, "{Ext}",  $g_oCtx.Item("Linked_DirExt"))
        $sText = StringReplace($sText, "{Ast}",  $g_oCtx.Item("Linked_DirAst"))
        $sText = StringReplace($sText, "{Sys}",  $g_oCtx.Item("Linked_DirSys"))
        $sText = StringReplace($sText, "{Res}",  $g_oCtx.Item("Linked_DirRes"))
    Else
        ; 독립 모드: {Base} 는 MIIIMEUniCleaner.exe 위치
        $sText = StringReplace($sText, "{Base}", $g_oCtx.Item("DirBase"))
    EndIf

    ; ── 시스템 경로 매크로 ──
    $sText = StringReplace($sText, "{Windows}",          EnvGet("SystemRoot"))
    $sText = StringReplace($sText, "{System32}",         EnvGet("SystemRoot") & "\System32")
    $sText = StringReplace($sText, "{SysWOW64}",         EnvGet("SystemRoot") & "\SysWOW64")
    $sText = StringReplace($sText, "{ProgramFiles}",     EnvGet("ProgramFiles"))
    $sText = StringReplace($sText, "{ProgramData}",      EnvGet("ProgramData"))

    ; ── 사용자 경로 매크로 ──
    $sText = StringReplace($sText, "{UserProfile}",      EnvGet("USERPROFILE"))
    $sText = StringReplace($sText, "{Docs}",             EnvGet("USERPROFILE") & "\Documents")
    $sText = StringReplace($sText, "{Desktop}",          @DesktopDir)
    $sText = StringReplace($sText, "{Local}",            @LocalAppDataDir)
    $sText = StringReplace($sText, "{Roaming}",          @AppDataDir)
    $sText = StringReplace($sText, "{LocalLow}",         EnvGet("USERPROFILE") & "\AppData\LocalLow")
    $sText = StringReplace($sText, "{Temp}",             @TempDir)
    $sText = StringReplace($sText, "{StartMenu}",        @StartMenuDir)
    $sText = StringReplace($sText, "{Programs}",         @ProgramsDir)
    $sText = StringReplace($sText, "{CommonStartMenu}",  EnvGet("ProgramData") & "\Microsoft\Windows\Start Menu")
    $sText = StringReplace($sText, "{CommonPrograms}",   EnvGet("ProgramData") & "\Microsoft\Windows\Start Menu\Programs")

    ; ── %환경변수% 처리 ──
    Local $aEnv = StringRegExp($sText, "%([^%]+)%", 3)
    If Not @error Then
        Local $iE
        For $iE = 0 To UBound($aEnv) - 1
            $sText = StringReplace($sText, "%" & $aEnv[$iE] & "%", EnvGet($aEnv[$iE]))
        Next
    EndIf

    ; ── .. 포함 경로 정규화 (절대 경로인 경우만) ──
    If StringInStr($sText, "\..") And StringMid($sText, 2, 1) = ":" Then
        Local $aParts = StringSplit($sText, "\", 2)
        Local $aResult[UBound($aParts)]
        Local $iR = 0, $iP
        For $iP = 0 To UBound($aParts) - 1
            If $aParts[$iP] = ".." Then
                If $iR > 1 Then $iR -= 1
            ElseIf $aParts[$iP] <> "." Then
                $aResult[$iR] = $aParts[$iP]
                $iR += 1
            EndIf
        Next
        Local $sFinal = ""
        Local $iJ
        For $iJ = 0 To $iR - 1
            $sFinal &= ($iJ = 0 ? "" : "\") & $aResult[$iJ]
        Next
        $sText = $sFinal
    EndIf

    Return $sText
EndFunc

; -------------------------------------------------------------------------------------------------
; Function: _WildcardMatchList
; 항목명이 파이프(|) 구분 패턴 목록 중 하나와 일치하면 True 반환
; -------------------------------------------------------------------------------------------------
Func _WildcardMatchList($sName, $sPatternList)
    Local $aPatterns = StringSplit($sPatternList, "|", 2)
    Local $i
    For $i = 0 To UBound($aPatterns) - 1
        Local $sPat = StringStripWS($aPatterns[$i], 3)
        If $sPat = "" Then ContinueLoop
        If _WildcardMatch($sName, $sPat) Then Return True
    Next
    Return False
EndFunc

; -------------------------------------------------------------------------------------------------
; Function: _WildcardMatch
; 단일 패턴과 항목명을 비교 (대소문자 구분 없음)
; 지원 와일드카드:
;   *  → 0개 이상의 임의 문자
;   ?  → 정확히 1개의 임의 문자
;   #  → 소문자 16진수 정확히 1글자 [0-9a-f]
; TargetApp_M 의 _WildcardMatch 와 동일한 구현
; -------------------------------------------------------------------------------------------------
Func _WildcardMatch($sStr, $sPattern)
    Local $sReg = $sPattern

    ; Step 1: * ? # 를 먼저 플레이스홀더로 치환 (이후 이스케이프 영향을 받지 않도록)
    $sReg = StringReplace($sReg, "*", @TAB & "STAR"  & @TAB)
    $sReg = StringReplace($sReg, "?", @TAB & "QMARK" & @TAB)
    $sReg = StringReplace($sReg, "#", @TAB & "HMARK" & @TAB)

    ; Step 2: 나머지 정규식 특수문자 이스케이프
    $sReg = StringRegExpReplace($sReg, "[.+^${}()\[\]\\|]", "\\$0")

    ; Step 3: 플레이스홀더를 정규식 표현으로 복원
    $sReg = StringReplace($sReg, @TAB & "STAR"  & @TAB, ".*")
    $sReg = StringReplace($sReg, @TAB & "QMARK" & @TAB, ".")
    $sReg = StringReplace($sReg, @TAB & "HMARK" & @TAB, "[0-9a-f]")

    ; Step 4: 전체 일치 + 대소문자 무시
    $sReg = "(?i)^" & $sReg & "$"
    Return StringRegExp($sStr, $sReg)
EndFunc

; -------------------------------------------------------------------------------------------------
; Function: _Log
; 로그 기록 + 로테이션 (MIIIME_Log_Standard_1_1 준거)
; -------------------------------------------------------------------------------------------------
Func _Log($sSender, $sMsg, $sLevel = "INFO")
    Local $iLogLevel = $g_oCtx.Item("LogLevel")
    If $iLogLevel = 0 Then Return

    ; LogLevel 1 : DEBUG 제외하고 모두 출력 (INFO/WARN/ERROR)
    ; LogLevel 2 : DEBUG 이상 모두 출력
    ; LogLevel 3 : INFO  이상 출력
    ; LogLevel 4 : WARN  이상 출력
    ; LogLevel 5 : ERROR 만 출력
    Local $iMsgWeight = 3
    Switch $sLevel
        Case "DEBUG"
            $iMsgWeight = 2
        Case "INFO"
            $iMsgWeight = 3
        Case "WARN"
            $iMsgWeight = 4
        Case "ERROR"
            $iMsgWeight = 5
    EndSwitch

    ; LogLevel=1 은 DEBUG(weight=2) 만 차단, 나머지 통과
    Local $iThreshold = ($iLogLevel = 1) ? 3 : $iLogLevel
    If $iMsgWeight < $iThreshold Then Return

    Local $sLogFile    = $g_oCtx.Item("LogFile")
    Local $iRotateSize = $g_oCtx.Item("Adv_LogRotateSize")
    If $iRotateSize <= 0 Then $iRotateSize = 5242880

    If FileExists($sLogFile) And FileGetSize($sLogFile) > $iRotateSize Then
        If Not StringInStr(FileGetAttrib($sLogFile), "R") Then
            FileMove($sLogFile, $sLogFile & ".old", 1)
        EndIf
    EndIf

    Local $sTime = @YEAR & "/" & @MON & "/" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC
    Local $sLine = "[" & $sTime & "] [" & StringUpper($sLevel) & "] [" & $sSender & "] " & $sMsg

    Local $hFile
    Local $iTry = 0
    While $iTry < 5
        $hFile = FileOpen($sLogFile, 1) ; FO_APPEND
        If $hFile <> -1 Then
            FileWriteLine($hFile, $sLine)
            FileClose($hFile)
            Return
        EndIf
        Sleep(50)
        $iTry += 1
    WEnd
EndFunc
