# MIIIME Universal Cleaner (MUC™)

MIIIMECleaner · 미메클리너

![OS](https://img.shields.io/badge/Platform-Windows-0078D4?logo=windows&style=flat-square)
[![Language](https://img.shields.io/badge/Language-AutoIt-orange?logo=autoit&style=flat-square)](https://www.autoitscript.com/site/)
![License](https://img.shields.io/badge/License-Freeware-lightgrey?style=flat-square)

<br>
<img width="559" height="136" alt="001" src="https://github.com/miiimeworks/M4T/blob/main/4bit_Enhanced/Id/Neon/4b_136_1_G.png?raw=true" style="margin-top: 20px; margin-bottom: 20px;">
<br>

Cleans up unnecessary files and folders according to rules defined in the INI configuration file.   
Supports both 'Delete' mode and 'Exclude' mode.
Can also work as a companion tool for MIIIMETools.

INI 설정 파일에 정의된 규칙에 따라 불필요한 파일과 폴더를 정리합니다.  
'삭제(Delete)' 모드와 '남기기(Exclude)' 모드를 지원하며, 미메툴즈의 보조 도구로 사용할 수 있습니다.

<br>
<img width="402" height="197" alt="001" src="https://github.com/miiimeworks/MUC/blob/main/Preview/001.png?raw=true" style="margin-top: 20px; margin-bottom: 20px;">
<br>

---

### File Organization

```text
MIIIMEUniCleaner.exe     # [Run] Cleaner executable file / 클리너 실행 파일
MIIIMEUniCleaner.ini     # [Settings] Cleanup target and rules / 정리 대상 및 규칙
```

---

## How to Use

### Standalone Mode

1. Open [MIIIMEUniCleaner.ini] and add cleanup entries to
   [CleanupExclude] and/or [CleanupDelete] sections.
2. Run [MIIIMEUniCleaner.exe].

**[독립 모드]**

1. [MIIIMEUniCleaner.ini]를 열어 [CleanupExclude] 또는 [CleanupDelete]
   섹션에 정리 대상을 추가.
2. [MIIIMEUniCleaner.exe]를 실행.

### Linked Mode

- If there are no items in the [CleanupExclude] / [CleanupDelete] section,
Run cleanup by referring to LinkedIniName in the same path as MIIIMEUniCleaner.exe.

**[연동 모드]**

- [CleanupExclude] / [CleanupDelete] 섹션에 항목이 없는 경우,
MIIIMEUniCleaner.exe 와 동일한 경로에 있는 LinkedIniName을 참고하여 클린업 실행.

- LinkedIniName ([Options]) is a priority list separated by pipes (`|`). e.g. `|*_x64_M|*_M|*_x86_M|`  
Entries are searched in order, and the first entry that finds an .ini file is used.  
An error occurs if one entry finds two or more files, or if no entry finds a file.

- LinkedIniName([Options])은 파이프(`|`)로 구분된 우선순위 목록입니다. 예: `|*_x64_M|*_M|*_x86_M|`  
앞에서부터 차례로 탐색하여 .ini 파일이 발견된 첫 항목을 사용합니다.  
한 항목에서 2개 이상 발견되거나 어느 항목에서도 발견되지 않으면 에러가 발생합니다.

### Setting tips

- [CleanupExclude] : Keeps only the listed items, deletes the rest.    

- [CleanupDelete] : Deletes the listed items.

- Safety : Drive roots, Documents, Desktop, Windows, Program Files, etc. are blocked by default.

**[설정 팁]**

- [CleanupExclude] : 목록의 항목만 남기고 나머지를 삭제.    

- [CleanupDelete] : 목록의 항목을 삭제.  

- 안전장치 : 드라이브 루트, 문서, 바탕화면, Windows, Program Files 등은 기본적으로 삭제가 차단됩니다.

---

## 🛡️ Security & Anti-virus Info

### [✅ VirusTotal Analysis Report](https://www.virustotal.com/gui/file/eb786d98123746c36c3b8ac4b85faab95bdeee1f6a7c2c5d2a3908e69b551d1f?nocache=1)

| Status             | Details                                                                        |
|:------------------ |:------------------------------------------------------------------------------ |
| **Major Vendors**  | **Clean** (Passed by AhnLab V3, Kaspersky, Microsoft, Avast, ESET, etc.)       |
| **Detection Rate** | **8 / 71** (Mostly Heuristic/Generic/Trojan-type flags)                        |
| **Integrity**      | Private project; verified via hashes and VT results. 						  |

> This Program was created with AutoIt. Some antivirus programs may incorrectly detect it as a virus.  
> 본 프로그램은 AutoIt으로 제작되었습니다. 일부 백신이 바이러스로 오진 할 수 있습니다. 

**File Checksum (SHA-256) :** `eb786d98123746c36c3b8ac4b85faab95bdeee1f6a7c2c5d2a3908e69b551d1f`

---

## Disclaimer

Provided **“AS IS”**, without warranty.  
This is a **private project**. No technical support is provided.

본 프로그램은 **“있는 그대로”** 제공되며, 사용 중 발생하는 문제에 대해 제작자는 책임을 지지 않습니다.  
기술 지원은 제공되지 않습니다.

---

## Project Information

**Developer** : MIIIME  
**Website** : https://www.miiime.com  
**GitHub** : [@miiimeworks](https://github.com/miiimeworks)  
**Last Update** : 2026-10-18   

<br>
<img width="64" height="64" alt="002" src="https://github.com/miiimeworks/M4T/blob/main/4bit_Brutal/Logo/Neon/4b_Mium_64_0_G.png?raw=true">  
<br>
<br>
<br>