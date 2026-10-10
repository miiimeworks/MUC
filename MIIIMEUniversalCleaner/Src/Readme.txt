========================================================================
             MIIIME Universal Cleaner (MUC™)
========================================================================

Cleans up unnecessary files and folders according to rules defined in the INI configuration file.   
Supports both 'Delete' mode and 'Exclude' mode.
Can also work as a companion tool for MIIIMETools.

INI 설정 파일에 정의된 규칙에 따라 불필요한 파일과 폴더를 정리합니다.  
'삭제(Delete)' 모드와 '남기기(Exclude)' 모드를 지원하며, 미메툴즈의 보조 도구로 사용할 수 있습니다.

========================================================================
[File Organization]
========================================================================

MIIIMEUniCleaner.exe	# [Run] Cleaner executable file / [실행] 클리너 실행 파일
MIIIMEUniCleaner.ini	# [Settings] Configuration file / [설정] 설정 파일

========================================================================
[How to use]
========================================================================

--- Standalone Mode / 독립 모드 ---

1. Open [MIIIMEUniCleaner.ini] and add cleanup entries to
   [CleanupExclude] and/or [CleanupDelete] sections.
2. Run [MIIIMEUniCleaner.exe].

1. [MIIIMEUniCleaner.ini]를 열어 [CleanupExclude] 또는 [CleanupDelete]
   섹션에 정리 대상 경로를 추가.
2. [MIIIMEUniCleaner.exe]를 실행.

--- Linked Mode / 연동 모드 ---

If there are no items in the [CleanupExclude] / [CleanupDelete] section,
Run cleanup by referring to LinkedIniName in the same path as MIIIMEUniCleaner.exe.

[CleanupExclude] / [CleanupDelete] 섹션에 항목이 없는 경우,
MIIIMEUniCleaner.exe 와 동일한 경로에 있는 LinkedIniName을 참고하여 클린업 실행.

※ Setting tips / 설정 팁 :
 - [CleanupExclude] : Keeps only the listed items, deletes the rest. / 목록의 항목만 남기고 나머지를 삭제.    
 - [CleanupDelete] : Deletes the listed items. / 목록의 항목을 삭제.

______________________________________________________________________________________________________________________

This program was created with AutoIt. Some antivirus programs may incorrectly detect it as a virus.
본 프로그램은 AutoIt으로 제작되었습니다. 일부 백신이 바이러스로 오진 할 수 있습니다.

========================================================================
[Disclaimer]
========================================================================

Provided **"AS IS"**, without warranty.
This is a **private project**. No technical support is provided.
본 프로그램은 **"있는 그대로"** 제공되며, 사용 중 발생하는 문제에 대해 제작자는 책임을 지지 않습니다.
기술 지원은 제공되지 않습니다.

Developer	: MIIIME 
Website		: https://www.miiime.com 
GitHub		: @miiimeworks 
Update      	: 2026.10.10
