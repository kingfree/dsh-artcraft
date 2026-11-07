# Craft Apps 无头 CLI 参考（抓取日期 2026-11-08）

> 用途：给 DSH skill 做「按扩展名路由到 `<app>-cli`」的参考资料。
> 抓取方式：本会话 `web_fetch` 不可用，全部页面用 PowerShell `Invoke-WebRequest` 抓 HTML，去标签转纯文本后人工核对；原始文本在 `raw/<slug>__<page>.txt`（一页一文件，见文末清单）。
> 子命令以 **本机 `--help` 实测** 为准（17 个 CLI 都在 `C:\Program Files\<App>\<app>-cli.exe`），wiki 用于格式、安装位置和官方示例。
> 结论标注来源：wiki 页面 URL 或本机 `--help`。

## 0. 读前必读：路径差异与总体结论

1. **本机实测安装路径**（2026-11-08，17 个 CLI 均存在，只有 ArtCraft Studio 没有）：
   `C:\Program Files\<App>\<app>-cli.exe`，其中 `<App>` 是 `PhotoCraft`、`WordCraft`、`GridCraft`、`DeckCraft`、`PdfCraft`、`VectorCraft`、`DesignCraft`、`FigCraft`、`LightCraft`、`CadCraft`（目录名 `CADCraft`）、`TextureCraft`、`MaterialCraft`、`FilmCraft`、`EffectCraft`、`SoundCraft`、`SolidCraft`、`Craft Anything`（注意空格）。
