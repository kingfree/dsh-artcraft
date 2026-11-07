---
name: craft-app-cli
description: 用本机已安装的 Craft 家族无头 CLI（wordcraft-cli、gridcraft-cli、deckcraft-cli、pdfcraft-cli、photocraft-cli、vectorcraft-cli、designcraft-cli、figcraft-cli、cadcraft-cli、lightcraft-cli、texturecraft-cli、materialcraft-cli、filmcraft-cli、effectcraft-cli、soundcraft-cli、solidcraft-cli、craft-anything-cli）读取、转换、渲染和批量处理常见商业软件文件（.docx .xlsx .pptx .pdf .psd .ai .indd .fig .aep .fcproj .dwg .dxf .step .tcraft .sbs .wav …），不需要图形界面，也不需要自己写 Python 解析器。Load when a document, image, design, CAD, video or audio file produced by these apps must be inspected, converted, exported or batch-edited headlessly.
---

# 用 Craft app CLI 无图形界面处理文件

Craft 家族（WordCraft、GridCraft、PhotoCraft、VectorCraft…）每个 app 都自带一个 `<app>-cli`：它执行的是桌面版同一套命令，但不需要开窗口。处理下列格式时：

- **优先调用对应 CLI**，不要临时写 Python 解析器，也不要打开 GUI（只有跨窗口实时调试才用 app 的 `--control`）。
- 先只读（`info` / `text` / `probe` / `inspect`），再改动（`convert` / `run`）；输出多为 JSON，适合直接读和管道。
- 各 CLI 语法不同，以本机 `<cli> --help` 和 `<cli> commands` 为准（见 `references/apps.md`）。

## 第 1 步：找到 CLI

本技能自带定位脚本（本技能目录下的 `scripts/craft-cli.ps1`；技能加载结果里的 Base directory 就是技能目录）：

```powershell
$sk = Join-Path '<本技能目录>' 'scripts\craft-cli.ps1'   # 例：C:\Users\mei\.dsh\skills\craft-app-cli\scripts\craft-cli.ps1
& $sk list                 # 每个 app 的 CLI 名、是否已安装、完整路径
& $sk find wordcraft       # 打印完整路径（缺失时给安装指引）
& $sk route .\report.docx  # 按扩展名猜 app，并给出可直接用的命令
& $sk formats              # 扩展名 → app 路由表
```

Windows 默认位置（按优先级探测，通常**不在 PATH**）：
`C:\Program Files\<App>\<cli>.exe` → `C:\Program Files\ArtCraft\<App>\<cli>.exe` →
`%LOCALAPPDATA%\Programs\ArtCraft\<App>\<cli>.exe` → PATH → portable 目录。
macOS 在 App 旁的独立 zip 里、Linux 在 `/usr/bin/<cli>`。其它位置用环境变量 `CRAFT_CLI_DIRS` 追加。

调用时路径含空格要用调用运算符和引号：

```powershell
& "$env:ProgramFiles\WordCraft\wordcraft-cli.exe" text .\report.docx
& $sk wordcraft text .\report.docx        # 等价：脚本负责定位并透传
```

CLI 缺失时按打印的安装页安装对应 app（或 DSH 里用 artcraft 插件的 `artcraft_discover`）；**不要**为绕过缺失 CLI 改用 Python 硬解格式，如实告诉用户缺哪个组件。

## 第 2 步：按扩展名路由

