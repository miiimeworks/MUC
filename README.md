# MIIIME Universal Cleaner (MUC™)

MIIIMEUniCleaner · 미메클리너

![OS](https://img.shields.io/badge/Platform-Windows-0078D4?logo=windows&style=flat-square)
[![Language](https://img.shields.io/badge/Language-AutoIt-orange?logo=autoit&style=flat-square)](https://www.autoitscript.com/site/)
![License](https://img.shields.io/badge/License-Freeware-lightgrey?style=flat-square)

<br>
<img width="559" height="136" alt="001" src="https://github.com/miiimeworks/M4T/blob/main/4bit_Enhanced/Id/Neon/4b_136_1_G.png?raw=true" style="margin-top: 20px; margin-bottom: 20px;">
<br>

This tool cleans up unnecessary files and folders according to rules defined in the INI configuration file.  
Supports both 'Delete' mode and 'Exclude' mode.
Can also work as a companion tool for MIIIME Hybrid Launcher.

이 도구는 INI 설정 파일에 정의된 규칙에 따라 불필요한 파일과 폴더를 정리합니다.  
'삭제(Delete)' 모드와 '남기기(Exclude)' 모드를 지원하며, 미메런처의 보조 도구로 사용할 수 있습니다.
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

### Linked Mode (MHL)

- Place MIIIMEUniCleaner.exe and MIIIMEUniCleaner.ini in the same folder as the *_M.ini launcher file. 
- The cleaner will automatically read the [CleanupExclude] and [CleanupDelete] sections from the *_M.ini, 
  ignoring the SmartSkip flag.

**[연동 모드]**

- MIIIMEUniCleaner.exe 와 MIIIMEUniCleaner.ini 를 런처(*_M.ini)와 동일한 폴더에 배치. 
- [CleanupExclude] / [CleanupDelete] 섹션을 *_M.ini 에서 자동으로 읽어 실행. (SmartSkip 값 무시).

---

### Setting tips

- [CleanupExclude] : Keeps only the listed items, deletes the rest.    

- [CleanupDelete] : Deletes the listed items.
  
  **[설정 팁]**

- [CleanupExclude] : 목록의 항목만 남기고 나머지를 삭제.    

- [CleanupDelete] : 목록의 항목을 삭제.  

---

## 🛡️ Security & Anti-virus Info

### [✅ VirusTotal Analysis Report](https://www.virustotal.com/gui/file/47e1be90bb19d901ce6ec7bc0706e0b7ce8689b49b9015d2c94dd7523f09d594?nocache=1)

| Status             | Details                                                                        |
|:------------------ |:------------------------------------------------------------------------------ |
| **Major Vendors**  | **Clean** (Passed by AhnLab V3, Kaspersky, Microsoft, Avast, ESET, etc.)       |
| **Detection Rate** | **8 / 72** (Mostly Heuristic/Generic/Trojan-type flags)                        |
| **Integrity**      | The source code is transparently available for verification in this repository |

> This Program was created with AutoIt. Some antivirus programs may incorrectly detect it as a virus.  
> 본 프로그램은 AutoIt으로 제작되었습니다. 일부 백신이 바이러스로 오진 할 수 있습니다. 

**File Checksum (SHA-256) :** `47e1be90bb19d901ce6ec7bc0706e0b7ce8689b49b9015d2c94dd7523f09d594`

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
**GitHub** : [@miiime6248](https://github.com/miiime6248)  
**Last Update** : 2026-02-14  

<br>
<img width="64" height="64" alt="002" src="https://github.com/miiimeworks/M4T/blob/main/4bit_Brutal/Logo/Neon/4b_Mium_64_0_G.png?raw=true">  
<br>
<br>
<br>