2. **wiki 写的官方安装位置**是两种：默认「Only for me」→ `%LOCALAPPDATA%\Programs\ArtCraft\<App>\<cli>.exe`；「Everyone」→ `C:\Program Files\ArtCraft\<App>\<cli>.exe`。「为所有人安装」的 app（MaterialCraft、TextureCraft、Craft Anything）直接装在 `C:\Program Files\<App>\`。**本机是 `C:\Program Files\<App>\`（无 `ArtCraft` 段）**，与 wiki 原文不同，应是安装包/Launcher 版本差异。skill 的解析器应按下列顺序探测：
   `C:\Program Files\<App>\<cli>.exe` → `C:\Program Files\ArtCraft\<App>\<cli>.exe` → `%LOCALAPPDATA%\Programs\ArtCraft\<App>\<cli>.exe` → PATH → portable zip 目录。
3. 所有 CLI **都不在 PATH 上**（wiki 反复强调）；桌面 app 调 MCP 时要用全路径。
4. **17 个 app 有 CLI 文档**；**ArtCraft Studio 没有任何 CLI/自动化/MCP 文档**（纯 GUI + 在线 AI 模型 + 账号），**Craft Anything 的 CLI 不是文件转换器**（是逆向/复刻工具）。
5. 使用 `run --cmd <id> --params '<json>'`（各 app 写法略有不同）是通用批量入口；`commands` 列出全部命令 ID，`info` 读结构，`convert` 转格式，`mcp` 接 AI。
6. **冲突一律以 `--help` 为准**。已发现的 wiki 与 --help 冲突记在各节「差异」里；最明显的是 SolidCraft（见该节）。

## 1. 总表

| App | CLI 可执行名 | Windows 默认路径 | 子命令（本机 --help） | 主要读写格式 | CLI 文档化 |
|---|---|---|---|---|---|
| PhotoCraft | `photocraft-cli` | `%LOCALAPPDATA%\Programs\ArtCraft\PhotoCraft\` 或 `C:\Program Files\ArtCraft\PhotoCraft\`；本机 `C:\Program Files\PhotoCraft\` | convert, info, run, batch, droplet, commands, mcp, serve | 读 .psd/.psb/.pcraft/.ora/.xcf/.kra/.pdn/.af*/.svg/.tif + PNG/JPEG/WebP/EXR/HDR/RAW/HEIC …；写 .pcraft/.psd/.psb/.ora/.tif/.png/.jpg/.webp/.tga/.ico/.jxl/.gif/.bmp/.exr/.hdr/.pdf … | 是（automation） |
| VectorCraft | `vectorcraft-cli` | `%LOCALAPPDATA%\Programs\ArtCraft\VectorCraft\` 或 `C:\Program Files\ArtCraft\VectorCraft\`；本机 `C:\Program Files\VectorCraft\` | run, convert, info, bench, perf, mcp | 读 .vectorcraft/.svg/.pdf/.ai/.ait/.eps/.ps/.dxf/.emf/.wmf/.af/.afdesign/.afpub/.psd/.psb + 位图；写 .vectorcraft/.svg/.pdf/.ai/.eps/.dxf/.emf/.wmf/.psd + 位图 | 是（ai-agents / automate-vectorcraft） |
| WordCraft | `wordcraft-cli` | `%LOCALAPPDATA%\Programs\ArtCraft\WordCraft\`；本机 `C:\Program Files\WordCraft\` | convert, info, text, inspect, render, run, commands, parity, mcp, zotero | 读 .docx/.doc/.odt/.rtf/.html/.md/.tex/.txt；写 .docx/.odt/.rtf/.html/.md/.tex/.txt/.pdf/.png/.xml | 是（ai-agents） |
| GridCraft | `gridcraft-cli` | `%LOCALAPPDATA%\Programs\ArtCraft\GridCraft\`；本机 `C:\Program Files\GridCraft\` | info, convert, eval, cat, check, run, commands, functions, mcp, send, version | 读 .xlsx/.xlsm/.xls/.xlsb/.ods/.csv/.tsv/.txt；写 .xlsx/.csv/.tsv/.json/.html/.pdf | 是（ai-agents） |
| DeckCraft | `deckcraft-cli` | `%LOCALAPPDATA%\Programs\ArtCraft\DeckCraft\`；本机 `C:\Program Files\DeckCraft\` | info, render, render-transition, convert, run, commands, describe, app, mcp, bench, links | 读 .pptx/.potx/.ppsx/.deckcraft/.txt/.md；写 .pptx/.deckcraft/.pdf/.txt/.rtf/.md/.png/.jpg/.gif | 是（ai-agents） |
| PdfCraft | `pdfcraft-cli` | `%LOCALAPPDATA%\Programs\ArtCraft\PdfCraft\`；本机 `C:\Program Files\PdfCraft\` | info, render, text, edit, combine, extract, split, check, audit, batch, tools, run, mcp, ui | 读 .pdf（另可把 PNG/JPEG/TIFF/GIF/BMP/JP2/.txt 合成 PDF）；写 .pdf；导出 docx/pptx/html/rtf/md/图片 | 是（ai-agents / organize-pages） |
| DesignCraft | `designcraft-cli` | `%LOCALAPPDATA%\Programs\ArtCraft\DesignCraft\`；本机 `C:\Program Files\DesignCraft\` | run, commands, describe, script, app, mcp, perf, bench, validate-pdf, thumbnail, links | 读 .designcraft/.idml/.indd/.indt + Place：PNG/JPEG/GIF/WebP/TIFF/BMP/PSD/SVG/PDF/AI/EPS/TXT/DOCX/RTF/MD/XLSX/MP4/MOV/WebM/MP3/WAV…；写 .designcraft/.idml/.pdf/.png/.epub/.html/.pptx/.xml/.txt | 是（ai-agents / indesign-files） |
| FigCraft | `figcraft-cli` | `%LOCALAPPDATA%\Programs\ArtCraft\FigCraft\`；本机 `C:\Program Files\FigCraft\` | info, export, convert, render, run, commands, mcp, plugin, connect, perf | 读 .figcraft/.fig/.sketch/.penpot/.jam/.json/.svg/.png/.jpg/.webp/.gif/.bmp；写 .figcraft/.fig/.json/.svg/.png/.jpg/.webp/.pdf | 是（ai-agents） |
| LightCraft | `lightcraft-cli` | `%LOCALAPPDATA%\Programs\ArtCraft\LightCraft\` 或 `C:\Program Files\ArtCraft\LightCraft\`；本机 `C:\Program Files\LightCraft\` | run, mcp, render, snapshot, merge, synth-merge, denoise-serve, commands, controls, calibrate | 读 CR2/CR3/ARW/NEF/RAF/RW2/RWL/PEF/ORF/DNG + JPEG/PNG/TIFF/WebP/PSD/JXL/GIF/BMP/.lrcat；写 JPEG/PNG/TIFF/PSD/WebP/AVIF/JXL/DNG + XMP sidecar | 是（ai-agents / lightroom） |
| TextureCraft | `texturecraft-cli` | `C:\Program Files\TextureCraft\`（wiki：装到 Program Files） | info, commands, run, batch, bake, export, render, new, mcp, serve | 读 .tcraft + .glb/.gltf/.fbx/.dae/.usd/.usda/.usdc/.usdz/.abc/.obj/.ply/.stl；写 .tcraft + PNG/JPEG/TGA/TIFF/BMP/WebP/EXR/HDR + OBJ/GLB/USD | 是（ai-agents） |
| MaterialCraft | `materialcraft-cli` | `C:\Program Files\MaterialCraft\`（wiki：装到 Program Files；本机同） | info, commands, nodes, run, batch, new, cook, export, render, mcp, serve | 读 .sbs/.mcraft（也读 Substance .sbs）；写 .sbs/.mcraft/.mcmat + PNG/JPEG/TGA/TIFF/BMP/WebP/EXR/HDR | 是（workflows） |
| FilmCraft | `filmcraft-cli` | `%LOCALAPPDATA%\Programs\ArtCraft\FilmCraft\` 或 `C:\Program Files\ArtCraft\FilmCraft\`；本机 `C:\Program Files\FilmCraft\` | exec, run, commands, describe, inspect, import, export, probe, render, bench-decode, mcp | 读 .fcproj + MP4/MOV/MKV/WebM/AVI/MXF/MPEG-TS（H.264/HEVC/ProRes/DNxHD/DNxHR/VP8/VP9/AV1）+ WAV/AAC/MP3/FLAC + 静帧 + FCPXML/OTIO/EDL/AAF/OMF；写 .fcproj + h264/hevc/prores/dnxhr/apv/mjpeg/mxf/png/tiff/bmp/gif/wav/aiff/aac | 是（ai-agents） |
| EffectCraft | `effectcraft-cli` | `%LOCALAPPDATA%\Programs\ArtCraft\EffectCraft\` 或 `C:\Program Files\ArtCraft\EffectCraft\`；本机 `C:\Program Files\EffectCraft\` | info, commands, exec, run, props, get, set, render-frame, render, bench, script, mcp | 读 .ecproj/.aep/.aepx/.ectemplate + 视频/音频/静帧/PSD/PDF/AI/Lottie；写 .ecproj/.aep + h264/hevc/av1/prores/webm/png/jpeg/tiff/exr/tga/gif/wav/aiff/lottie | 是（ai-agents / after-effects） |
| SoundCraft | `soundcraft-cli` | `%LOCALAPPDATA%\Programs\ArtCraft\SoundCraft\`；本机 `C:\Program Files\SoundCraft\` | info, convert, run, script, commands, describe, app, mcp, parity, plugins | 读 .scraft + WAV/BWF/RF64/AIFF/FLAC/MP3/Ogg/AAC/ALAC/CAF/MIDI + MP4/MOV 视频轨；写 .scraft + WAV/AIFF/FLAC/MIDI/MusicXML | 是（ai-agents） |
| CADCraft | `cadcraft-cli` | `%LOCALAPPDATA%\Programs\ArtCraft\CADCraft\`（Everyone：`C:\Program Files\ArtCraft\CADCraft\`）；本机 `C:\Program Files\CADCraft\` | info, convert, run, commands, mcp, perf, sample, roundtrip | 读 .dxf/.dwg/.dwt/.svg；写 .dxf/.dwg/.dwt/.pdf/.svg/.png | 是（automation） |
| SolidCraft（第三方） | `solidcraft-cli` | 本机 `C:\Program Files\SolidCraft\`；wiki 只写 `.msi`/portable `.zip`，未给安装目录 | run, eval, script, bench-open, bench-agent, bench-assistant, snapshot, render, exec, commands, recipe, oracle, kernel-cases, fuzz, mcp, crashes, licences, gpu, icon | 读 `.sc`（design/script）/`.step`；读导入 STEP/IGES/3MF/STL/OBJ；写 .step/.iges/.3mf/.stl/.obj/.png | 是（workflows，但示例与 --help 冲突） |
| Craft Anything | `craft-anything-cli` | `C:\Program Files\Craft Anything\`（本机同） | mcp, setup, doctor, uninstall, commands, capabilities, triage, report, chat, rebuild, ai | **不是格式转换器**：逆向分析网站/app/游戏/文件；项目目录 `.cany` | 是（但非文件处理） |
| ArtCraft Studio | 无 | 本机未安装；wiki 安装包 `ArtCraft_<ver>_x64-setup.exe` / `_universal.dmg` | **无 CLI 文档** | 无本地文件格式（产物在 My Library，下载到 Downloads） | 否 |

## 2. 文件扩展名 → App 路由表

> 原则：优先用「原生/可写」的 app；标「只读」的只能读入。典型命令都按本机 `--help`/wiki 原文，`<cli>` 用总表里的全路径或名字。

| 扩展名 | App | CLI | 典型命令 |
|---|---|---|---|
| .docx | WordCraft | wordcraft-cli | `wordcraft-cli convert in.docx out.pdf` |
| .doc | WordCraft | wordcraft-cli | 只读：`wordcraft-cli convert old.doc new.docx` |
| .odt/.rtf/.md/.html/.htm/.tex/.txt | WordCraft | wordcraft-cli | `wordcraft-cli convert in.odt out.docx` |
| .xlsx | GridCraft | gridcraft-cli | `gridcraft-cli convert book.xlsx data.csv --sheet Sales` |
| .xlsm/.xls | GridCraft | gridcraft-cli | `gridcraft-cli info book.xlsm`；`.xls` 保留值/公式/数字格式 |
| .xlsb/.ods | GridCraft | gridcraft-cli | 只作数据读入（公式取最后保存结果） |
| .csv/.tsv | GridCraft | gridcraft-cli | `gridcraft-cli convert data.csv data.xlsx` |
| .pptx | DeckCraft | deckcraft-cli | `deckcraft-cli convert deck.pptx deck.pdf` |
| .potx/.ppsx | DeckCraft | deckcraft-cli | 打开另存 .pptx / 导出 PDF、PNG |
| .pdf | PdfCraft | pdfcraft-cli | `pdfcraft-cli info in.pdf`；`pdfcraft-cli edit in.pdf --out out.pdf ...` |
| .pdf（从图/文本合成） | PdfCraft（GUI） | — | `pdfcraft-cli combine` 实测只收 **≥2 个 PDF**；图片/`.txt`→PDF 是 GUI 的「Create a PDF」，CLI 不支持（实测 PNG 报 "not a PDF file"） |
| .pdf（PDF→Office） | PdfCraft（MCP 工具） | pdfcraft-cli（MCP） | automation 工具有 `export.docx`（→ .docx/.pptx/.html/.rtf/.md）；CLI 的 `run <tool>` 只认 compact 别名（doc_open/doc_list/doc_save…），实测 `run create.multiple` 报 unknown tool |
| .psd/.psb | PhotoCraft | photocraft-cli | `photocraft-cli convert in.psd out.png`；VectorCraft 可扁平读、EffectCraft 可当素材导入、LightCraft 可打开 |
| .pcraft | PhotoCraft | photocraft-cli | `photocraft-cli info in.pcraft` |
| .ora/.xcf/.kra/.krz/.pdn | PhotoCraft | photocraft-cli | 只读（原地编辑后另存 .psd/.ora） |
| .af/.afphoto/.afdesign/.afpub | PhotoCraft / VectorCraft | 两者均可读 | 位图用 PhotoCraft，矢量用 VectorCraft（VectorCraft 保留图层/画板/文字） |
| .ai | VectorCraft | vectorcraft-cli | `vectorcraft-cli convert in.ai out.svg` |
| .eps/.ps | VectorCraft | vectorcraft-cli | `vectorcraft-cli convert in.eps out.pdf` |
| .svg/.svgz | VectorCraft | vectorcraft-cli | `vectorcraft-cli convert in.svg out.pdf` |
| .dxf | CADCraft / VectorCraft | cadcraft-cli 优先 | `cadcraft-cli convert drawing.dxf drawing.pdf` |
| .dwg/.dwt | CADCraft | cadcraft-cli | `cadcraft-cli convert drawing.dwg drawing.dxf` |
| .indd/.indt/.idml | DesignCraft | designcraft-cli | `designcraft-cli run --in brochure.indd --export brochure.pdf`（不写回 .indd，可导出 .idml） |
| .fig | FigCraft | figcraft-cli | `figcraft-cli convert design.fig design.figcraft` |
| .sketch/.penpot/.jam | FigCraft | figcraft-cli | `figcraft-cli info design.sketch`（best effort） |
| .aep/.aepx | EffectCraft | effectcraft-cli | GUI 导入；CLI 可用 `effectcraft-cli exec`/`run` 打开 .ecproj。AE 工程读入有限制（插件效果丢失） |
| .prproj | **无 app** | — | FilmCraft 明确「还不能打开 Premiere .prproj」；让用户在 Premiere 导出 FCPXML/AAF/OTIO，再用 `filmcraft-cli import` |
| .fcproj | FilmCraft | filmcraft-cli | `filmcraft-cli inspect` / `export` |
| .mp4/.mov/.mkv/.webm/.avi/.mxf/.ts | FilmCraft（剪辑）/ EffectCraft（合成） | filmcraft-cli / effectcraft-cli | `filmcraft-cli probe in.mp4`；`filmcraft-cli export out.mp4 --preset ...` |
| .fcpxml/.otio/.edl/.aaf/.omf | FilmCraft | filmcraft-cli | 时间线交换：`filmcraft-cli import timeline.xml` |
| .wav/.aiff/.aif/.flac/.mp3/.ogg/.aac/.m4a/.alac/.caf/.mid/.midi | SoundCraft | soundcraft-cli | `soundcraft-cli info in.wav`；`soundcraft-cli convert in.wav out.flac` |
| .scraft | SoundCraft | soundcraft-cli | `soundcraft-cli info session.scraft` |
| .cr2/.cr3/.arw/.nef/.raf/.rw2/.rwl/.pef/.orf/.dng | LightCraft | lightcraft-cli | `lightcraft-cli render in.CR3 -o out.jpg --set light.exposure=0.5` |
| .lrcat | LightCraft | lightcraft-cli | GUI 导入；CLI 无 catalog 导入命令 |
| .jpg/.jpeg/.png/.tif/.tiff/.webp/.heic/.heif/.gif/.bmp/.jxl/.exr/.hdr/.tga/.dds/.dpx/.cin/.fits/.pnm | PhotoCraft | photocraft-cli | `photocraft-cli convert in.heic out.png`（HEIC 只读） |
| .tcraft | TextureCraft | texturecraft-cli | `texturecraft-cli info project.tcraft` |
| .glb/.gltf/.fbx/.dae/.usd/.usda/.usdc/.usdz/.abc/.obj/.ply/.stl | TextureCraft（材质/烘焙） | texturecraft-cli | `texturecraft-cli new model.glb model.tcraft --resolution 2048` |
| .sbs/.mcmat | MaterialCraft | materialcraft-cli | `materialcraft-cli info pack.sbs`；导出 `export ... --format png` |
| .sc（SolidCraft design/script） | SolidCraft | solidcraft-cli | `solidcraft-cli run design.sc --out part.step` |
| .step/.stp/.iges/.igs/.3mf/.stl/.obj | SolidCraft（机械 CAD） | solidcraft-cli | `solidcraft-cli run --in part.step --out out.step` |
| .ecproj | EffectCraft | effectcraft-cli | `effectcraft-cli render main.ecproj --comp Main --out main.mp4` |
| .cany | Craft Anything | craft-anything-cli | 项目目录：`craft-anything-cli triage <file>` 做初查（非转换） |
| 任意文件/程序/网站 | Craft Anything | craft-anything-cli | `craft-anything-cli triage <file>`、`chat`、`rebuild`（逆向/复刻，不是格式转换） |

## 3. 通用调用模式（各 app 相同部分）

- **读结构**：`<cli> info <file>`（JSON）。
- **转格式**：`<cli> convert <in> <out>`，输出格式由 OUT 扩展名决定（DesignCraft/部分 app 用 `run --export`）。
- **批量脚本**：`<cli> run --cmd <command-id> --params '<json>' ...`（VectorCraft/PhotoCraft/DeckCraft/GridCraft/WordCraft 等）；或 `run --commands <file.json>` / `--script`；命令 ID 用 `<cli> commands` 查。
- **MCP**：`<cli> mcp`（stdio），通常可加 `--automation-read-root DIR --automation-write-root DIR` 或 `--read-root/--write-root` 限制文件访问；要驱动已开窗口用 `<app> --control <port>` + `mcp --connect/--bridge/--attach`。
- **Windows 引号**：PowerShell 里 JSON 参数用单引号：`--params '{"amount":80}'`；路径含空格用双引号。

---

## 4. PhotoCraft

- **CLI**：`photocraft-cli`（有文档：[Automation and AI agents](https://craft.wiki/apps/photocraft/automation/)）。随 Windows/Linux 安装包提供；macOS 单独下载；Linux AppImage 用 `--cli` 前缀。
- **安装位置**（wiki 原文）：
  - Windows：`%LOCALAPPDATA%\Programs\ArtCraft\PhotoCraft\photocraft-cli.exe`（为当前账号安装）或 `C:\Program Files\ArtCraft\PhotoCraft\photocraft-cli.exe`（为所有人安装）。**不在 PATH 上**。
  - Windows portable zip：在 `photocraft.exe` 旁边。
  - macOS：单独下载 `photocraft-cli-<ver>-macos-universal.zip`（已签名公证）。
  - Linux .deb/.rpm：`/usr/bin/photocraft-cli`；AppImage：`./photocraft-<ver>-linux-x86_64.AppImage --cli --help`。
- **子命令**（本机 --help，单位：0.20.2）：
  | 子命令 | 说明 |
  |---|---|
  | convert | 在 .pcraft/.psd/.png/.jpg/.tif/.webp/.exr … 间转换 |
  | info | 以 JSON 打印文档（尺寸、模式、位深、图层树） |
  | run | 打开/新建文档，按顺序跑命令，保存结果 |
  | batch | 对一个目录里每张图应用动作列表 |
  | droplet | 对图片和文件夹运行 droplet（File › Automate › Create Droplet） |
  | commands | 列出引擎命令注册表 |
  | mcp | stdio 上的 MCP server（headless，或桥接 `photocraft --control <port>`） |
  | serve | 保持一个 headless 会话，stdio 或 127.0.0.1:<PORT> 上应答 JSON lines |
- **示例命令**（wiki 原文）：
  ```
  photocraft-cli run wave.psd \
    --cmd filter.sharpen.smartSharpen --params '{"amount":80}' \
    --cmd layer.newAdjustmentLayer.curves --params '{"points":[[0,0],[64,48],[192,212],[255,255]]}' \
    --out wave-final.png
  ```
  ```
  photocraft-cli mcp --automation-read-root /path/to/project --automation-write-root /path/to/project
  claude mcp add photocraft -- photocraft-cli mcp --automation-read-root /path/to/project --automation-write-root /path/to/project
  ```
- **支持格式**（[File formats](https://craft.wiki/apps/photocraft/file-formats/)）：
  - **读+写（带图层）**：.pcraft、.psd、.psb、.tif/.tiff（分层）、.ora。
  - **只读（分层）**：.xcf（GIMP）、.kra/.krz（Krita）、.pdn（Paint.NET）、.af/.afphoto/.afdesign/.afpub（Affinity）、.svg/.svgz（作为形状图层）。
  - **读+写（平面）**：PNG、JPEG、WebP、TIFF、TGA、ICO、GIF、BMP、OpenEXR、Radiance HDR、FITS、DDS、DPX、Cineon、Netpbm（.pnm/.pbm/.pgm/.ppm/.pam/.pfm）、Amiga IFF。
  - **只读**：HEIC/HEIF、相机 RAW（DNG/CR2/CR3/NEF/NRW/ARW/PEF/ORF/RW2/RAF）、QOI/PCX/XPM/DICOM。
  - **只写**：JPEG XL（无损）、PDF。
  - **预设**（只读）：.abr、.grd、.asl、.aco/.act/.ase、.kys。
- **MCP**：`photocraft-cli mcp --automation-read-root DIR --automation-write-root DIR`；Claude Code：`claude mcp add photocraft -- photocraft-cli mcp ...`。不给 root 时 agent 完全不能读写文件。
- **来源**：https://craft.wiki/apps/photocraft/automation/ · https://craft.wiki/apps/photocraft/file-formats/ · https://craft.wiki/apps/photocraft/install-update/

## 5. VectorCraft

- **CLI**：`vectorcraft-cli`（有文档：[AI agents](https://craft.wiki/apps/vectorcraft/ai-agents/)、[Automate VectorCraft](https://craft.wiki/apps/vectorcraft/automate-vectorcraft/)）。随安装包提供；macOS 单独 zip（automate 页写 `vectorcraft-cli-<version>-macos-<arch>.zip`，ai-agents 页写 `macos-universal.zip`，以 release 页实际文件为准）。
- **安装位置**：
  - Windows installer：`%LOCALAPPDATA%\Programs\ArtCraft\VectorCraft\vectorcraft-cli.exe`（Everyone：`C:\Program Files\ArtCraft\VectorCraft\`）。**不在 PATH**。
  - Windows portable zip：`vectorcraft.exe` 旁边。
  - Linux .deb/.rpm：`/usr/bin/vectorcraft-cli`。
  - macOS：`vectorcraft-cli-<ver>-macos-<arch>.zip`；`.app` 里只有 GUI。
- **子命令**（本机 --help，0.21.1）：`run`（headless 批量）、`convert`、`info`、`bench`、`perf`、`mcp`。
- **示例命令**（wiki 原文）：
  ```
  vectorcraft-cli run --in in.svg --cmd select.all --cmd paint.setFill --params '{"color":"#ff0000"}' --export out.svg
  vectorcraft-cli run --cmd file.new --params '{"width":800,"height":600}' --cmd shape.star --params '{"cx":400,"cy":300,"radius1":200,"radius2":90}' --export star.vectorcraft
  vectorcraft-cli run --in sheet.vectorcraft --commands steps.json --export out.pdf
  ```
  ```
  vectorcraft-cli mcp --connect 127.0.0.1:7979
  vectorcraft-cli mcp --headless
  ```
- **支持格式**（本机 --help 明列；[Open and save files](https://craft.wiki/apps/vectorcraft/open-and-save-files/)）：
  - **可读**：.vectorcraft/.drawcraft、.svg/.svgz、.pdf、.ai/.ait、.png/.pns/.jpg/.jpeg/.gif/.webp/.tif/.tiff/.bmp/.dib/.rle/.tga/.vda/.icb/.vst/.pcx/.pxr/.jpf/.jpx/.jp2/.j2k/.j2c/.jpc、.psd/.pdd/.psb、.vctemplate、.dxf、.emf/.wmf、.eps/.epsf/.ps/.ps、.af/.afdesign/.afpub。
  - **可写**：.vectorcraft、.svg/.svgz、.pdf、.ai、.png/.jpg/.gif/.webp/.tif/.bmp/.tga、.vctemplate、.txt、.dxf、.eps、.emf/.wmf、.psd（带图层）。
  - PDF/PDF 兼容 .ai/EPS 可保留完整文档（`--preserve-editing`）；`.ai` 默认写 PDF 兼容格式，`--ai-version 7` 写旧版。
  - Place（GUI）还能放 .txt/.rtf/.docx/.doc 作为区域文字（不是转格式）。
- **MCP**：`vectorcraft-cli mcp`（默认先连运行中的 app `vectorcraft --control 7979`，连不上则 headless）；`--automation-read-root/--automation-write-root` 隐含 headless。Claude/PowerShell：`claude mcp add vectorcraft -- "$env:LOCALAPPDATA\Programs\ArtCraft\VectorCraft\vectorcraft-cli.exe" mcp`。服务给 agent 33 个工具。
- **来源**：https://craft.wiki/apps/vectorcraft/automate-vectorcraft/ · https://craft.wiki/apps/vectorcraft/ai-agents/ · https://craft.wiki/apps/vectorcraft/open-and-save-files/

## 6. WordCraft

- **CLI**：`wordcraft-cli`（有文档：[AI agents](https://craft.wiki/apps/wordcraft/ai-agents/)）。随安装包；macOS 单独下载；AppImage 不含，改用 tarball。
- **安装位置**：Windows `%LOCALAPPDATA%\Programs\ArtCraft\WordCraft\wordcraft-cli.exe`（或 `C:\Program Files\ArtCraft\WordCraft\`；本机 `C:\Program Files\WordCraft\`）、portable zip 在 `wordcraft.exe` 旁；Linux .deb/.rpm/tarball/FreeBSD 随 app 安装，Flatpak `flatpak run --command=wordcraft-cli ai.storyteller.wordcraft`；macOS `wordcraft-cli-<ver>-macos-universal.zip`。
- **子命令**（本机 --help，0.15.2）：
  | 子命令 | 说明 |
  |---|---|
  | convert | 格式互转（docx、doc[读]、pdf、odt、rtf、html、md、tex、txt、json、png、xml）；`--update-fields` 刷新域；`--markup` 输出批注/修订 |
  | info | 页数、词数、段落、属性（JSON） |
  | text | 纯文本 |
  | inspect | 文档结构（JSON） |
  | render | 渲染某页为 PNG |
  | run | headless 跑命令后保存（`--script` 可一次存 docx+pdf） |
  | commands | 列出全部命令 |
  | parity | 功能目录对照 |
  | mcp | MCP server（headless 或桥接 app） |
  | zotero | 对文档运行 Zotero 命令（需 Zotero 运行）：addEditCitation、addEditBibliography、addNote、refresh、removeCodes、setDocPrefs |
- **示例命令**（wiki 原文，注释保留）：
  ```
  wordcraft-cli convert report.docx report.pdf # convert to docx, pdf, odt, rtf, html, md, tex, txt or png
  ```
  ```
  claude mcp add wordcraft -- wordcraft-cli mcp
  wordcraft-cli mcp --automation-read-root ~/Documents/project --automation-write-root ~/Documents/project/out
  wordcraft-cli mcp --author "Claude (copyedit)"
  ```
- **支持格式**：读 .docx/.doc/.odt/.rtf/.html/.md/.tex/.txt；写 .docx/.odt/.rtf/.html/.md/.tex/.txt/.pdf（真实可选中文字、链接、书签）/.png/.xml（Word XML Document = Flat OPC，或 `--format wordml2003` 的 Word 2003 XML）。密码文档用 `--password`/`--password-file`/`WORDCRAFT_PASSWORD`。
- **MCP**：`wordcraft-cli mcp [--connect HOST:PORT | --author NAME] [--automation-read-root DIR] [--automation-write-root DIR]`；`--author` 标注修订/批注作者；roots 与 `--connect` 互斥。
- **来源**：https://craft.wiki/apps/wordcraft/ai-agents/ · https://craft.wiki/apps/wordcraft/overview/ · https://craft.wiki/apps/wordcraft/install-update/

## 7. GridCraft

- **CLI**：`gridcraft-cli`（有文档：[AI agents](https://craft.wiki/apps/gridcraft/ai-agents/)）。随安装包；AppImage 不含改用 tarball；macOS app 不含、单独 zip 且不是每个 release 都有。
- **安装位置**：Windows `%LOCALAPPDATA%\Programs\ArtCraft\GridCraft\gridcraft-cli.exe`（或 Program Files；本机 `C:\Program Files\GridCraft\`）、portable zip 在 `gridcraft.exe` 旁；Linux .deb/.rpm/Arch/tarball/FreeBSD 随 app，Flatpak `flatpak run --command=gridcraft-cli ai.storyteller.gridcraft`；macOS `gridcraft-cli-<ver>-macos-universal.zip`（不一定有）。
- **子命令**（本机 --help，0.16.1）：`info`、`convert`、`eval`、`cat`、`check`、`run`、`commands`、`functions`、`mcp`、`send`、`version`。
- **示例命令**（wiki 原文）：
  ```
  gridcraft-cli convert book.xlsx data.csv --sheet Sales # convert to xlsx, csv, tsv, json or html
  gridcraft-cli cat book.xlsx --range A1:F20 # print cells as a table
  gridcraft-cli eval '=PMT(5%/12,360,-300000)' # work out a formula
  ```
  ```
  gridcraft-cli run [--in FILE | --sample NAME] [--cmd 'id={json}']... [--script FILE.jsonl] [--out FILE]
  ```
- **支持格式**：读+写 .xlsx；读 .xlsm、.xls（值/公式/数字格式）、.xlsb/.ods（只当数据，公式取最后结果）、.csv/.tsv/.txt；convert 可写 .xlsx/.csv/.tsv/.json/.html/.pdf。
- **MCP**：`gridcraft-cli mcp [--connect PORT] [--in FILE | --sample NAME]`；`gridcraft --control 7979` + `claude mcp add gridcraft -- gridcraft-cli mcp`。
- **来源**：https://craft.wiki/apps/gridcraft/ai-agents/ · https://craft.wiki/apps/gridcraft/overview/

## 8. DeckCraft

- **CLI**：`deckcraft-cli`（有文档：[AI agents](https://craft.wiki/apps/deckcraft/ai-agents/)）。随安装包；AppImage 不含改用 tarball。
- **安装位置**：Windows `%LOCALAPPDATA%\Programs\ArtCraft\DeckCraft\deckcraft-cli.exe`（或 Program Files；本机 `C:\Program Files\DeckCraft\`）、portable zip 在 `deckcraft.exe` 旁；Linux .deb/.rpm/.pkg.tar.zst/tarball/FreeBSD 随 app，Flatpak `flatpak run --command=deckcraft-cli ai.storyteller.deckcraft`；macOS `deckcraft-cli-<ver>-macos-universal.zip`。
- **子命令**（本机 --help，0.15.1）：info、render、render-transition、convert、run、commands、describe、app、mcp、bench、links。
- **示例命令**（wiki 原文）：
  ```
  deckcraft-cli convert deck.deckcraft deck.pptx # or .pdf, .txt, .md, .png, .jpg, .gif
  deckcraft-cli render deck.pptx --all slides/ # every slide as a PNG
  deckcraft-cli info deck.pptx # what's in a presentation
  deckcraft-cli commands format. # list commands
  ```
  ```
  deckcraft-cli run --cmd 'slide.new={"title":"Q3 results"}' --save q3.deckcraft
  ```
- **支持格式**：读+写 .pptx/.deckcraft；读 .potx 模板、.ppsx 放映、.txt/.md 大纲；导出 PDF（幻灯片/备注页/讲义）、PNG/JPEG、动画 GIF、大纲 .txt/.rtf。
- **MCP**：`deckcraft-cli mcp`；`--connect 7990` 连 `deckcraft --control 7990`；roots：`--automation-read-root/--automation-write-root`。
- **来源**：https://craft.wiki/apps/deckcraft/ai-agents/ · https://craft.wiki/apps/deckcraft/overview/

## 9. PdfCraft

- **CLI**：`pdfcraft-cli`（有文档：[AI agents](https://craft.wiki/apps/pdfcraft/ai-agents/)、[Organise pages](https://craft.wiki/apps/pdfcraft/organize-pages/)）。MCP 默认关闭，需显式 `mcp` 子命令；不开网络端口。
- **安装位置**：Windows `%LOCALAPPDATA%\Programs\ArtCraft\PdfCraft\pdfcraft-cli.exe`（或 Program Files；本机 `C:\Program Files\PdfCraft\`）、portable zip 在 `pdfcraft.exe` 旁；Linux .deb/.rpm/.pkg.tar.zst/tarball/FreeBSD 随 app（服务器可只装 `pdfcraft-cli-<ver>-linux-x86_64.tar.gz`），Flatpak `flatpak run --command=pdfcraft-cli ai.storyteller.pdfcraft`；macOS `pdfcraft-cli-<ver>-macos-universal.zip`。
- **子命令**（本机 --help，0.18.2）：info、render、text、edit、combine、extract、split、check、audit、batch、tools、run、mcp、ui。
- **示例命令**（wiki 原文）：
  ```
  pdfcraft-cli mcp --root ~/Documents/pdfs
  claude mcp add pdfcraft -- pdfcraft-cli mcp --root ~/Documents/pdfs
  ```
  ```
  pdfcraft-cli info form.pdf # what's in a PDF
  pdfcraft-cli text paper.pdf --page 3 # the text of page 3
  pdfcraft-cli edit in.pdf --rotate 1,2:90 --delete 5 --out out.pdf
  pdfcraft-cli combine report.pdf appendix.pdf --out combined.pdf
  pdfcraft-cli extract report.pdf --pages 1,3,5-8 --out highlights.pdf
  pdfcraft-cli split report.pdf --every 10 --out-dir parts/
  ```
- **支持格式**：核心是 PDF 读+写（保存时追加增量）。**CLI 实测边界**（2026-11-08）：
  - `combine` **只接受 ≥2 个 PDF**（传 PNG 报 `not a PDF file`；`combine` 传 1 个报 `give at least two input files`）；已验证 `designcraft-cli run --sample --export a.pdf` 出的两个 PDF 可 `pdfcraft-cli combine a.pdf b.pdf --out c.pdf` 成功。
  - **图片/`.txt` → PDF 是 GUI 的「Create a PDF」**（wiki overview 原文；CLI 无对应普通子命令）。
  - `batch --steps convert,ocr,optimize` 批量转换/OCR/压小（`convert` 步骤针对支持的文件）。
  - automation tools（`pdfcraft-cli tools`，189 个）里有 `export.docx`：PDF → Word(.docx)/PowerPoint(.pptx)/HTML/RTF/Markdown——**供 MCP agent 调用**；CLI 的 `run <tool>` 只认 compact 别名（`doc_open`/`doc_list`/`doc_save` 等），实测 `run create.multiple` 报 `unknown tool`。
- **MCP**：`pdfcraft-cli mcp --root DIR`（工具只在该目录读写），或 `--automation-read-root/--automation-write-root`；`--compact` 只给核心工具 + tool_search/tool_call。
- **来源**：https://craft.wiki/apps/pdfcraft/ai-agents/ · https://craft.wiki/apps/pdfcraft/organize-pages/ · https://craft.wiki/apps/pdfcraft/workflows/

## 10. DesignCraft

- **CLI**：`designcraft-cli`（有文档：[AI agents](https://craft.wiki/apps/designcraft/ai-agents/)、[InDesign files](https://craft.wiki/apps/designcraft/indesign-files/)）。随安装包。
- **安装位置**：
  - Windows：`%LOCALAPPDATA%\Programs\ArtCraft\DesignCraft\designcraft-cli.exe`（默认 Only for me）；Everyone 装到 `C:\Program Files\ArtCraft\DesignCraft\`；portable zip 在程序旁。
  - macOS：`/Applications/DesignCraft.app/Contents/MacOS/designcraft-cli`，也可单独下 `designcraft-cli-<ver>-macos-universal.zip`。
  - Linux .deb/.rpm：`/usr/bin/designcraft-cli`；tarball/FreeBSD：`bin/` 下；本机 `C:\Program Files\DesignCraft\`。
- **子命令**（本机 --help，0.17.2）：run、commands、describe、script、app、mcp、perf、bench、validate-pdf（PDF/X、可见未嵌入字体检查）、thumbnail、links。
- **示例命令**（wiki 原文）：
  ```
  designcraft-cli run --in brochure.designcraft --export brochure.pdf # export to .pdf, .idml, .epub, .pptx or .png
  designcraft-cli run --sample --all-pages out/ # render every page of the sample to PNG
  designcraft-cli commands # list every command
  ```
  ```
  designcraft-cli mcp --automation-read-root ~/Documents/project --automation-write-root ~/Documents/project/out
  claude mcp add designcraft -- designcraft-cli mcp
  ```
- **支持格式**：
  - **读+写**：.designcraft；导出 .idml（交回 InDesign）、PDF（含 PDF/X-4、PDF/A-2b）、PNG、EPUB、HTML、.pptx、XML、纯文本。
  - **读**：.idml（InDesign 交换格式）、.indd/.indt（打开时转 IDML，使用 indd-utils），**不能读 .indb 书籍 / .indl 库，也不能保存 .indd**。
  - **Place（放图/文件）**：图片 PNG/JPEG/GIF/WebP/TIFF/BMP/PSD/SVG；矢量 PDF/AI/EPS；文本 TXT/DOCX/RTF/MD；表格 XLSX（作为表格）；视频音频 MP4/M4V/MOV/WebM/MP3/M4A/WAV/OGG。
- **MCP**：`designcraft-cli mcp [--connect PORT] [--sample] [--automation-read-root DIR]... [--automation-write-root DIR]...`；`--sample` 用在无窗口时；`designcraft --control 7979` 可驱动已开窗口（能点击/截图）。
- **来源**：https://craft.wiki/apps/designcraft/ai-agents/ · https://craft.wiki/apps/designcraft/indesign-files/ · https://craft.wiki/apps/designcraft/workflows/

## 11. FigCraft

- **CLI**：`figcraft-cli`（有文档：[AI agents](https://craft.wiki/apps/figcraft/ai-agents/)）。随安装包；AppImage 用 `cli` 子命令形式（`/path/to/FigCraft.AppImage cli mcp`）。
- **安装位置**：Windows `%LOCALAPPDATA%\Programs\ArtCraft\FigCraft\figcraft-cli.exe`（或 Program Files；本机 `C:\Program Files\FigCraft\`）、portable zip `figcraft.exe` 旁；Linux .deb/.rpm/.pkg.tar.zst/tarball/FreeBSD 随 app，Flatpak `flatpak run --command=figcraft-cli ai.storyteller.figcraft`；macOS `figcraft-cli-<ver>-macos-universal.zip`。
- **子命令**（本机 --help，0.15.1）：info、export、convert、render、run、commands、mcp、plugin、connect、perf。
- **示例命令**（wiki 原文）：
  ```
  figcraft-cli render landing.figcraft -o landing.png --scale 2 # render a page as an image
  figcraft-cli export landing.figcraft -o out/ --format svg # export the layers' export settings
  figcraft-cli convert design.fig design.figcraft # convert by file extension
  figcraft-cli commands --filter autoLayout # list commands and their parameters
  ```
  ```
  figcraft-cli mcp --automation-read-root ~/Designs/project --automation-write-root ~/Designs/project/out
  ```
- **支持格式**（overview + --help）：读 .figcraft（原生）、.fig（best effort，`info` 列出没导入的内容）、.sketch（Sketch 48+，best effort）、.penpot（Penpot 2.x）、.jam（overview 列出）、.json（FigCraft/REST API 文件 JSON）、.svg、.png/.jpg/.webp/.gif/.bmp（作为图片图层）。写/导出：PNG、JPEG、WebP、SVG、PDF、Android vector drawable XML、整份 .fig、.figcraft、.json。
- **MCP**：`figcraft-cli mcp`（headless 或 attach 到运行中 app）；`--attach 7979` 连 `figcraft --control 7979`；roots 限制读写。
- **来源**：https://craft.wiki/apps/figcraft/ai-agents/ · https://craft.wiki/apps/figcraft/overview/ · https://craft.wiki/apps/figcraft/live-sessions/

## 12. LightCraft

- **CLI**：`lightcraft-cli`（有文档：[AI agents](https://craft.wiki/apps/lightcraft/ai-agents/)）。随 Windows 安装包和 Linux .deb/.rpm；macOS 单独下载。要用与 app 同版本的 CLI。
- **安装位置**：Windows `%LOCALAPPDATA%\Programs\ArtCraft\LightCraft\lightcraft-cli.exe` 或 `C:\Program Files\ArtCraft\LightCraft\`（本机 `C:\Program Files\LightCraft\`）；Linux `/usr/bin/lightcraft-cli`；macOS `lightcraft-cli-<ver>-macos-universal.zip`。
- **子命令**（本机 --help，0.18.1）：run、mcp、render、snapshot、merge（hdr/panorama/hdr-panorama/hdr-batch）、synth-merge、denoise-serve、commands、controls、calibrate。
- **示例命令**（wiki + --help 原文）：
  ```
  claude mcp add lightcraft -- lightcraft-cli mcp --library "/path/to/LightCraft Library"
  ```
  ```
  lightcraft-cli render in.CR3 -o out.jpg --set light.exposure=0.5 --size 1600 --quality 92
  lightcraft-cli run --import ~/Photos/a.jpg develop.set control=light.exposure value=0.7 develop.auto app.export path=/tmp/a.jpg longEdge=1600
  ```
- **支持格式**：读 RAW：Canon CR2/CR3、Sony ARW、Nikon NEF、Fujifilm RAF（含 X-Trans）、Panasonic RW2、Leica RWL、Pentax PEF、Olympus ORF、DNG；另 JPEG/PNG/TIFF/WebP/PSD/JPEG XL/GIF/BMP；Lightroom Classic 目录 .lrcat。写/导出：JPEG/PNG/TIFF/PSD/WebP/AVIF/JPEG XL/DNG，或复制原图 + XMP sidecar；**不能读视频**。原生库是文件夹（默认 `Pictures/LightCraft Library`）。
- **MCP**：`lightcraft-cli mcp [OPTIONS] [FILES/FOLDERS…]`，`--library DIR`/`--demo`/`--connect 127.0.0.1:7980`（app 用 `lightcraft --control 7980`）。
- **来源**：https://craft.wiki/apps/lightcraft/ai-agents/ · https://craft.wiki/apps/lightcraft/overview/ · https://craft.wiki/apps/lightcraft/lightroom/

## 13. TextureCraft

- **CLI**：`texturecraft-cli`（有文档：[AI agents](https://craft.wiki/apps/texturecraft/ai-agents/)）。随安装包。
- **安装位置**：Windows 安装包装到 `Program Files`（本机 `C:\Program Files\TextureCraft\`），portable zip 解压运行；Linux .deb/.rpm/tarball/FreeBSD 随 app；macOS `texturecraft-cli-<ver>-macos-universal.zip`。
- **子命令**（本机 --help，0.3.2）：info、commands、run、batch、bake、export、render、new、mcp、serve。
- **示例命令**（wiki 原文）：
  ```
  claude mcp add texturecraft -- texturecraft-cli mcp --read-root . --write-root .
  claude mcp add texturecraft-app -- texturecraft-cli mcp --bridge 7878
  ```
  ```
  texturecraft-cli new model.glb model.tcraft --resolution 2048
  texturecraft-cli bake model.tcraft --resolution 2048
  texturecraft-cli export model.tcraft out/ --format png --size 2048
  ```
- **支持格式**：读 .tcraft 项目 + 网格 .glb/.gltf/.fbx/.dae/.usd/.usda/.usdc/.usdz/.abc/.obj/.ply/.stl（无 UV 会自动生成）；写 .tcraft；贴图导出 PNG/JPEG/TGA/TIFF/BMP/WebP/EXR/HDR（8/16/32 bit、UDIM）；带贴图模型可导出 OBJ/GLB/USD。
- **MCP**：`texturecraft-cli mcp [--bridge PORT] [--token TOKEN] [--read-root DIR] [--write-root DIR]`；bridge 连 `texturecraft --control 7878`。
- **来源**：https://craft.wiki/apps/texturecraft/ai-agents/ · https://craft.wiki/apps/texturecraft/overview/

## 14. MaterialCraft

- **CLI**：`materialcraft-cli`（有文档：[workflows](https://craft.wiki/apps/materialcraft/workflows/)）。随安装包；macOS 单独下载。
- **安装位置**：Windows 安装包装到 `Program Files`（本机 `C:\Program Files\MaterialCraft\`），portable zip 解压运行；Linux .deb/.rpm/.pkg.tar.zst/tarball/FreeBSD 随 app；macOS `materialcraft-cli-<ver>-macos-universal.zip`。
- **子命令**（本机 --help，0.1.2）：info、commands、nodes、run、batch、new、cook、export、render、mcp、serve。
- **示例命令**（wiki 原文 + --help）：
  ```
  claude mcp add materialcraft -- materialcraft-cli mcp --read-root . --write-root .
  ```
  ```
  materialcraft-cli new pbr my-material.sbs --size 2048
  materialcraft-cli export my-material.sbs textures --format png --depth 16
  materialcraft-cli render my-material.sbs preview.png --scene sphere
  ```
- **支持格式**：读+写 .sbs 包 / .mcraft；导出贴图 PNG/JPEG/TGA/TIFF/BMP/WebP/OpenEXR/Radiance HDR（8/16/32 bit）；`File › Export material` 写便携 .mcmat（贴图+图一起）。注意 .sbs 也是另一款节点材质软件格式，MaterialCraft 能打开但缺的节点会变占位。
- **MCP**：`materialcraft-cli mcp [--bridge PORT] [--token] [--read-root DIR] [--write-root DIR]`；`materialcraft --control 7878` + `mcp --bridge 7878`。
- **来源**：https://craft.wiki/apps/materialcraft/workflows/ · https://craft.wiki/apps/materialcraft/overview/

## 15. FilmCraft

- **CLI**：`filmcraft-cli`（有文档：[AI agents](https://craft.wiki/apps/filmcraft/ai-agents/)）。随安装包；macOS 单独下载。
- **安装位置**：Windows `%LOCALAPPDATA%\Programs\ArtCraft\FilmCraft\filmcraft-cli.exe`（或 `C:\Program Files\ArtCraft\FilmCraft\`；本机 `C:\Program Files\FilmCraft\`），**不在 PATH**；Linux .deb/.rpm：`/usr/bin/filmcraft-cli`；macOS `filmcraft-cli-<ver>-macos-universal.zip`。
- **子命令**（本机 --help，0.17.1）：exec、run、commands、describe、inspect、import、export、probe、render、bench-decode、mcp。
- **示例命令**（wiki 原文 + --help）：
  ```
  claude mcp add filmcraft -- filmcraft-cli mcp --project /path/to/film.fcproj
  ```
  ```
  filmcraft-cli --project film.fcproj export out.mp4 --format h264
  filmcraft-cli export --list-presets
  filmcraft-cli probe clip.mov
  filmcraft-cli exec timeline.razor seconds=3.5
  ```
- **支持格式**：项目 .fcproj（只存引用，媒体留在原地）。读：MP4/MOV/MKV/WebM/AVI/MXF/MPEG-TS，H.264/HEVC/ProRes/DNxHD/DNxHR/VP8/VP9/AV1；音频 WAV/AAC/MP3/FLAC 等；静帧 PNG/JPEG/GIF/WebP/TIFF/BMP；**不能读相机 RAW 视频**；时间线交换读 FCPXML/Final Cut Pro XML/OpenTimelineIO/EDL/AAF/OMF；**不能打开 Premiere .prproj**（让用户在 Premiere 导出 FCPXML/AAF/OTIO）。写：h264/hevc/prores/dnxhr/apv/mjpeg/mxf-op1a/mxf-opatom/png/tiff/bmp/gif/wav/aiff/aac，`export --list-presets` 列预设。
- **MCP**：`filmcraft-cli mcp`（headless，或 `--bridge 127.0.0.1:9876` 连运行中 app，需同一 token）。
- **来源**：https://craft.wiki/apps/filmcraft/ai-agents/ · https://craft.wiki/apps/filmcraft/overview/ · https://craft.wiki/apps/filmcraft/workflows/

## 16. EffectCraft

- **CLI**：`effectcraft-cli`（有文档：[AI agents](https://craft.wiki/apps/effectcraft/ai-agents/)、[After Effects projects](https://craft.wiki/apps/effectcraft/after-effects/)）。所有桌面版都带（macOS 单独下载）。
- **安装位置**：Windows `%LOCALAPPDATA%\Programs\ArtCraft\EffectCraft\effectcraft-cli.exe`（Everyone：`C:\Program Files\ArtCraft\EffectCraft\`；本机 `C:\Program Files\EffectCraft\`），不在 PATH；Linux .deb/.rpm `/usr/bin/effectcraft-cli`；macOS `effectcraft-cli-<ver>-macos-universal.zip`。
- **子命令**（本机 --help，0.21.1）：info、commands、exec、run、props、get、set、render-frame、render、bench、script（JSX，AE 风格对象模型）、mcp。
- **示例命令**（wiki 原文）：
  ```
  claude mcp add effectcraft -- "$env:LOCALAPPDATA\Programs\ArtCraft\EffectCraft\effectcraft-cli.exe" mcp
  effectcraft-cli render main.ecproj --comp Main --out main.mp4
  ```
- **支持格式**：项目 .ecproj（可读 JSON，适合版本控制）；导入视频/音频/静帧/图像序列、Photoshop .psd、PDF、Illustrator、Lottie；导入 After Effects .aep/.aepx（有限制：只带能精确匹配的部分，AE 插件效果不运行）；模板 .ectemplate（`--template`）。导出：render 队列格式 h264/hevc/av1/prores/webm/png/jpeg/tiff/exr/tga/gif/wav/aiff，Lottie（.json/.lottie），以及 `File › Export › After Effects Project…` 写 .aep（AE 2026）。
- **MCP**：`effectcraft-cli mcp [--autosave | --bridge PORT] [--automation-read-root DIR] [--automation-write-root DIR]`；bridge 用 `effectcraft-cli mcp --bridge 9877`。
- **来源**：https://craft.wiki/apps/effectcraft/ai-agents/ · https://craft.wiki/apps/effectcraft/after-effects/ · https://craft.wiki/apps/effectcraft/overview/

## 17. SoundCraft

- **CLI**：`soundcraft-cli`（有文档：[AI agents](https://craft.wiki/apps/soundcraft/ai-agents/)）。随安装包；AppImage 不含改用 tarball；macOS app 不含、单独下载。
- **安装位置**：Windows `%LOCALAPPDATA%\Programs\ArtCraft\SoundCraft\soundcraft-cli.exe`（或 Program Files；本机 `C:\Program Files\SoundCraft\`）、portable zip `soundcraft.exe` 旁；Linux .deb/.rpm/.pkg.tar.zst/tarball/FreeBSD 随 app，Flatpak `flatpak run --command=soundcraft-cli ai.storyteller.soundcraft`；macOS `soundcraft-cli-<ver>-macos-universal.zip`。
- **子命令**（本机 --help，0.17.1）：info、convert、run、script、commands、describe、app、mcp、parity、plugins。
- **示例命令**（wiki 原文）：
  ```
  soundcraft-cli run --demo \
  --cmd 'mix.volume={"track":"Kick","db":-6}' \
  --bounce mix.wav
  ```
  ```
  claude mcp add soundcraft -- soundcraft-cli mcp
  soundcraft-cli mcp --automation-read-root ~/Music/project --automation-write-root ~/Music/project/out
  ```
- **支持格式**：会话 .scraft（一个文件夹，旁边 Audio Files）；导入 WAV（含 BWF/RF64）、AIFF、FLAC、MP3、Ogg Vorbis、AAC、ALAC、CAF、MIDI；导出 WAV/AIFF/FLAC、MIDI、MusicXML；视频轨播放 MP4/MOV（H.264、ProRes、Motion JPEG）。
- **MCP**：`soundcraft-cli mcp`，roots 同上；`soundcraft --control 7801` + `mcp --connect 7801`。
- **来源**：https://craft.wiki/apps/soundcraft/ai-agents/ · https://craft.wiki/apps/soundcraft/overview/

## 18. CADCraft

- **CLI**：`cadcraft-cli`（有文档：[Scripts, LISP and AI agents](https://craft.wiki/apps/cadcraft/automation/)）。随 Windows 和 Linux 安装包；macOS 单独下载。**wiki 说「五个子命令」，实际 --help 有 8 个**。
- **安装位置**：Windows installer（默认 Only for me）`%LOCALAPPDATA%\Programs\ArtCraft\CADCraft\cadcraft-cli.exe`（Everyone：`C:\Program Files\ArtCraft\CADCraft\`；本机 `C:\Program Files\CADCraft\`）、portable zip 在 `cadcraft.exe` 旁；Linux 随包（.deb/.rpm/AppImage/flatpak/tarball）；macOS `cadcraft-cli-<ver>-macos-universal.zip`。
- **子命令**（本机 --help，0.17.1）：info、convert、run、commands、mcp，另有 perf、sample、roundtrip。
- **示例命令**（wiki 原文 + --help）：
  ```
  cadcraft-cli info drawing.dxf
  cadcraft-cli convert drawing.dwg drawing.pdf
  cadcraft-cli run drawing.dxf --script-file setup.scr --save out.dxf
  cadcraft-cli --help lists every option.
  ```
  ```
  { "mcpServers": { "cadcraft": { "command": "cadcraft-cli", "args": ["mcp"] } } }
  ```
- **支持格式**：读 .dxf（R12+，ASCII 或二进制，二进制须 R13+）、.dwg（2000+）、.dwt 模板、.svg（形状/路径/组/Inkscape 图层；文字、填充、图片会丢）；写 .dxf/.dwg/.dwt（版本 2000/2004/2007/2010/2013/2018）、导出 PDF（矢量、可带多图）、SVG、PNG。不能导入 PDF，不能开 DGN/DWF；不能读 SHX 字体。
- **MCP**：`cadcraft-cli mcp`（headless drawing session）；`cadcraft --control 7979` + `mcp --connect 127.0.0.1:7979` 可截图/点击。也支持脚本 .scr 与 AutoLISP .lsp。
- **来源**：https://craft.wiki/apps/cadcraft/automation/ · https://craft.wiki/apps/cadcraft/files/

## 19. SolidCraft（第三方，Tangency Labs）

- **CLI**：`solidcraft-cli`（有文档：[workflows](https://craft.wiki/apps/solidcraft/workflows/)、[install-update](https://craft.wiki/apps/solidcraft/install-update/)）。另有 `solvecraft-cli`（本机 0.40.0-rc.1 报「deprecated，用 solidcraft-cli」）。
- **安装位置**：wiki 只写按平台下载：Linux Flatpak（`flatpak install flathub io.tangencylabs.solidcraft`）、AppImage、Snap（`sudo snap install solidcraft --classic`）；macOS `.dmg`（`solidcraft-cli` 在 app bundle 或单独下载）；Windows `.msi` 或 portable `.zip`（本机 `C:\Program Files\SolidCraft\`）。无官方逐字安装目录。
- **子命令**（本机 --help，0.40.0-rc.1）：run、eval/inspect、script、bench-open、bench-agent、bench-assistant、snapshot、render、exec、commands、recipe、oracle、kernel-cases、fuzz、mcp（含 `mcp setup`）、crashes、licences、gpu、icon。
- **示例命令**：
  - wiki 原文（**与 --help 冲突**）：`solidcraft-cli input.scad --export output.step`
  - 以本机 --help 为准：
    ```
    solidcraft-cli run design.sc --out part.step
    solidcraft-cli snapshot --in part.step --out shot.png --view iso
    solidcraft-cli render design.sc --out image.png
    solidcraft-cli mcp setup --client claude-code
    ```
- **支持格式**：互操作 STEP、IGES、3MF、STL、OBJ（导入+导出，3MF 推荐用于多体/高分辨率，另支持二进制 STL）；原生设计/脚本 `.sc`（`design.sc` / `script.json`，`part.step` 可直接作为 `--in`）；`snapshot`/`render` 写 PNG。wiki 未列全读写矩阵，以 --help 与实现为准。
- **MCP**：`solidcraft-cli mcp [--headless] [--in DESIGN] [--connect 127.0.0.1:PORT] [--allow-path DIR]...`；`solidcraft-cli mcp setup [--client opencode|claude-desktop|claude-code|cursor] [--live]` 自动写 AI 客户端配置（`--live` 另加 `solidcraft-live` 连运行中 app）。
- **差异（重要）**：wiki 的 `input.scad --export output.step` 是旧/示意写法，本机 --help 没有 `--export` 顶层参数，实际用 `run <file> --out <file>` 或 `run --in <file> --out <file>`。**以 --help 为准**。
- **来源**：https://craft.wiki/apps/solidcraft/workflows/ · https://craft.wiki/apps/solidcraft/install-update/ · https://craft.wiki/apps/solidcraft/overview/

## 20. Craft Anything（开发者工具）

- **CLI**：`craft-anything-cli`（有文档：[install-update](https://craft.wiki/apps/craft-anything/install-update/)、[workflows](https://craft.wiki/apps/craft-anything/workflows/)）。**它不是文件格式转换器**：它「研究」网站/app/游戏/文件，再用本机 coding agent 复刻一个项目并比对。
- **安装位置**：Windows 安装包装到 `C:\Program Files\Craft Anything\`（本机同），portable zip 设置存 `CraftAnythingData`；macOS `.dmg`（含 CLI）或 `craft-anything-cli-<ver>-macos-universal.zip`；Linux AppImage 用 `<AppImage> --cli <command>` 或软链名 `craft-anything-cli`，另有 .deb/.rpm/.pkg.tar.zst/.flatpak/.tar.gz；FreeBSD tarball。
- **子命令**（本机 --help，0.3.0）：mcp、setup、doctor、uninstall、commands、capabilities、triage、report、chat、rebuild、ai。
- **示例命令**（wiki 原文）：
  ```
  craft-anything-cli doctor
  craft-anything-cli commands # every tool, by group
  craft-anything-cli rebuild https://example.com "Recreate this website"
  craft-anything-cli mcp # serve the essential tools to an MCP client
  craft-anything-cli setup # connect Craft Anything to your coding-agent apps
  ```
- **格式**：不按扩展名转换；项目目录 `.cany`（evidence/memory/journal），新项目在 `Documents/Craft Anything`。可 `triage <file>` 打开文件做初查（逆向/分析用途）。
- **MCP**：`craft-anything-cli mcp [--all-tools]`；`setup` 把它注册进 Claude Code/Codex/Cursor 等。
- **来源**：https://craft.wiki/apps/craft-anything/install-update/ · https://craft.wiki/apps/craft-anything/workflows/

## 21. ArtCraft Studio

- **CLI**：**无。未找到 CLI 文档**。抓遍了 `/apps/artcraft-studio/overview|getting-started|install-update|workflows/troubleshooting`，全是 GUI + ArtCraft 账号 + 在线模型（Nano Banana、GPT Image、FLUX、Seedream、Seedance、Kling、Veo、Suno、Hunyuan 3D 等），没有任何命令行、自动化、脚本或 MCP 说明。
- **安装位置**（wiki 原文）：Windows `ArtCraft_<ver>_x64-setup.exe` 或 `ArtCraft_<ver>_x64_en-US.msi`；macOS `ArtCraft_<ver>_universal.dmg`（拖到 Applications）；**没有现成 Linux 版**（只能源码构建）。ArtCraft Launcher 不装 ArtCraft Studio。要求 Windows 64 位或 macOS，需联网 + 账号。
- **文件**：没有本地工程格式；产物都在 `My Library`，下载到 `Downloads`，自身数据在用户主目录的 `Artcraft` 文件夹。
- **结论**：做 skill 时把 ArtCraft Studio 当「无 CLI、不能参与文件路由」处理；遇到它的产物（图片/视频/3D）交给对应的 PhotoCraft/FilmCraft/TextureCraft 处理。
- **来源**：https://craft.wiki/apps/artcraft-studio/overview/ · https://craft.wiki/apps/artcraft-studio/install-update/

---

## 22. 格式缺口与注意事项（skill 必须如实告知）

1. **.prproj 无 app 支持**：FilmCraft 明确「还不能打开 Premiere Pro .prproj」，需先在 Premiere 导出 FCPXML/AAF/OpenTimelineIO，再 `filmcraft-cli import`。
2. **.indb / .indl 无 app 支持**：DesignCraft 明确不能开 InDesign 书籍/库；也不能保存 .indd（只能读 .indd/.indt 并另存 .designcraft 或导出 .idml）。
3. **Keynote/Pages/Numbers（.key/.pages/.numbers）**：wiki 全站未出现，无 app 支持。
4. **.prproj/.aep 类工程**：.aep 仅 EffectCraft 有限导入（插件效果丢失）；.prproj 完全不行。
5. **Office 只读降级**：.doc 只读；.xlsb/.ods 只当数据（公式变最后值）；.potx/.ppsx 只能打开再另存。
6. **PDF 写 Office 是「弱项」**：PdfCraft 自己说「turning office documents into PDFs, and exporting to Word are still weak」；`export.docx` 工具（PDF→Word/PPT/HTML/RTF/MD）只在 automation tools / MCP 里，CLI 普通子命令做不到；「图片/文本→PDF」也是 GUI 功能，`pdfcraft-cli combine` 只合并 PDF（已实测）。
7. **ArtCraft Studio 无 CLI**；**Craft Anything 不是转换器**。
8. **SolidCraft 是第三方**，wiki 示例与 --help 冲突，以 --help 为准。
9. **本机路径与 wiki 路径不同**：见第 0 节，探测顺序要兼容两者。
10. 所有 CLI **不在 PATH**，skill 必须解析全路径；MCP 客户端尤其需要全路径。

## 23. 抓取清单（raw/ 备查）

命名：`raw/<slug>__<page>.txt`（纯文本），原始 HTML 在 `raw/_html/<slug>__<page>.html`；另有 `raw/_home.txt`、`raw/_sitemap.xml`、`raw/_fetch.ps1`（抓取脚本）、`raw/cli-help/<app>.txt`（Lead 抓的 --help）。

- 18 app × `overview` / `getting-started` / `install-update` / `workflows`：artcraft-studio、cadcraft、craft-anything、deckcraft、designcraft、effectcraft、figcraft、filmcraft、gridcraft、lightcraft、materialcraft、pdfcraft、photocraft、solidcraft、soundcraft、texturecraft、vectorcraft、wordcraft
- 专项页：cadcraft/automation、cadcraft/files、designcraft/ai-agents、designcraft/indesign-files、deckcraft/ai-agents、deckcraft/slide-shows、effectcraft/ai-agents、effectcraft/after-effects、figcraft/ai-agents、figcraft/live-sessions、filmcraft/ai-agents、gridcraft/ai-agents、lightcraft/ai-agents、lightcraft/lightroom、pdfcraft/ai-agents、pdfcraft/forms-and-signing、pdfcraft/organize-pages、photocraft/automation、photocraft/file-formats、soundcraft/ai-agents、texturecraft/ai-agents、vectorcraft/ai-agents、vectorcraft/automate-vectorcraft、vectorcraft/open-and-save-files、wordcraft/ai-agents、wordcraft/zotero、wordcraft/languages、wordcraft/recovery
- 共 100 个页面，全部抓取成功（`raw/_failures.txt` 为空）。

## 24. 本机实测版本（2026-11-08）

`cadcraft 0.17.1` · `craft-anything 0.3.0` · `deckcraft 0.15.1` · `designcraft 0.17.2` · `effectcraft 0.21.1` · `figcraft 0.15.1` · `filmcraft 0.17.1` · `gridcraft 0.16.1` · `lightcraft 0.18.1` · `materialcraft 0.1.2` · `pdfcraft 0.18.2` · `photocraft 0.20.2` · `solidcraft 0.40.0-rc.1` · `soundcraft 0.17.1` · `texturecraft 0.3.2` · `vectorcraft 0.21.1` · `wordcraft 0.15.2`