| 扩展名 | App / CLI | 常用入口 |
|---|---|---|
| `.docx` `.doc` `.rtf` `.odt` `.md` `.html` `.tex` `.txt` | WordCraft / `wordcraft-cli` | `info` `text` `inspect` `convert` `render` `run` |
| `.xlsx` `.xlsm` `.xls` `.xlsb` `.ods` `.csv` `.tsv` | GridCraft / `gridcraft-cli` | `info` `cat` `eval` `convert` `check` `run` |
| `.pptx` `.pptm` `.potx` `.ppsx` `.deckcraft` | DeckCraft / `deckcraft-cli` | `info` `render` `convert` `run` |
| `.pdf` | PdfCraft / `pdfcraft-cli` | `info` `text` `render` `extract` `split` `combine` `edit` `batch` |
| `.psd` `.psb` `.pcraft` `.ora` `.tif` `.tiff` `.png` `.jpg` `.webp` `.exr` `.gif` `.bmp` `.heic` `.jxl` `.hdr` `.tga` `.dds` `.xcf` `.kra` `.pdn` `.afphoto` | PhotoCraft / `photocraft-cli` | `info` `convert` `run` `batch` `droplet` |
| `.ai` `.ait` `.svg` `.eps` `.ps` `.afdesign` `.afpub` | VectorCraft / `vectorcraft-cli` | `convert` `run` `commands` |
| `.indd` `.indt` `.idml` `.designcraft` | DesignCraft / `designcraft-cli` | `run --in … --export …` `run --all-pages` `commands` |
| `.fig` `.figcraft` `.sketch` `.penpot` `.jam` | FigCraft / `figcraft-cli` | `info` `export` `convert` `render` |
| `.dwg` `.dxf` `.dwt` `.scr` `.lsp` | CADCraft / `cadcraft-cli` | `info` `convert` `run` `sample` |
| `.cr2` `.cr3` `.arw` `.nef` `.raf` `.rw2` `.pef` `.orf` `.dng` `.lrcat` | LightCraft / `lightcraft-cli` | `render` `run`（.lrcat 仅 GUI 导入） |
| `.tcraft`，以及 `.glb` `.gltf` `.fbx` `.dae` `.usd*` `.abc` `.ply` | TextureCraft / `texturecraft-cli` | `info` `new` `bake` `export` `render` |
| `.sbs` `.sbsar` `.mcmat` `.mcraft` | MaterialCraft / `materialcraft-cli` | `info` `cook` `export` `render` |
| `.fcproj`，以及 `.mp4` `.mov` `.mkv` `.webm` `.avi` `.mxf` `.mts` | FilmCraft / `filmcraft-cli` | `probe` `inspect` `import` `export` `render` |
| `.fcpxml` `.otio` `.edl` `.aaf` `.omf` | FilmCraft / `filmcraft-cli` | 剪辑交换：`import` 时间线 |
| `.ecproj` `.ectemplate` `.aep` `.aepx` | EffectCraft / `effectcraft-cli` | `info` `render-frame` `render` `script` |
| `.wav` `.aif` `.aiff` `.flac` `.mp3` `.m4a` `.ogg` `.aac` `.caf` `.mid` `.scraft` | SoundCraft / `soundcraft-cli` | `info` `convert` `run` |
| `.sc` | SolidCraft / `solidcraft-cli` | `run` `eval` `script` `snapshot` `render` |
| `.step` `.stp` `.iges` `.igs` `.3mf` `.stl` `.obj` | SolidCraft / `solidcraft-cli` | `run --in … --out …` `snapshot` |
| `.cany` / 未知格式 | Craft Anything / `craft-anything-cli` | `triage`（初查，不是格式转换） |

**没有可用 app 的格式**（如实告知，不要硬试）：`.prproj`（依据 FilmCraft 文档暂不支持，需先在 Premiere 导出 FCPXML/AAF/OTIO；尚无真实样本复核）、`.indb` `.indl`、`.key` `.pages` `.numbers`；ArtCraft Studio 没有任何无头 CLI。

## 第 3 步：按任务选命令

### 看内容与结构
```powershell
wordcraft-cli info report.docx            # 页数/字数/段落/属性，JSON
wordcraft-cli text report.docx            # 纯文本
gridcraft-cli info book.xlsx --json       # 工作表、已用范围、表格、图表
gridcraft-cli cat book.xlsx --range A1:D20 --csv
deckcraft-cli info deck.pptx              # 幻灯片、版式、主题 JSON
pdfcraft-cli info scan.pdf                # 页数、PDF/A、PDF/UA 等；text 取正文
photocraft-cli info art.psd               # 尺寸、色彩模式、位深、图层树
vectorcraft-cli info logo.ai              # 矢量；cadcraft-cli info plan.dxf 为 CAD 摘要
filmcraft-cli probe clip.mp4              # 媒体信息（含 MXF/Ogg/BWF 细节）
```

### 转换格式（OUT 扩展名决定输出格式）
```powershell
wordcraft-cli convert report.docx report.md      # 也可 .pdf .odt .rtf .html .tex .txt .json .png .xml
gridcraft-cli convert book.xlsx book.csv         # 也可 .pdf .html .json .tsv
deckcraft-cli convert deck.pptx deck.pdf         # 也可 .md/.txt 大纲、.png/.jpg 首页、.gif 逐页动画
pdfcraft-cli extract scan.pdf --pages 1,3-5 --out pick.pdf
pdfcraft-cli combine a.pdf b.pdf --out merged.pdf   # 只收 ≥2 个 PDF；图片→PDF 是 GUI 功能
pdfcraft-cli split scan.pdf --every 10 --out-dir chunks
photocraft-cli convert art.psd art.png           # 也可 .jpg .tif .webp .exr .psd .pdf
vectorcraft-cli convert logo.ai logo.svg         # 也可 .pdf .png .eps .dxf .psd
cadcraft-cli convert plan.dwg plan.dxf           # 也可 .svg .png .pdf .dwt
designcraft-cli run --in brochure.indd --export brochure.pdf   # 或 --export brochure.idml；.indd 只读
figcraft-cli convert design.fig design.svg       # 也可 .png .pdf .figcraft .penpot
figcraft-cli export --out outdir design.fig      # 每个顶层 frame 一张；--format png|svg|pdf|jpg|webp
wordcraft-cli render report.docx preview.png --page 1
pdfcraft-cli render scan.pdf --page 1 --dpi 150 --out page1.png
deckcraft-cli render deck.pptx --all slides\     # 每页 slide-01.png …
```

