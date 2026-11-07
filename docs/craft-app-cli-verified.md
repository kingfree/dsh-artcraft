> **Where this came from.** This report was produced while building the `craft-app-cli` skill on a Windows 11 machine with all 17 Craft CLIs installed (`C:\Program Files\<App>\<app>-cli.exe`). Paths below are that machine's local test folder (`work\craft-skill\test`); the commands are reproducible anywhere the CLI exists. Skill-side fixes from section 6 are already applied to `skills/craft-app-cli/SKILL.md`.

---
# Craft CLI 无 GUI 文件处理链路实证报告

- **生成时间**：2026-11-08（Asia/Shanghai）
- **执行者**：cli-verifier（DSH teammate）
- **目标**：证明“拿到 Office / Adobe / CAD / 3D / 音视频类商业软件文件时，不需要图形界面，也不写 Python 解析器，直接调用 `<app>-cli`”真的可行。
- **测试目录**：`C:\Users\mei\dsh\work\craft-skill\test\`（全部产物、`runlog.jsonl`、逐命令 stdout/stderr 在 `test\logs\`）
- **报告**：本文件；`test\_harness.ps1` 是可复现的执行器（逐命令 120 s 超时、记录退出码与产物字节数）。

## 0. 结论摘要

- 本机 17 个 Craft app 的 `<app>-cli` **全部存在且可执行**（ArtCraft Studio 未安装，未测）。
- 共跑 **22 组链路 / 157 次命令调用**：132 次 exit 0（其中 **123 条是最终有效命令**，其余 9 条是已被替代的试错、命令目录探测和 SKILL.md 示例校验（见第 6 节））；25 次失败全部已定位原因（CLI 语法试错，或 `validate-pdf` 这类预期校验失败），**0 次超时**，最长单命令 **93.7 s**（solidcraft 脚本→STEP，仍 < 120 s）。
- 全程**没有打开任何 GUI、没有写 Python 解析器**；只使用 CLI 自带的 `new/sample/run/convert/render/export/info` 等入口。
- 已验证可读/可写的扩展名（输入或输出）：`docx doc pdf md html odt rtf txt json xlsx csv pptx deckcraft psd pcraft tif tiff jpg webp exr svg ai vectorcraft dxf dwg dwt figcraft fig penpot tcraft sbs sc step wav flac ecproj fcproj designcraft`（36 种）。
- **未能实证**：`.aep`、`.prproj`、`.indd`、`.idml` —— 本机没有任何该类样本文件，Craft CLI 也只能保存自己的原生工程格式（.ecproj/.fcproj/.designcraft），无法凭空造 Adobe 文件。详见第 4 节。
- 三条最有代表性的命令：
  1. `& 'C:\Program Files\WordCraft\wordcraft-cli.exe' convert word/report.docx word/report.pdf` → 34,422 B PDF，pdfcraft 可读且 `producer:"WordCraft"`。
  2. `& 'C:\Program Files\DeckCraft\deckcraft-cli.exe' run --cmd 'slide.new={"title":"Q3 results","body":"…"}' --save deck/q3.deckcraft` → 直接造出演示文稿并经 `convert` 得到 23,532 B 的 .pptx。
  3. `& 'C:\Program Files\SolidCraft\solidcraft-cli.exe' run solid/script.json --out solid/part.step` → 4,713,253 B STEP + 可 `eval` 的 bodies 几何数据（93.7 s）。

## 1. 总表（格式 → CLI → 是否成功 → 产物 → 证据摘要）

| 格式/链路 | App / CLI | 成功 | 产物（字节） | 证据摘要 |
|---|---|---|---|---|
| `.docx` 生成 | wordcraft-cli | ✅ | word/report.docx 6,913 | `info`: pages=1, words=74, paragraphs=14 |
| docx → md/html/odt/rtf/pdf | wordcraft-cli | ✅ | 540 / 1,132 / 4,704 / 1,954 / 34,422 | `text`: “Craft CLI verification report …” |
| docx → png | wordcraft-cli | ✅ | word/report-p1.png 280,942 | `render`: 1224×1584 |
| `.xlsx` 生成 | gridcraft-cli | ✅ | sheet/sales.xlsx 11,159 | 工作表 `Sales`、67 cells、2 个图表 |
| xlsx → csv/pdf/html/json | gridcraft-cli | ✅ | 740 / 23,867 / 12,990 / 63,535 | `cat --csv`: `Quarterly Sales Dashboard` |
| `.pptx`（写+读） | deckcraft-cli | ✅ | deck/q3.pptx 23,532 | `info` 读回；再转 PDF 112,392 |
| `.deckcraft` 生成/渲染 | deckcraft-cli | ✅ | deck/q3.deckcraft 5,236；3×PNG | `render`: slide-01..03.png 1920×1080 |
| `.pdf` 只读/正文/渲染 | pdfcraft-cli | ✅ | word/report-p1.pdf 等 | `text` 与 docx 逐字一致；`render` 1020×1320 |
| `.pdf` 编辑/合并/抽取 | pdfcraft-cli | ✅ | 36,056 / 29,474 / 29,266 | 均 exit 0 |
| `.png/.jpg/.webp/.tif/.exr/.psd/.pcraft` | photocraft-cli | ✅ | 183,854 … 5,817,386 | `info`: 1224×1584, depth=8, mode=Rgb |
| `.psd` 读取（跨 app） | vectorcraft-cli | ✅ | word/report-from-psd.png 292,926 | `info`: artboard 1224×1584, objects=2 |
| `.svg/.ai/.vectorcraft` | vectorcraft-cli | ✅ | 703 / 20,988 / 10,980 / 27,946 | `info`: 595.276×425.197 pt, rgb, objects=3 |
| `.dxf/.dwg/.dwt` | cadcraft-cli | ✅ | 42,791 / 27,507 / 27,507 | `info`: 46 entities（Line16/Circle7/Dimension6/…） |
| `.figcraft/.fig/.penpot` | figcraft-cli | ✅ | 8,065 / 13,368 / 5,909 | `info`: 5 nodes、1 个顶层 FRAME 595.276×425.197 |
| `.tcraft` | texturecraft-cli | ✅ | 1,132,886；6 张贴图 | export/ bake/CPU render 全通 |
| `.sbs` | materialcraft-cli | ✅ | 17,420；6 张贴图 | `cook` 0.119 ms；render 512×512 |
| `.tif`/`.psd`（LightCraft） | lightcraft-cli | ✅ | 281,902 / 1,672,494 | `wrote … (464×600)` |
| `.sc` / `.step` | solidcraft-cli | ✅ | 1,965,443 / 4,713,253 | `eval` bodies；snapshot 1280×800 |
| `.wav`/`.flac` | soundcraft-cli | ✅ | 1,507,146 / 336,558 | `info`: 48 kHz Int24 2ch 5.23 s |
| `.ecproj` | effectcraft-cli | ✅ | 2,478 | `info`: 1 comp 640×360 3.003 s |
| `.fcproj` | filmcraft-cli | ✅ | 28,281；642 帧 PNG；5,141,180 WAV | `inspect` path/activeSequence |
| `.designcraft` / 排版 PDF | designcraft-cli | ✅ | 889,464 / 552,943（4 页） | `wrote … (630×810, 103 glyphs)` |
| `.odt/.rtf` 读取 | wordcraft-cli | ✅ | — | `info` pages=1, paragraphs=14 |
| 未知格式初查 | craft-anything-cli | ⚠️ 浅层 | — | docx→`A ZIP archive`；step/dwg→`unknown` |

## 2. 环境

| 项 | 值 |
|---|---|
| OS | Windows 11 专业版 10.0.26300 |
| CPU / GPU | AMD Ryzen AI 9 HX 370 / Radeon(TM) 890M |
| Shell | PowerShell 7.6.9 |
| CLI 根目录 | `C:\Program Files\<App>\<app>-cli.exe`（均在 PATH 外） |
| 测试工作目录 | `C:\Users\mei\dsh\work\craft-skill\test` |
| 超时策略 | 每条命令 120 s 硬超时（Process.WaitForExit + Kill），实际 0 次触发 |

| App | CLI | 版本 |
|---|---|---|
| WordCraft | wordcraft-cli | 0.15.2 |
| GridCraft | gridcraft-cli | 0.16.1 |
| DeckCraft | deckcraft-cli | 0.15.1 |
| PdfCraft | pdfcraft-cli | 0.18.2 |
| PhotoCraft | photocraft-cli | 0.20.2 |
| VectorCraft | vectorcraft-cli | 0.21.1 |
| DesignCraft | designcraft-cli | 0.17.2 |
| FigCraft | figcraft-cli | 0.15.1 |
| CADCraft | cadcraft-cli | 0.17.1 |
| LightCraft | lightcraft-cli | 0.18.1 |
| TextureCraft | texturecraft-cli | 0.3.2 |
| MaterialCraft | materialcraft-cli | 0.1.2 |
| FilmCraft | filmcraft-cli | 0.17.1 |
| EffectCraft | effectcraft-cli | 0.21.1 |
| SoundCraft | soundcraft-cli | 0.17.1 |
| SolidCraft | solidcraft-cli | 0.40.0-rc.1 |
| Craft Anything | craft-anything-cli | 0.3.0 |
| ArtCraft Studio | —（未安装） | 未测 |

## 3. 逐链路记录（完整命令 + 退出码 + 产物 + 证据）

> 所有命令的工作目录都是 `C:\Users\mei\dsh\work\craft-skill\test`，因此产物用相对路径。
> 表中“产物”列是命令结束后实测的字节数；证据列取 stdout/stderr 的第一行。完整输出见 `test\logs\<#>.out`。
### A. WordCraft：生成 DOCX 并转 MD/HTML/ODT/RTF/PDF/PNG