### 无窗口编辑（run / 脚本）
先 `commands` 看命令目录；`describe <id>`（DeckCraft/PDFCraft/VectorCraft/EffectCraft…）或 `--help` 看参数。语法因 app 而异：

```powershell
wordcraft-cli run --cmd 'text.insert={"text":"Hello"}' --save out.docx
gridcraft-cli run --in book.xlsx --cmd 'cell.set={"cell":"A1","value":"Hi"}' --out book.xlsx
deckcraft-cli run --cmd 'slide.new={"title":"Q3 results"}' --save q3.deckcraft
vectorcraft-cli run --in art.ai --cmd object.path.offsetPath --params '{"offset":10}' --export out.svg   # 需先选中路径
cadcraft-cli run plan.dxf --script-file setup.scr --save out.dxf
effectcraft-cli script title.jsx project.ecproj   # After Effects 风格 JSX 对象模型
filmcraft-cli exec timeline.razor seconds=3.5     # key=value 参数，值能解析为 JSON 就解析
lightcraft-cli run --import photo.jpg develop.set control=light.exposure value=0.7 develop.auto app.export path=out.jpg
solidcraft-cli run design.sc --out part.step      # 旧写法 input.scad --export 已过时
```

编辑类命令的实测要点：

- `--cmd` 的写法分两派：**WordCraft / DeckCraft / GridCraft / PhotoCraft** 用 `--cmd 'id={json}'`；**VectorCraft / EffectCraft** 用 `--cmd ID --params '<json>'`（EffectCraft 是 `exec ID --params`）。命令 ID 以 `commands` 列出的为准。
- EffectCraft / FilmCraft 的 `--save` / `--save-as` **只在工程被改动后才落盘**：先跑一条变更命令（如 `comp.new`、`file.newBin`）再保存，否则静默不写文件。
- FigCraft `export` / `render` 的输出路径是 `-o` / `--out` 选项，不是位置参数。
- 长任务放宽超时：SolidCraft 的 `run → step`、`snapshot`、FilmCraft 的 PNG 导出可能各需 60–100 秒，建议 180–240 秒超时。

### 批量
```powershell
photocraft-cli batch --actions actions.json --in photos\ --out edited\ --recursive
pdfcraft-cli batch *.pdf --steps convert,ocr,optimize --out-dir out\
# 其它没有 batch 的 app：用 PowerShell 循环
Get-ChildItem *.docx | ForEach-Object { & "$env:ProgramFiles\WordCraft\wordcraft-cli.exe" convert $_.FullName ($_.BaseName + '.md') }
```

### 给 AI 助手接 MCP（用户要求时才做）
大多数 CLI 有 `<cli> mcp`（stdio），例如 `wordcraft-cli mcp`、`pdfcraft-cli mcp`、`vectorcraft-cli mcp`；
WordCraft/PdfCraft/DesignCraft/EffectCraft 等支持 `--automation-read-root` / `--automation-write-root` 限制可访问目录。
若当前 profile 装了 `@ninkch/dsh-artcraft` 插件，也可以直接用它的 `artcraft_cli` 工具执行同一批命令。

## 写入与安全
- `convert` 不会覆盖输入：`IN == OUT` 会被拒绝（PhotoCraft 要 `--in-place` 才允许）。
- 批量或覆盖前先对单个文件试跑，产物写新路径；保留原文件。
- 大 PSD/PSB 可能触发内存限制，PhotoCraft 用 `--approve-high-memory` 显式批准。
- 不是每个 app 都能写出所有格式：以 `<cli> --help` 和 `references/apps.md` 的读写表为准；写不了就换目标格式或换 app。
- 命令失败时读 stderr 与退出码（多数 CLI：0 成功、1 命令失败、2 用法错误），不要静默重试。

## 细节与真相来源
- `references/apps.md`：17 个 CLI 的实测总表、40+ 行扩展名路由、每个 app 的安装路径（Windows/macOS/Linux/portable）、`--help` 子命令、官方示例、读写格式、MCP 接法、格式缺口、来源 URL。
- `scripts/craft-cli.ps1`：`list` / `find` / `route` / `formats` / `<app> <args>` 透传。
- 优先级：本机 `<cli> --help` 与 `<cli> commands` > `references/apps.md` > 本文件表格。