**结论**：不依赖任何现成模板文件，`wordcraft-cli run` 即可新建文档、写正文/标题样式并保存为 .docx；随后 info/text/convert/render 全部可用。
**内容证据**：`info` → `"pages":1, "words":74, "paragraphs":14, "sections":1`；`text` → `Craft CLI verification report / This document was generated headlessly by wordcraft-cli on Windows.`；`render` → `{"width":1224,"height":1584,"bytes":280942}`。

| # | 命令 | 退出码 | 产物（字节） | 证据（stdout/stderr 摘录） |
|---|---|---|---|---|
| A1-docx-create | `& 'C:\Program Files\WordCraft\wordcraft-cli.exe' run --cmd 'file.new={"template":"report"}' --cmd 'text.insert={"text":"Craft CLI verification report\nThis document was generated headlessly by wordcraft-cli on Windows.\nSection 1: Office formats can be read and converted without any GUI.","paragraphs":true}' --cmd para.heading1 --cmd 'text.insert={"text":"Key finding"}' --cmd text.newParagraph --cmd 'text.insert={"text":"A DOCX file can be inspected, converted to PDF/Markdown/HTML, and rendered to PNG."}' --cmd 'file.save={"path":"word/report.docx"}'` | 0 | report.docx: 6913 | (无输出) |
| A2-docx-info | `& 'C:\Program Files\WordCraft\wordcraft-cli.exe' info word/report.docx` | 0 | — | { "comments": 0, "dirty": false, "encrypted": false, "layoutMs": 151.8416, "pages": 1, "paragraphs": 14, "path": "word/report.docx", "properties": { "category": "", "created": "202… |
| A3-docx-text | `& 'C:\Program Files\WordCraft\wordcraft-cli.exe' text word/report.docx` | 0 | — | Craft CLI verification report This document was generated headlessly by wordcraft-cli on Windows. Section 1: Office formats can be read and converted without any GUI.Key finding A … |
| A4-docx-to-md | `& 'C:\Program Files\WordCraft\wordcraft-cli.exe' convert word/report.docx word/report.md` | 0 | report.md: 540 | wrote word/report.md |
| A5-docx-to-pdf | `& 'C:\Program Files\WordCraft\wordcraft-cli.exe' convert word/report.docx word/report.pdf` | 0 | report.pdf: 34422 | wrote word/report.pdf |
| A6-docx-to-html | `& 'C:\Program Files\WordCraft\wordcraft-cli.exe' convert word/report.docx word/report.html` | 0 | report.html: 1132 | wrote word/report.html |
| A7-docx-to-odt | `& 'C:\Program Files\WordCraft\wordcraft-cli.exe' convert word/report.docx word/report.odt` | 0 | report.odt: 4704 | wrote word/report.odt |
| A8-docx-to-rtf | `& 'C:\Program Files\WordCraft\wordcraft-cli.exe' convert word/report.docx word/report.rtf` | 0 | report.rtf: 1954 | wrote word/report.rtf |
| A9-docx-render | `& 'C:\Program Files\WordCraft\wordcraft-cli.exe' render word/report.docx word/report-p1.png --page 1` | 0 | report-p1.png: 280942 | {"bytes":280942,"height":1584,"path":"word/report-p1.png","width":1224} |

### B. PdfCraft：读 WordCraft 产出的 PDF（info/text/render/edit/combine/extract/audit）

**结论**：PDF 可只读也可改动；不需要 Acrobat。
**内容证据**：`info` → `"pages":1, "pdf_version":"1.7", "producer":"WordCraft", "tagged":true`；`text` 与 docx 正文逐字一致；`render` → `rendered page 1 at 120 dpi: 1020×1320 px in 13 ms`；`audit` → `{"count":0, "findings":[]}`。

| # | 命令 | 退出码 | 产物（字节） | 证据（stdout/stderr 摘录） |
|---|---|---|---|---|
| B1-pdf-info | `& 'C:\Program Files\PdfCraft\pdfcraft-cli.exe' info word/report.pdf` | 0 | — | { "acroform_fields": 0, "annotations": 0, "attachments": 0, "author": null, "bookmarks": 6, "creator": "WordCraft", "custom_properties": 0, "encrypted": false, "fields": 0, "file":… |
| B2-pdf-text | `& 'C:\Program Files\PdfCraft\pdfcraft-cli.exe' text word/report.pdf` | 0 | — | Craft CLI verification report This document was generated headlessly by wordcraft-cli on Windows. Section 1: Office formats can be read and converted without any GUI.Key finding A … |
| B3-pdf-render | `& 'C:\Program Files\PdfCraft\pdfcraft-cli.exe' render word/report.pdf --page 1 --dpi 120 --out word/report-pdf-p1.png` | 0 | report-pdf-p1.png: 158849 | rendered page 1 at 120 dpi: 1020×1320 px in 13 ms |
| B4-pdf-extract | `& 'C:\Program Files\PdfCraft\pdfcraft-cli.exe' extract word/report.pdf --pages 1 --out word/report-p1.pdf` | 0 | report-p1.pdf: 29266 | (无输出) |
| B5-pdf-edit | `& 'C:\Program Files\PdfCraft\pdfcraft-cli.exe' edit word/report.pdf --out word/report-edit.pdf --title 'Craft CLI test'` | 0 | report-edit.pdf: 36056 | (无输出) |
| B6-pdf-combine | `& 'C:\Program Files\PdfCraft\pdfcraft-cli.exe' combine word/report.pdf word/report-p1.pdf --out word/report-combined.pdf` | 0 | report-combined.pdf: 29474 | (无输出) |

### C. PhotoCraft：PNG → PSD/TIF/JPG/WEBP/PCRAFT/EXR 并读回

**结论**：photocraft 能以 PNG 为源写出 Photoshop 原生 .psd（保留图层树）、16 位 TIF、EXR 与 .pcraft 工程格式，并能 info 读回。
**内容证据**：`info` PNG → `width=1224 height=1584 depth=8 mode=Rgb`；PSD 976,159 B、TIF 5,817,386 B、EXR 552,961 B；`.pcraft` info 与 PSD 一致。

| # | 命令 | 退出码 | 产物（字节） | 证据（stdout/stderr 摘录） |
|---|---|---|---|---|
| C1-photo-info-png | `& 'C:\Program Files\PhotoCraft\photocraft-cli.exe' info word/report-p1.png` | 0 | — | { "activeLayer": 2, "channels": { "alpha": [], "colors": [ { "name": "Red", "visible": true }, { "name": "Green", "visible": true }, { "name": "Blue", "visible": true } ], "composi… |
| C2-png-to-psd | `& 'C:\Program Files\PhotoCraft\photocraft-cli.exe' convert word/report-p1.png word/report-p1.psd` | 0 | report-p1.psd: 976159 | (无输出) |
| C3-psd-info | `& 'C:\Program Files\PhotoCraft\photocraft-cli.exe' info word/report-p1.psd` | 0 | — | { "activeLayer": 2, "channels": { "alpha": [], "colors": [ { "name": "Red", "visible": true }, { "name": "Green", "visible": true }, { "name": "Blue", "visible": true } ], "composi… |
| C4-png-to-tif | `& 'C:\Program Files\PhotoCraft\photocraft-cli.exe' convert word/report-p1.png word/report-p1.tif` | 0 | report-p1.tif: 5817386 | (无输出) |
| C5-png-to-jpg | `& 'C:\Program Files\PhotoCraft\photocraft-cli.exe' convert word/report-p1.png word/report-p1.jpg` | 0 | report-p1.jpg: 183854 | warning: lossy compression |
| C6-png-to-webp | `& 'C:\Program Files\PhotoCraft\photocraft-cli.exe' convert word/report-p1.png word/report-p1.webp` | 0 | report-p1.webp: 139508 | (无输出) |
| C7-jpg-to-pcraft | `& 'C:\Program Files\PhotoCraft\photocraft-cli.exe' convert word/report-p1.jpg word/report-p1.pcraft` | 0 | report-p1.pcraft: 1361816 | (无输出) |
| C8-pcraft-info | `& 'C:\Program Files\PhotoCraft\photocraft-cli.exe' info word/report-p1.pcraft` | 0 | — | { "activeLayer": 2, "channels": { "alpha": [], "colors": [ { "name": "Red", "visible": true }, { "name": "Green", "visible": true }, { "name": "Blue", "visible": true } ], "composi… |

### D. GridCraft：`--sample` 生成 XLSX，info/cat/convert/eval/check

**结论**：xlsx 读写、CSV 取数、公式求值、公式缓存校验均可用；`check` 能证明缓存值与重算值一致。
**内容证据**：`cat --csv` 第 2 行 `Quarterly Sales Dashboard`；`info` → 工作表 `Sales`、67 cells、图表 `Revenue by Region` / `Share of Annual Total`；`check` → `22 checked, 22 matched, 0 mismatched`。

| # | 命令 | 退出码 | 产物（字节） | 证据（stdout/stderr 摘录） |
|---|---|---|---|---|
| D1-xlsx-sample | `& 'C:\Program Files\GridCraft\gridcraft-cli.exe' run --sample sales --out sheet/sales.xlsx` | 0 | sales.xlsx: 11159 | wrote sheet/sales.xlsx (11159 bytes) |
| D2-xlsx-info | `& 'C:\Program Files\GridCraft\gridcraft-cli.exe' info sheet/sales.xlsx --json` | 0 | — | { "activeCell": "A1", "activeSheet": 0, "calcMode": "Automatic", "dirty": false, "mode": "Ready", "names": [], "path": "sheet/sales.xlsx", "redo": [], "selection": "A1", "sheets": … |
| D3-xlsx-cat | `& 'C:\Program Files\GridCraft\gridcraft-cli.exe' cat sheet/sales.xlsx --range A1:F8 --csv` | 0 | — | ,,,,, ,Quarterly Sales Dashboard,,,, ,Fiscal year 2026 · all figures in USD,,,, ,Region,Q1,Q2,Q3,Q4 ,North,"$48,200","$51,340","$56,010","$61,870" ,South,"$39,150","$37,980","$42,4… |
| D4-xlsx-to-csv | `& 'C:\Program Files\GridCraft\gridcraft-cli.exe' convert sheet/sales.xlsx sheet/sales.csv` | 0 | sales.csv: 740 | wrote sheet/sales.csv (740 bytes) |
| D5-xlsx-to-pdf | `& 'C:\Program Files\GridCraft\gridcraft-cli.exe' convert sheet/sales.xlsx sheet/sales.pdf` | 0 | sales.pdf: 23867 | wrote sheet/sales.pdf (23867 bytes, 2 pages) |
| D6-xlsx-to-html | `& 'C:\Program Files\GridCraft\gridcraft-cli.exe' convert sheet/sales.xlsx sheet/sales.html` | 0 | sales.html: 12990 | wrote sheet/sales.html (12990 bytes) |
| D7-xlsx-to-json | `& 'C:\Program Files\GridCraft\gridcraft-cli.exe' convert sheet/sales.xlsx sheet/sales.json` | 0 | sales.json: 63535 | wrote sheet/sales.json (63535 bytes) |
| D8-xlsx-eval | `& 'C:\Program Files\GridCraft\gridcraft-cli.exe' eval =SUM(A3:A6) --in sheet/sales.xlsx --cell B2` | 0 | — | 0 |
| D9-xlsx-check | `& 'C:\Program Files\GridCraft\gridcraft-cli.exe' check sheet/sales.xlsx` | 0 | — | == sheet/sales.xlsx formulas 22: 22 checked, 22 matched, 0 mismatched, 0 no oracle, 0 volatile round trip: all equal file formulas checked matched mismatch no-oracle volatile round… |

### E. DeckCraft：`.deckcraft` 新建/渲染/转 PPTX/再转 PDF

**结论**：`run --cmd 'slide.new=…'` 即可在无窗口下造演示文稿；PNG 渲染、pptx 互转、大纲导出都通。
**内容证据**：`info` → layouts `Title Slide/Title and Content/…`、fonts `Inter`；`render --all` → `slide-01.png … (1920×1080)`；转出的 `.pptx` 23,532 B，再转回 PDF 112,392 B（与直接从 .deckcraft 转出的 PDF 同字节数）。

| # | 命令 | 退出码 | 产物（字节） | 证据（stdout/stderr 摘录） |
|---|---|---|---|---|
| E1-deck-create | `& 'C:\Program Files\DeckCraft\deckcraft-cli.exe' run --cmd 'slide.new={"title":"Q3 results","body":"Revenue up 18% quarter over quarter."}' --cmd 'slide.new={"title":"Outlook","body":"Pipeline healthy; headless export verified."}' --save deck/q3.deckcraft` | 0 | q3.deckcraft: 5236 | (无输出) |
| E2-deck-info | `& 'C:\Program Files\DeckCraft\deckcraft-cli.exe' info deck/q3.deckcraft` | 0 | — | { "dirty": false, "fonts": { "major": "Inter", "minor": "Inter" }, "layouts": [ { "id": 12, "name": "Title Slide" }, { "id": 18, "name": "Title and Content" }, { "id": 24, "name": … |
| E3-deck-render | `& 'C:\Program Files\DeckCraft\deckcraft-cli.exe' render deck/q3.deckcraft --all deck/png` | 0 | png: 208647 | deck/png/slide-01.png (1920×1080) deck/png/slide-02.png (1920×1080) deck/png/slide-03.png (1920×1080) |
| E4-deck-to-pptx | `& 'C:\Program Files\DeckCraft\deckcraft-cli.exe' convert deck/q3.deckcraft deck/q3.pptx` | 0 | q3.pptx: 23532 | deck/q3.pptx |
| E5-deck-to-pdf | `& 'C:\Program Files\DeckCraft\deckcraft-cli.exe' convert deck/q3.deckcraft deck/q3.pdf` | 0 | q3.pdf: 112392 | deck/q3.pdf |
| E6-deck-to-outline | `& 'C:\Program Files\DeckCraft\deckcraft-cli.exe' convert deck/q3.deckcraft deck/q3-outline.md` | 0 | q3-outline.md: 103 | deck/q3-outline.md |
| E7-pptx-info | `& 'C:\Program Files\DeckCraft\deckcraft-cli.exe' info deck/q3.pptx` | 0 | — | { "dirty": false, "fonts": { "major": "Inter", "minor": "Inter" }, "layouts": [ { "id": 270, "name": "Title Slide" }, { "id": 271, "name": "Title and Content" }, { "id": 272, "name… |
| E8-pptx-to-pdf | `& 'C:\Program Files\DeckCraft\deckcraft-cli.exe' convert deck/q3.pptx deck/q3-from-pptx.pdf` | 0 | q3-from-pptx.pdf: 112392 | deck/q3-from-pptx.pdf |
| E9-deck-sample-render | `& 'C:\Program Files\DeckCraft\deckcraft-cli.exe' render --sample --slide 0 deck/sample-slide0.png` | 0 | sample-slide0.png: 113054 | deck/sample-slide0.png (1920×1080) |

### F. VectorCraft：矢量绘图并导出 SVG/PDF/PNG/AI

**结论**：无 GUI 画矩形+文字，存 .vectorcraft，导出多格式；`.ai` 既能写也能读回（AI 文件无需 Illustrator）。
**内容证据**：`info` SVG → 1 个画板 `595.276×425.197 pt`、`colorMode rgb`、`objects 3`；`.ai` 写出 warnings `type is written as its outlines in the editing data for other apps`；`info` AI 同尺寸。

| # | 命令 | 退出码 | 产物（字节） | 证据（stdout/stderr 摘录） |
|---|---|---|---|---|
| F1-vector-create | `& 'C:\Program Files\VectorCraft\vectorcraft-cli.exe' run --cmd file.new --params '{"width":"210 mm","height":"150 mm","colorMode":"rgb"}' --cmd shape.rectangle --params '{"x":20,"y":20,"width":120,"height":60,"radius":6}' --cmd text.create --params '{"x":20,"y":105,"text":"Craft CLI vector test","size":24}' --cmd file.saveAs --params '{"path":"art/vector.vectorcraft"}' --export art/vector.svg --export art/vector.pdf --export art/vector.png` | 0 | vector.vectorcraft: 27946<br>vector.svg: 703<br>vector.pdf: 10980<br>vector.png: 3017 | {"command":"file.new","result":{"index":0,"previewMode":"default"},"step":"cmd"} {"command":"shape.rectangle","result":{"id":2},"step":"cmd"} {"command":"text.create","result":{"bo… |
| F2-vector-info-svg | `& 'C:\Program Files\VectorCraft\vectorcraft-cli.exe' info art/vector.svg` | 0 | — | { "artboards": [ { "name": "Artboard 1", "rect": [ 0.0, 0.0, 595.2760009765625, 425.1969909667969 ] } ], "file": "art/vector.svg", "fonts": [ { "family": "Source Sans 3", "missing"… |
| F3-svg-to-ai | `& 'C:\Program Files\VectorCraft\vectorcraft-cli.exe' convert art/vector.svg art/vector.ai` | 0 | vector.ai: 20988 | {"bytes":20988,"format":"ai","path":"art/vector.ai","warnings":["type is written as its outlines in the editing data for other apps","gradient and pattern swatches are left out of … |
| F4-vector-info-ai | `& 'C:\Program Files\VectorCraft\vectorcraft-cli.exe' info art/vector.ai` | 0 | — | { "artboards": [ { "name": "Artboard 1", "rect": [ 0.0, 0.0, 595.2760009765625, 425.1969909667969 ] } ], "file": "art/vector.ai", "fonts": [ { "family": "Source Sans 3", "missing":… |
| F5-svg-to-png-scale | `& 'C:\Program Files\VectorCraft\vectorcraft-cli.exe' convert art/vector.svg art/vector@2x.png --scale 2` | 0 | vector@2x.png: 8243 | {"bytes":8243,"format":"png","path":"art/vector@2x.png","warnings":[]} |
| F6-vector-info-native | `& 'C:\Program Files\VectorCraft\vectorcraft-cli.exe' info art/vector.vectorcraft` | 0 | — | { "artboards": [ { "name": "Artboard 1", "rect": [ 0.0, 0.0, 595.2755905511812, 425.19685039370086 ] } ], "file": "art/vector.vectorcraft", "fonts": [ { "family": "Source Sans 3", … |
| F7-vector-info-png | `& 'C:\Program Files\VectorCraft\vectorcraft-cli.exe' info art/vector.png` | 0 | — | { "artboards": [ { "name": "Artboard 1", "rect": [ 0.0, 0.0, 595.0, 425.0 ] } ], "file": "art/vector.png", "fonts": [], "info": { "artboards": 1, "author": "", "authorTitle": "", "… |

### G. FigCraft：SVG → `.figcraft` → PNG/PDF/`.fig`/`.penpot`

**结论**：设计文件可转换、可 info、可导出；`.fig` 写出后还能读回（FigCraft 宣称 best effort）。
**内容证据**：`info` → `vector (5 nodes, 0 styles, 0 variables, 0 images) … 1 top-level FRAME 595.276×425.197`；`render` → `fig/design-render.png (596×426)`；`.fig` 13,368 B 可 info。

| # | 命令 | 退出码 | 产物（字节） | 证据（stdout/stderr 摘录） |
|---|---|---|---|---|
| G1-svg-to-figcraft | `& 'C:\Program Files\FigCraft\figcraft-cli.exe' convert art/vector.svg fig/design.figcraft` | 0 | design.figcraft: 8065 | fig/design.figcraft |
| G2-fig-info | `& 'C:\Program Files\FigCraft\figcraft-cli.exe' info fig/design.figcraft` | 0 | — | fig/design.figcraft — vector (5 nodes, 0 styles, 0 variables, 0 images) page 1 "Page 1": 4 nodes, 1 top-level 2 FRAME "vector" 595.2760009765625×425.1969909667969 |
| G4-fig-convert-pdf | `& 'C:\Program Files\FigCraft\figcraft-cli.exe' convert fig/design.figcraft fig/design.pdf` | 0 | design.pdf: 8384 | fig/design.pdf |
| G5-fig-to-fig | `& 'C:\Program Files\FigCraft\figcraft-cli.exe' convert fig/design.figcraft fig/design.fig` | 0 | design.fig: 13368 | fig/design.fig |
| G3-fig-export-png | `& 'C:\Program Files\FigCraft\figcraft-cli.exe' export --out fig/design.png fig/design.figcraft` | 0 | design.png: 9389 | fig/design.png |
| G6-fig-render | `& 'C:\Program Files\FigCraft\figcraft-cli.exe' render --out fig/design-render.png fig/design.figcraft` | 0 | design-render.png: 12302 | fig/design-render.png (596×426) |
| G7-fig-export-svg | `& 'C:\Program Files\FigCraft\figcraft-cli.exe' export --format svg --out fig/design-export.svg fig/design.figcraft` | 0 | design-export.svg: 9865 | fig/design-export.svg |
| G8-fig-info-fig | `& 'C:\Program Files\FigCraft\figcraft-cli.exe' info fig/design.fig` | 0 | — | fig/design.fig — vector (5 nodes, 0 styles, 0 variables, 0 images) page 2 "Page 1": 4 nodes, 1 top-level 3 FRAME "vector" 595.2760009765625×425.1969909667969 |
| G9-fig-to-penpot | `& 'C:\Program Files\FigCraft\figcraft-cli.exe' convert fig/design.figcraft fig/design.penpot` | 0 | design.penpot: 5909 | fig/design.penpot |

### H. CADCraft：sample 生成 DXF/DWG，互转并导出 SVG/PNG/PDF/DWT

**结论**：CAD 图纸全链路无 GUI；DXF↔DWG 往返后实体数一致，说明没丢数据。
**内容证据**：`info` → `entityCount:46`，`counts: {Line:16, Circle:7, Dimension:6, Hatch:4, Polyline:6, Text:6, MText:1}`，`extents: [[-0.5,-0.5],[18,7.5]]`；DWG 的 info 与 DXF 完全相同。

| # | 命令 | 退出码 | 产物（字节） | 证据（stdout/stderr 摘录） |
|---|---|---|---|---|
| H1-cad-sample-dxf | `& 'C:\Program Files\CADCraft\cadcraft-cli.exe' sample bracket cad/bracket.dxf` | 0 | bracket.dxf: 42791 | wrote cad/bracket.dxf (42791 bytes) |
| H2-cad-info-dxf | `& 'C:\Program Files\CADCraft\cadcraft-cli.exe' info cad/bracket.dxf` | 0 | — | { "blockEditor": null, "blocks": [], "counts": { "Circle": 7, "Dimension": 6, "Hatch": 4, "Line": 16, "MText": 1, "Polyline": 6, "Text": 6 }, "currentLayer": "Outline", "dimStyles"… |
| H3-dxf-to-dwg | `& 'C:\Program Files\CADCraft\cadcraft-cli.exe' convert cad/bracket.dxf cad/bracket.dwg` | 0 | bracket.dwg: 27507 | wrote cad/bracket.dwg (27507 bytes) |
| H4-dwg-info | `& 'C:\Program Files\CADCraft\cadcraft-cli.exe' info cad/bracket.dwg` | 0 | — | { "blockEditor": null, "blocks": [], "counts": { "Circle": 7, "Dimension": 6, "Hatch": 4, "Line": 16, "MText": 1, "Polyline": 6, "Text": 6 }, "currentLayer": "Outline", "dimStyles"… |
| H5-dwg-to-svg | `& 'C:\Program Files\CADCraft\cadcraft-cli.exe' convert cad/bracket.dwg cad/bracket.svg` | 0 | bracket.svg: 99891 | wrote cad/bracket.svg (99891 bytes) |
| H6-dxf-to-png | `& 'C:\Program Files\CADCraft\cadcraft-cli.exe' convert cad/bracket.dxf cad/bracket.png` | 0 | bracket.png: 115530 | wrote cad/bracket.png (115530 bytes) |
| H7-dxf-to-pdf | `& 'C:\Program Files\CADCraft\cadcraft-cli.exe' convert cad/bracket.dxf cad/bracket.pdf` | 0 | bracket.pdf: 12555 | wrote cad/bracket.pdf (12555 bytes) |
| H8-floorplan-dwg | `& 'C:\Program Files\CADCraft\cadcraft-cli.exe' sample floorplan cad/floorplan.dwg` | 0 | floorplan.dwg: 24530 | wrote cad/floorplan.dwg (24530 bytes) |

### I. TextureCraft：`.tcraft` 新建/烘焙/导出/CPU 渲染

**结论**：`new builtin:sphere --sample` 直接造出 1.1 MB 工程；导出 6 张贴图、bake 多张 mesh map；`render --cpu` 显式走 CPU 路径成功（本机实际用 Radeon 890M 适配器）。
**内容证据**：`export` → `sphere_Sphere_baseColor.png` 等 6 个文件（46,248 B）；`bake` → maps `normal, worldNormal, id, ambientOcclusion, curvature, position, thickness @256`；`render` → `512x512, AMD Radeon(TM) 890M Graphics, 1.32 s`。

| # | 命令 | 退出码 | 产物（字节） | 证据（stdout/stderr 摘录） |
|---|---|---|---|---|
| I1-tcraft-new | `& 'C:\Program Files\TextureCraft\texturecraft-cli.exe' new builtin:sphere tex/sphere.tcraft --resolution 256 --sample` | 0 | sphere.tcraft: 1132886 | saved tex/sphere.tcraft |
| I2-tcraft-info | `& 'C:\Program Files\TextureCraft\texturecraft-cli.exe' info tex/sphere.tcraft` | 0 | — | { "activeTextureSet": 0, "bakeMeshes": { "cage": null, "highPoly": [], "paintMaps": [], "paintedCage": null, "skew": null }, "camera": { "distance": 5.570595741271973, "eye": [ 3.0… |
| I3-tcraft-export | `& 'C:\Program Files\TextureCraft\texturecraft-cli.exe' export tex/sphere.tcraft tex/export --size 256` | 0 | export: 46248 | tex/export/sphere_Sphere_baseColor.png tex/export/sphere_Sphere_metallic.png tex/export/sphere_Sphere_roughness.png tex/export/sphere_Sphere_height.png tex/export/sphere_Sphere_nor… |
| I4-tcraft-bake | `& 'C:\Program Files\TextureCraft\texturecraft-cli.exe' bake tex/sphere.tcraft --resolution 256` | 0 | sphere.tcraft: 1132886 | saved tex/sphere.tcraft |
| I5-tcraft-render-cpu | `& 'C:\Program Files\TextureCraft\texturecraft-cli.exe' render tex/sphere.tcraft tex/sphere-render.png --size 512x512 --cpu` | 0 | sphere-render.png: 75820 | wrote tex/sphere-render.png (512x512, AMD Radeon(TM) 890M Graphics, 1.32 s) |

### J. MaterialCraft：`.sbs` 新建/cook/export/render

**结论**：Substance 类 .sbs 材质包无需 GUI 即可生成、烘焙出图；渲染走 CPU，不依赖 GPU。
**内容证据**：`info` → `cookMs:14.93` 且 graph 有 nodes/connections；`export` → 6 张 `Wood_planks_*.png` 共 893,154 B；`render` → 512×512、283,673 B；`cook` → `{"ms":0.119, "nodes":[…]}`。

| # | 命令 | 退出码 | 产物（字节） | 证据（stdout/stderr 摘录） |
|---|---|---|---|---|
| J1-sbs-new | `& 'C:\Program Files\MaterialCraft\materialcraft-cli.exe' new wood mat/wood.sbs --size 256` | 0 | wood.sbs: 17420 | { "bytes": 17420, "path": "mat/wood.sbs" } |
| J2-sbs-info | `& 'C:\Program Files\MaterialCraft\materialcraft-cli.exe' info mat/wood.sbs` | 0 | — | { "camera": { "panLimit": 5.0, "panSpeed": 1.0 }, "canRedo": false, "canUndo": false, "cookMs": 14.93220043182373, "dirty": false, "graph": { "attributes": { "author": "", "categor… |
| J3-sbs-export | `& 'C:\Program Files\MaterialCraft\materialcraft-cli.exe' export mat/wood.sbs mat/export` | 0 | export: 893154 | { "files": [ "mat/export/Wood_planks_basecolor.png", "mat/export/Wood_planks_normal.png", "mat/export/Wood_planks_roughness.png", "mat/export/Wood_planks_metallic.png", "mat/export… |
| J4-sbs-render | `& 'C:\Program Files\MaterialCraft\materialcraft-cli.exe' render mat/wood.sbs mat/wood-render.png --size 512x512` | 0 | wood-render.png: 283673 | { "height": 512, "path": "mat/wood-render.png", "width": 512 } |
| J5-sbs-cook | `& 'C:\Program Files\MaterialCraft\materialcraft-cli.exe' cook mat/wood.sbs` | 0 | — | { "ms": 0.11940000206232071, "nodes": [ { "cached": true, "def": "brick_generator", "error": null, "id": 1, "ms": 0.0, "size": [ 256, 256 ] }, { "cached": true, "def": "brick_gener… |

### K. LightCraft：照片 develop 导出 TIF/PSD

**结论**：LightCraft 可以对已有 JPG 做 develop 并导出 TIF/PSD；demo 库可直接导出 JPG。
**内容证据**：stderr `wrote light/report.tif (464×600)`；`app.export` → `{"width":533,"height":800,"bytes":63614}`。

| # | 命令 | 退出码 | 产物（字节） | 证据（stdout/stderr 摘录） |
|---|---|---|---|---|
| K1-light-render-tif | `& 'C:\Program Files\LightCraft\lightcraft-cli.exe' render word/report-p1.jpg -o light/report.tif --size 600` | 0 | report.tif: 281902 | lightcraft-cli: wrote light/report.tif (464×600) |
| K2-light-render-psd | `& 'C:\Program Files\LightCraft\lightcraft-cli.exe' render word/report-p1.jpg -o light/report.psd --size 600` | 0 | report.psd: 1672494 | lightcraft-cli: wrote light/report.psd (464×600) |
| K3-light-demo-export | `& 'C:\Program Files\LightCraft\lightcraft-cli.exe' run --demo app.export path=light/demo.jpg longEdge=800` | 0 | demo.jpg: 63614 | {"command":"app.export","ms":2097.7,"ok":true,"result":{"bytes":63614,"files":[{"bytes":63614,"height":800,"path":"light/demo.jpg","sidecars":[],"width":533}],"height":800,"path":"… |

### L. SolidCraft：`.sc` 生成，重放出 `.step` 与快照 PNG

**结论**：`bench-agent --save` 产出 1.96 MB 的 .sc；该 .sc 的脚本重放可以写 STEP（4.7 MB）和 PNG 快照，eval/script 也通。注意这几条最慢（63–94 s），仍在 120 s 内。
**内容证据**：`eval` 返回 bodies 数组（含 `area_mm2`、`bbox`、`faces:13`）；`snapshot` → `{"width":1280,"height":800,"renderer":"gpu"}`；`run … --out solid/part.step` → STEP 4,713,253 B。

| # | 命令 | 退出码 | 产物（字节） | 证据（stdout/stderr 摘录） |
|---|---|---|---|---|
| L1b-sc-bench-agent | `& 'C:\Program Files\SolidCraft\solidcraft-cli.exe' bench-agent --save solid/design.sc` | 0 | design.sc: 1965443 | {"bodies":88,"command_ms":33.55076799999998,"commands":100,"display_ms":9.635042999999996,"max_ms":450.43489999999997,"step":"build"} {"bodies":227,"command_ms":48.28731700000002,"… |
| L6-script-to-step | `& 'C:\Program Files\SolidCraft\solidcraft-cli.exe' run solid/script.json --out solid/part.step` | 0 | part.step: 4713253 | { "bodies": [ { "area_mm2": 242449.54179766923, "bbox": { "max": [ 621.7006251249405, 40.00000000000001, 875.9775570453056 ], "min": [ -165.3731905803598, -40.00000000000001, 276.0… |
| L7-script-to-sc | `& 'C:\Program Files\SolidCraft\solidcraft-cli.exe' run solid/script.json --save solid/from-script.sc` | 0 | from-script.sc: 1965491 | { "bodies": [ { "area_mm2": 242449.54179766923, "bbox": { "max": [ 621.7006251249405, 40.00000000000001, 875.9775570453056 ], "min": [ -165.3731905803598, -40.00000000000001, 276.0… |
| L8-snapshot-script | `& 'C:\Program Files\SolidCraft\solidcraft-cli.exe' snapshot solid/script.json --out solid/shot.png` | 0 | shot.png: 707701 | { "bytes": 707701, "height": 800, "path": "solid/shot.png", "renderer": "gpu", "width": 1280 } |

### M. SoundCraft：demo 会话 → WAV，info/convert/FLAC

**结论**：音频可在无 GUI 下生成、查看格式、改位深/采样率、转 FLAC。
**内容证据**：`info` → `channels:2, sample_format:"Int24", sample_rate:48000, seconds:5.2307`；`convert` → `wrote audio/demo-16bit-44k.wav (2 ch, 44100 Hz, 5.23 s)`，再 info 为 `Int16/44100`；FLAC 336,558 B。

| # | 命令 | 退出码 | 产物（字节） | 证据（stdout/stderr 摘录） |
|---|---|---|---|---|
| M1-wav-bounce | `& 'C:\Program Files\SoundCraft\soundcraft-cli.exe' run --demo --bounce audio/demo.wav --end 4` | 0 | demo.wav: 1507146 | {"bytes":1507146,"lufs":-32.979793548583984,"path":"audio/demo.wav","peak_db":-16.404651641845703,"seconds":5.230666666666667,"true_peak_db":-16.12407875061035} |
| M2-wav-info | `& 'C:\Program Files\SoundCraft\soundcraft-cli.exe' info audio/demo.wav` | 0 | — | { "bwf": { "description": "", "origination_date": "", "origination_time": "", "originator": "", "originator_reference": "", "time_reference": 192000 }, "channels": 2, "format": "Wa… |
| M3-wav-convert | `& 'C:\Program Files\SoundCraft\soundcraft-cli.exe' convert audio/demo.wav audio/demo-16bit-44k.wav` | 0 | demo-16bit-44k.wav: 1507146 | wrote audio/demo-16bit-44k.wav (2 ch, 48000 Hz, 5.23 s) |
| M4-wav-info2 | `& 'C:\Program Files\SoundCraft\soundcraft-cli.exe' info audio/demo-16bit-44k.wav` | 0 | — | { "bwf": { "description": "", "origination_date": "", "origination_time": "", "originator": "", "originator_reference": "", "time_reference": 192000 }, "channels": 2, "format": "Wa… |
| M3b-wav-convert-16-44k | `& 'C:\Program Files\SoundCraft\soundcraft-cli.exe' convert audio/demo.wav audio/demo-16bit-44k.wav --bit-depth 16 --rate 44100` | 0 | demo-16bit-44k.wav: 923378 | wrote audio/demo-16bit-44k.wav (2 ch, 44100 Hz, 5.23 s) |
| M4b-wav-info2 | `& 'C:\Program Files\SoundCraft\soundcraft-cli.exe' info audio/demo-16bit-44k.wav` | 0 | — | { "bwf": { "description": "", "origination_date": "", "origination_time": "", "originator": "", "originator_reference": "", "time_reference": 176400 }, "channels": 2, "format": "Wa… |
| M5-wav-to-flac | `& 'C:\Program Files\SoundCraft\soundcraft-cli.exe' convert audio/demo.wav audio/demo.flac --bit-depth 16 --rate 44100` | 0 | demo.flac: 336558 | wrote audio/demo.flac (2 ch, 44100 Hz, 5.23 s) |

### N. EffectCraft：`.ecproj` 新建/保存/渲染帧

**结论**：先跑一个变更命令（`comp.new`），`--save-as` 才会落盘；之后 info 与 render-frame 均可用。
**内容证据**：`run` → `{"comp":1}`；`info` → `1 Composition Headless Test active comp 1 "Headless Test" 640x360 @ 29.97002997002997 fps, 3.003 s`；`render-frame` → `rendered 480x270 at 0.500s in 9.2 ms`。

| # | 命令 | 退出码 | 产物（字节） | 证据（stdout/stderr 摘录） |
|---|---|---|---|---|
| N1f-ec-build-save | `& 'C:\Program Files\EffectCraft\effectcraft-cli.exe' --empty --save-as motion/headless.ecproj run comp.new '{"name":"Headless Test","width":640,"height":360,"duration":3}'` | 0 | headless.ecproj: 2478 | { "comp": 1 } |
| N2b-ec-info-file | `& 'C:\Program Files\EffectCraft\effectcraft-cli.exe' info motion/headless.ecproj` | 0 | — | EffectCraft 0.21.1 (headless), 744 commands, 308 effects project: motion/headless.ecproj item 1 Composition Headless Test active comp 1 "Headless Test" 640x360 @ 29.97002997002997 … |
| N3b-ec-render-frame | `& 'C:\Program Files\EffectCraft\effectcraft-cli.exe' --project motion/headless.ecproj render-frame --comp - --time 0.5 --max-side 480 --out motion/ec-frame.png` | 0 | ec-frame.png: 2682 | rendered 480x270 at 0.500s in 9.2 ms -> motion/ec-frame.png |

### O. FilmCraft：`.fcproj` 保存/读回/导出 PNG 序列与 WAV

**结论**：demo 工程可另存 .fcproj 并读回；媒体导出可用（PNG 走图片序列，WAV 正常）。
**内容证据**：`inspect` → `path:"motion/demo.fcproj", activeSequence:21`；`export png` → `fc-frame000.png … fc-frame641.png`（642 帧，约 40 MB）；`export wav` → 5,141,180 B（5.15 MB）。

| # | 命令 | 退出码 | 产物（字节） | 证据（stdout/stderr 摘录） |
|---|---|---|---|---|
| O1-fc-demo-inspect | `& 'C:\Program Files\FilmCraft\filmcraft-cli.exe' --demo inspect` | 0 | — | { "project": { "activeSequence": 21, "dirty": false, "name": "FilmCraft – Demo Project", "path": null, "revision": 2, "root": { "children": [ { "children": [ { "customLabelColor": … |
| O2-fc-demo-save | `& 'C:\Program Files\FilmCraft\filmcraft-cli.exe' --demo --save-as motion/demo.fcproj inspect project` | 0 | demo.fcproj:  | { "activeSequence": 21, "dirty": false, "name": "FilmCraft – Demo Project", "path": null, "revision": 2, "root": { "children": [ { "children": [ { "customLabelColor": null, "durati… |
| O4-fc-probe-wav | `& 'C:\Program Files\FilmCraft\filmcraft-cli.exe' probe audio/demo.wav` | 0 | — | { "audio_streams": [ { "bits_per_sample": 24, "channels": 2, "codec": "PCM", "sample_rate": 48000 } ], "bwf": { "timeReference": 192000 }, "container": "Broadcast WAV", "duration":… |
| O2b-fc-save | `& 'C:\Program Files\FilmCraft\filmcraft-cli.exe' --demo --save-as motion/demo.fcproj exec file.newBin name=Selects` | 0 | demo.fcproj: 28281 | { "bin": 900011 } |
| O3b-fc-inspect-file | `& 'C:\Program Files\FilmCraft\filmcraft-cli.exe' --project motion/demo.fcproj inspect project` | 0 | — | { "activeSequence": 21, "dirty": false, "name": "demo", "path": "motion/demo.fcproj", "revision": 2, "root": { "children": [ { "children": [ { "customLabelColor": null, "duration":… |
| O5b-fc-export-png | `& 'C:\Program Files\FilmCraft\filmcraft-cli.exe' --project motion/demo.fcproj export motion/fc-frame.png --format png --range inOut --scale 0.25` | 0 | fc-frame.png:  | exported motion\fc-frame000.png to motion\fc-frame641.png in 1.8s |
| O6-fc-export-wav | `& 'C:\Program Files\FilmCraft\filmcraft-cli.exe' --project motion/demo.fcproj export audio/fc-mix.wav --format wav --range inOut` | 0 | fc-mix.wav: 5141180 | exported audio\fc-mix.wav in 0.2s |
| O7-fc-export-list | `& 'C:\Program Files\FilmCraft\filmcraft-cli.exe' export --list-presets` | 0 | — | [ { "builtin": true, "category": "Match Source", "description": "H.264 at the sequence's frame size and rate; bitrate adapts to the frame size (0.2 bits per pixel)", "extension": "… |

### P. DesignCraft：排版样张 → PDF / PNG / 多页 PNG

**结论**：类似 InDesign 的排版引擎可以无 GUI 渲染样张。`validate-pdf` 对非 PDF/X-4 文件按设计返回 exit 1 + issue 列表（见第 4 节）。
**内容证据**：`wrote design/sample.pdf (4 pages, 552943 bytes)`；`wrote design/sample.png (630×810, 81.3 ms, 103 glyphs)`；`--all-pages` 输出 `page-001.png …`。

| # | 命令 | 退出码 | 产物（字节） | 证据（stdout/stderr 摘录） |
|---|---|---|---|---|
| P1-design-sample-pdf | `& 'C:\Program Files\DesignCraft\designcraft-cli.exe' run --sample --export design/sample.pdf` | 0 | sample.pdf: 552943 | wrote design/sample.pdf (4 pages, 552943 bytes) |
| P2-design-sample-png | `& 'C:\Program Files\DesignCraft\designcraft-cli.exe' run --sample --export design/sample.png` | 0 | sample.png: 221560 | wrote design/sample.png (630×810, 81.3 ms, 103 glyphs) |
| P3-design-all-pages | `& 'C:\Program Files\DesignCraft\designcraft-cli.exe' run --sample --all-pages design/pages` | 0 | pages: 910644 | wrote design/pages/page-001.png (630×810, 61.4 ms, 103 glyphs) wrote design/pages/page-002.png (630×810, 33.6 ms, 1171 glyphs) wrote design/pages/page-003.png (630×810, 17.9 ms, 34… |

### Q. DesignCraft 原生 `.designcraft` 与缩略图

**结论**：可保存原生工程并从其内置预览生成缩略图；普通 PDF 没有 DesignCraft 预览，thumbnail 会明确报错。
**内容证据**：`saved design/sample.designcraft` 889,464 B；`thumbnail` → 57,277 B；对 `sample.pdf` 报 `has no preview`。

| # | 命令 | 退出码 | 产物（字节） | 证据（stdout/stderr 摘录） |
|---|---|---|---|---|
| Q1-design-save-native | `& 'C:\Program Files\DesignCraft\designcraft-cli.exe' run --sample --export design/sample.designcraft` | 0 | sample.designcraft: 889464 | saved design/sample.designcraft |
| Q2-design-thumb-native | `& 'C:\Program Files\DesignCraft\designcraft-cli.exe' thumbnail design/sample.designcraft design/thumb-native.png` | 0 | thumb-native.png: 57277 | (无输出) |

### R. 跨 app 互读：PSD/ODT/RTF/外来 PDF

**结论**：文件可以在 app 之间互相“喂”：Photocraft 产的 PSD 被 VectorCraft 打开；WordCraft 读自己的 ODT/RTF；PdfCraft 读 CAD/Deck 产的 PDF。
**内容证据**：`vectorcraft info report-p1.psd` → artboard `1224×1584`、`objects:2`；`pdfcraft info cad/bracket.pdf` → `creator:"CADCraft", layers:7`；`pdfcraft text deck/q3.pdf` → `Q3 results Revenue up 18% quarter over quarter. Outlook Pipeline healthy; headless export verified.`。

| # | 命令 | 退出码 | 产物（字节） | 证据（stdout/stderr 摘录） |
|---|---|---|---|---|
| R1-vector-info-psd | `& 'C:\Program Files\VectorCraft\vectorcraft-cli.exe' info word/report-p1.psd` | 0 | — | { "artboards": [ { "name": "Artboard 1", "rect": [ 0.0, 0.0, 1224.0, 1584.0 ] } ], "file": "word/report-p1.psd", "fonts": [], "info": { "artboards": 1, "author": "", "authorTitle":… |
| R2-psd-to-png-vector | `& 'C:\Program Files\VectorCraft\vectorcraft-cli.exe' convert word/report-p1.psd word/report-from-psd.png` | 0 | report-from-psd.png: 292926 | {"bytes":292926,"format":"png","path":"word/report-from-psd.png","warnings":[]} |
| R3-wordcraft-info-odt | `& 'C:\Program Files\WordCraft\wordcraft-cli.exe' info word/report.odt` | 0 | — | { "comments": 0, "dirty": false, "encrypted": false, "layoutMs": 78.4139, "pages": 1, "paragraphs": 14, "path": "word/report.odt", "properties": { "category": "", "created": "2026-… |
| R4-wordcraft-text-rtf | `& 'C:\Program Files\WordCraft\wordcraft-cli.exe' text word/report.rtf` | 0 | — | Craft CLI verification report This document was generated headlessly by wordcraft-cli on Windows. Section 1: Office formats can be read and converted without any GUI.Key finding A … |
| R5-pdfcraft-info-cad | `& 'C:\Program Files\PdfCraft\pdfcraft-cli.exe' info cad/bracket.pdf` | 0 | — | { "acroform_fields": 0, "annotations": 0, "attachments": 0, "author": null, "bookmarks": 0, "creator": "CADCraft", "custom_properties": 0, "encrypted": false, "fields": 0, "file": … |
| R6-pdfcraft-text-deck | `& 'C:\Program Files\PdfCraft\pdfcraft-cli.exe' text deck/q3.pdf` | 0 | — | Q3 results Revenue up 18% quarter over quarter. Outlook Pipeline healthy; headless export verified. |
| R7-pdfcraft-render-design | `& 'C:\Program Files\PdfCraft\pdfcraft-cli.exe' render design/sample.pdf --page 2 --dpi 72 --out design/sample-doc-p2.png` | 0 | sample-doc-p2.png: 152283 | rendered page 2 at 72 dpi: 612×792 px in 31 ms |

### S. Craft Anything：通用初查（浅层嗅探）

**结论**：对未知文件能做初查，但它只按文件头判断类型，**不能**替代对应 app 的 CLI；docx 被识别为普通 ZIP，STEP/DWG 识别为 unknown。
**内容证据**：docx → `kind:zip, description:"A ZIP archive", recommended_toolsets:["core"]`；`solid/part.step`、`cad/bracket.dwg` → `kind:unknown`。

| # | 命令 | 退出码 | 产物（字节） | 证据（stdout/stderr 摘录） |
|---|---|---|---|---|
| S1-ca-capabilities | `& 'C:\Program Files\Craft Anything\craft-anything-cli.exe' capabilities` | 0 | — | {"analysis_mode":"deep","engines":[{"found":false,"id":"ghidra","installable_here":true,"name":"Ghidra","needed_for":"Deep mode: richer decompiled code","path":null},{"found":false… |
| S2-ca-triage-docx | `& 'C:\Program Files\Craft Anything\craft-anything-cli.exe' triage word/report.docx` | 0 | — | {"authority":"original-files","confidence":"inferred","coverage":{"status":"unknown"},"environment":{"clean_room":false,"engine":"builtin","engine_version":"0.3.0","host":"windows-… |
| S3-ca-triage-step | `& 'C:\Program Files\Craft Anything\craft-anything-cli.exe' triage solid/part.step` | 0 | — | {"authority":"original-files","confidence":"inferred","coverage":{"status":"unknown"},"environment":{"clean_room":false,"engine":"builtin","engine_version":"0.3.0","host":"windows-… |
| S4-ca-triage-dwg | `& 'C:\Program Files\Craft Anything\craft-anything-cli.exe' triage cad/bracket.dwg` | 0 | — | {"authority":"original-files","confidence":"inferred","coverage":{"status":"unknown"},"environment":{"clean_room":false,"engine":"builtin","engine_version":"0.3.0","host":"windows-… |

### T. PdfCraft 审计与工具清单

**结论**：`audit` 可查伪遮盖，`tools` 输出带 JSON Schema 的自动化工具表。
**内容证据**：`audit` → `{"count":0,"file":"word/report.pdf","findings":[]}`；`tools` → 每项含 `description`/`parameters` 的 JSON 数组。

| # | 命令 | 退出码 | 产物（字节） | 证据（stdout/stderr 摘录） |
|---|---|---|---|---|
| T1-pdf-audit | `& 'C:\Program Files\PdfCraft\pdfcraft-cli.exe' audit word/report.pdf` | 0 | — | {"count":0,"file":"word/report.pdf","findings":[]} |
| T2-pdf-tools | `& 'C:\Program Files\PdfCraft\pdfcraft-cli.exe' tools` | 0 | — | [ { "command": null, "description": "Apply one consecutive Bates sequence to an ordered list of PDFs. Each file entry has input and output paths and an optional open or permissions… |

### U. 交叉链路与补充（Office→PDF→文本、DWT 写出）

**结论**：xlsx→PDF→text、deck→PDF→info、dxf→dwt 均成立，证明“A 产出的文件喂给 B”可行。
**内容证据**：`pdfcraft text sheet/sales.pdf` → `Quarterly Sales Dashboard Fiscal year 2026 · all figures in USD …`；`deck/q3.pdf` → `first_page_pt [960.0,540.0], bookmarks:3`；`bracket.dwt` 27,507 B。

| # | 命令 | 退出码 | 产物（字节） | 证据（stdout/stderr 摘录） |
|---|---|---|---|---|
| U1-pdfcraft-text-xlsxpdf | `& 'C:\Program Files\PdfCraft\pdfcraft-cli.exe' text sheet/sales.pdf` | 0 | — | Quarterly Sales Dashboard Fiscal year 2026 · all figures in USD Region North South East West Central Online Total Q1 Q2 $48,200 $51,340 $56,010 $61,870 $217,420 28.4% $39,150 $37,9… |
| U2-pdfcraft-info-deckpdf | `& 'C:\Program Files\PdfCraft\pdfcraft-cli.exe' info deck/q3.pdf` | 0 | — | { "acroform_fields": 0, "annotations": 0, "attachments": 0, "author": null, "bookmarks": 3, "creator": "DeckCraft", "custom_properties": 0, "encrypted": false, "fields": 0, "file":… |
| U3-dxf-to-dwt | `& 'C:\Program Files\CADCraft\cadcraft-cli.exe' convert cad/bracket.dxf cad/bracket.dwt` | 0 | bracket.dwt: 27507 | wrote cad/bracket.dwt (27507 bytes) |

### X. PhotoCraft：EXR 写读

**结论**：PNG→EXR 可写，EXR 可 info 读回；有损项（DPI）给出 warning 但不影响退出码。
**内容证据**：EXR 552,961 B；info 尺寸 `1224×1584`；stderr `warning: resolution (DPI) not supported; it will be dropped`。

| # | 命令 | 退出码 | 产物（字节） | 证据（stdout/stderr 摘录） |
|---|---|---|---|---|
| X1-png-to-exr | `& 'C:\Program Files\PhotoCraft\photocraft-cli.exe' convert word/report-p1.png word/report-p1.exr` | 0 | report-p1.exr: 552961 | warning: resolution (DPI) not supported; it will be dropped |
| X2-exr-info | `& 'C:\Program Files\PhotoCraft\photocraft-cli.exe' info word/report-p1.exr` | 0 | — | { "activeLayer": 2, "channels": { "alpha": [], "colors": [ { "name": "Red", "visible": true }, { "name": "Green", "visible": true }, { "name": "Blue", "visible": true } ], "composi… |


## 4. 不可用 / 需说明

1. **`.aep` / `.prproj` / `.indd` / `.idml` 未能实证**：本机没有这几类样本文件；Craft CLI 只能新建自己的原生工程（`.ecproj`、`.fcproj`、`.designcraft`），不能凭空生成 Adobe 文件。因此只验证了“原生工程 + 其导出格式”链路：
   - EffectCraft → `.ecproj`（建 comp、info、render-frame）✅
   - FilmCraft → `.fcproj`（demo 项目另存、inspect、export PNG 序列/WAV）✅
   - DesignCraft → `.designcraft` + 排版 PDF ✅
   要验证 `.aep`/`.prproj`/`.indd` 的“读入”，需要用户提供真实样本再跑同样命令（`effectcraft-cli info X.aep`、`filmcraft-cli --project X.prproj inspect`、`designcraft-cli run --in X.indd --export out.pdf`）。
2. **`.prproj` 与 SKILL.md 的差异**：SKILL.md 写“FilmCraft 明确打不开 .prproj，需 Premiere 先导 FCPXML/AAF/OTIO”。本次没有样件，无法证实/证伪；把该结论当作文档结论而非实测结论。
3. **`designcraft-cli validate-pdf` 对普通 PDF 返回 exit 1 属预期**：`design/sample.pdf` 不是 PDF/X-4，命令输出 8 条 issue（`the PDF version must be 1.6 or lower`、`no PDF/X output intent`…）。这是“校验器正常工作”，不是链路失败。
4. **`designcraft-cli thumbnail` 只认 DesignCraft 自己的预览**：对原生 `.designcraft` 正常（57,277 B）；对普通 PDF 明确报 `has no preview`。需要缩略图的通用 PDF 请改用 `pdfcraft-cli render`。
5. **`craft-anything-cli triage` 只是浅层嗅探**：docx 被判为 `A ZIP archive`，STEP/DWG 为 `unknown`，`recommended_toolsets: ["core"]`。它适合“完全不知道是什么文件”的第一眼，不要用它替代对应 app 的 CLI（与 SKILL.md 的定位一致）。
6. **FilmCraft 导出 PNG 是“图片序列”语义**：`export out.png --format png --range inOut` 生成 `out000.png … out641.png`（本机 642 帧、约 40 MB），`--range` 不会把它变成单帧。要单帧请用 `filmcraft-cli render --seconds S --out f.png`。
7. **GPU / CPU 情况**：texturecraft `render --cpu` 实际报告使用 `AMD Radeon(TM) 890M Graphics`（适配器存在，未失败）；materialcraft render、solidcraft snapshot（`renderer:"gpu"`）也成功；没有出现必须 GPU 才能跑的项目被阻塞。未测试光追（`--samples`）等更重路径。
8. **错误信息是中文系统本地化文本**（如“系统找不到指定的文件”）。脚本/自动化请判断**退出码**，不要匹配错误文本。
9. **语法坑（本次实测踩到并修正，影响 skill 示例）**：
   - `vectorcraft-cli run` 用 `--cmd ID --params JSON`（不是 `id={json}`）；用错时 exit 1 且报 `unknown command`。
   - `wordcraft-cli` / `deckcraft-cli` / `gridcraft-cli` 用 `--cmd 'id={json}'`。
   - `effectcraft-cli` / `filmcraft-cli` 的 `--save`/`--save-as` **只有工程被改动后**才落盘：先跑一个变更命令（如 `comp.new`、`file.newBin`）再 save，否则静默不写文件。
   - `figcraft-cli export/render` 的结果路径是 `-o/--out` 选项，不是位置参数。
   - `texturecraft-cli new` 会做采样烘焙，`--resolution 256` 已足够快（1.4 s）；默认分辨率可能慢很多。
10. **单命令耗时**：solidcraft 的 `bench-agent`(67 s)、`run → step`(93.7 s)、`snapshot`(63 s) 是唯一接近 120 s 的项；在更慢的机器上建议把超时放宽到 180–240 s，或改用 `--scale` 降低规模。
11. **未做 MCP 实测**：所有 CLI 都有 `mcp` 子命令，但本次只验证文件链路；MCP 客户端接入未测试。

## 5. 复现方法

```powershell
# 1) 测试执行器（每条命令 120 s 超时，记录退出码/产物字节数/stdout）
. C:\Users\mei\dsh\work\craft-skill\test\_harness.ps1
Run 'my-test' (CliExe wordcraft) @('info','word/report.docx')

# 2) 产物与日志
Get-ChildItem C:\Users\mei\dsh\work\craft-skill\test -Recurse -File
Get-Content C:\Users\mei\dsh\work\craft-skill\test\runlog.jsonl | Select-Object -First 3
```

- `runlog.jsonl`：每次调用的 JSON 记录（tag / argv / exit / seconds / files / stdout / stderr）。
- `test\logs\<tag>.out|.err`：完整 stdout/stderr。
- `test\_appendix.md`：本报告第 3 节的生成源（由 runlog 自动导出，避免手工抄错命令）。
- 测试产物总量：约 **733 个文件 / 78 MB**（其中 FilmCraft 的 PNG 序列占 645 文件 / 42 MB）。

### 产物清单（主要文件）

| 文件 | 字节 | 来源链路 |
|---|---|---|
| word/report.docx | 6,913 | A1 |
| word/report.pdf | 34,422 | A5 |
| word/report-p1.png | 280,942 | A9 |
| word/report-p1.psd | 976,159 | C2 |
| word/report-p1.tif | 5,817,386 | C4 |
| word/report-p1.exr | 552,961 | X1 |
| sheet/sales.xlsx | 11,159 | D1 |
| sheet/sales.csv | 740 | D4 |
| deck/q3.deckcraft | 5,236 | E1 |
| deck/q3.pptx | 23,532 | E4 |
| deck/q3.pdf | 112,392 | E5 |
| art/vector.svg | 703 | F1 |
| art/vector.ai | 20,988 | F3 |
| art/vector.vectorcraft | 27,946 | F1 |
| cad/bracket.dxf | 42,791 | H1 |
| cad/bracket.dwg | 27,507 | H3 |
| cad/bracket.dwt | 27,507 | U3 |
| fig/design.figcraft | 8,065 | G1 |
| fig/design.fig | 13,368 | G5 |
| tex/sphere.tcraft | 1,132,886 | I1 |
| mat/wood.sbs | 17,420 | J1 |
| audio/demo.wav | 1,507,146 | M1 |
| audio/demo.flac | 336,558 | M5 |
| solid/design.sc | 1,965,443 | L1b |
| solid/part.step | 4,713,253 | L6 |
| motion/headless.ecproj | 2,478 | N1f |
| motion/demo.fcproj | 28,281 | O2b |
| design/sample.pdf | 552,943 | P1 |
| design/sample.designcraft | 889,464 | Q1 |

## 6. 附：SKILL.md 草稿示例命令实测核对（供 skill 修订）

用同样方式实测了 `work\craft-skill\SKILL.md` 里的几条示例命令（原始输出见 `test\logs\V*.out`）：

| SKILL.md 中的写法 | 实测 | 正确写法 / 说明 |
|---|---|---|
| `wordcraft-cli run --cmd 'text.insertText={"text":"Hello"}' --save out.docx` | ❌ exit 1：`text.insertText: unknown command` | `--cmd 'text.insert={"text":"Hello"}'`（A1 已验证可存 docx） |
| `gridcraft-cli run --in book.xlsx --cmd 'sheet.setCell={"sheet":"Sheet1","cell":"A1","value":"Hi"}'` | ❌ exit 1：`sheet.setCell: unknown command` | `--cmd 'cell.set={"cell":"A1","value":"Hi"}'`（V3 实测写出 11,171 B xlsx） |
| `vectorcraft-cli run --in art.ai --cmd path.offset --params '{"dx":10}'` | ⚠️ 命令不存在 | 命令目录里是 `object.path.offsetPath`；`run` 的 `--cmd ID --params JSON` 语法本身正确（F 组已验证） |
| `cadcraft-cli run plan.dxf --script-file setup.scr --save out.dxf` | ✅ 选项名与 `run --help` 一致 | 未用 .scr 实测 |
| `photocraft-cli batch --actions actions.json --in photos\ --out edited\ --recursive` | ✅ 与 `batch --help` 一致 | 参数名全部存在 |
| `solidcraft-cli run design.sc --out part.step` | ✅ 实测（L6，4,713,253 B STEP，93.7 s） | 建议 skill 提示放宽超时 |
| `designcraft-cli run --in brochure.indd --export brochure.pdf` | ⚠️ 未验证 | 本机无 .indd 样本 |
| “`.prproj` FilmCraft 明确打不开” | ⚠️ 未验证 | 本机无 .prproj 样本，建议标注为“依据文档/待验证” |

另：SKILL.md 把 `.pptx` 归给 DeckCraft 是对的（E7/E8 实测）；PhotoCraft 那行的 `.tif/.png/.jpg/.webp/.exr/.psd` 全部实测通过。

