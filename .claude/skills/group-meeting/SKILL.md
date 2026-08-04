---
name: group-meeting
description: Create or update lab group-meeting PPTX decks from the DUT template, session.yaml, and optional notes/Zotero/git sources. Trigger when the user mentions 组会, 组会PPT, group meeting, or weekly lab presentation slides.
---

# Group Meeting PPT

Lab group-meeting decks: **OfficeCLI** edits a fixed PowerPoint template. Content sources (priority order):

1. **本地笔记**（`session.yaml` 指定的 md；先读再写）
2. **Zotero MCP**（对比表、单篇笔记；key 由当次 session 提供）
3. **git 进展摘要**（工作进展页；经 `scripts/summarize_git.sh`）
4. 用户当次修改的 PPT 正文（**勿覆盖**）

## Dependencies

1. **OfficeCLI** — `officecli --version` (install via `curl -fsSL https://d.officecli.ai/install.sh | bash`)
2. **Official `pptx` skill** — `officecli skills install pptx` (quality gates, layout rules). Read it with `load_skill pptx` or `~/.claude/skills/officecli-pptx/SKILL.md`.
3. **Zotero MCP** (`user-zotero`) — optional; Zotero desktop open for local read; Web API for writes.

Shell commands that touch `officecli open` need **full permissions** (resident process uses sockets; sandbox blocks it).

## Paths

| Item | Path |
|------|------|
| Template | `~/KB/group-meetings/组会模版.pptx` |
| Session dir | `~/KB/group-meetings/<YYYY-MM-DD>/` |
| Output | `~/KB/group-meetings/<YYYY-MM-DD>/组会<月>.<日>王俊博.pptx` |
| Session manifest | `~/KB/group-meetings/<YYYY-MM-DD>/session.yaml` |
| Assets / formulas | `~/KB/group-meetings/<YYYY-MM-DD>/assets/`（公式在 `assets/formulas/`） |
| Formula script | `~/.claude/skills/group-meeting/scripts/latex_render.py`（vendored from ppt-master） |
| Init / git / QA | `scripts/init_deck.sh` · `summarize_git.sh` · `qa_deck.sh` |
| Session template | `~/.claude/skills/group-meeting/templates/session.yaml` |

写 PPT 前 `Read` session 与其中列出的笔记；勿凭记忆编造。不确定处标 `needs-verify`。

## Page types (extensible)

| Type | Use | Content source |
|------|-----|----------------|
| 封面 | Name + date | Template + `session.date` |
| 思路 | Single-topic bullets | `session` 指定 md |
| 对比表 | Multi-object comparison | Zotero note / md table / user table; optional architecture PNG |
| 多文打包 | 2–3 sentences × N items on one slide | Same as above |
| 上下周工作 | Title + empty body or bullets | User hand-fill preferred |
| 工作进展 | Code / experiment progress | `scripts/summarize_git.sh` + `session` repos |

Arc comes from **当次 `session.yaml`**, not a fixed slide list.

## Workflow

### 1. Init session dir

```bash
bash ~/.claude/skills/group-meeting/scripts/init_deck.sh YYYY-MM-DD
# prints FILE=... ; creates dir, copies template, writes session.yaml stub
FILE=~/KB/group-meetings/YYYY-MM-DD/组会M.D王俊博.pptx
# edit session.yaml (slides / sources / repos), then:
officecli open "$FILE"
```

### 2. Orient

```bash
officecli view "$FILE" outline
officecli view "$FILE" annotated
officecli get "$FILE" "/slide[1]" --depth 1   # cover shape IDs
```

Template content slides use layout **`Blank Slide`**. Copy an existing content slide instead of `layout=blank`:

```bash
officecli add "$FILE" / --type slide --from '/slide[2]' --index 2
```

### 3. Cover (slide 1)

- Date: `/slide[1]/shape[@id=89]` → `YYYY.MM.DD`（与 session.date 一致）
- Name: already in `/slide[1]/table[@id=88]` cell (王俊博)

### 4. Fill content slides

Reuse copied slide title/body textboxes (`shape[@id=5]` title, `shape[@id=2]` body on template slide 2; IDs differ on copied slides — always `get --depth 1` first).

**Typography**

- **Body default**: 微软雅黑 **18pt**, `lineSpacing=1.5x`, `bold=false` on the shape.
- Slide **titles**: keep template bold (~28pt).
- **Selective bold** via `run` only: section labels, paper/project names, key anchors. Never leave template full-paragraph bold.
- **Multi-point body**: `list=bullet` on each bullet paragraph; intro/overview paragraphs stay plain.
- **Tables**: dense content may drop to **14pt**; header row + 维度列 bold, data cells normal.
- Recreate the text shape if runs duplicate after split edits.

**Slide layout — split text boxes (不要单框堆全文)**

按内容语义拆 **多个** `shape`，命名便于维护：

| Shape name | 用途 |
|------------|------|
| `OverviewTop` | 用户可手改的总思路；**禁止**用 `set text` 覆盖，只删下游段落或调位置/高度 |
| `HeaderLeft` / `ImgLeft` 等 | 左栏：标题 + 图/公式 PNG（按页自定名） |
| `PointsRight` / `ImgRight*` 等 | 右栏：项目符号 + 图/公式 PNG |

内容较多（公式 + 分点 + 总述）时 **必须**分栏/分框；单文本框仅用于 ≤2 段短导语。

**Formulas → PNG（本 skill `scripts/latex_render.py`）**

pptx 下 OfficeCLI 的 `--type equation` **不能**挂进 textbox，且单独点选体验差。组会默认用本 skill 的 `latex_render.py`（从 ppt-master vendored）渲透明 PNG，再 `add --type picture`：

```bash
# 1) 写 manifest：assets/formulas/images/formula_manifest.json
# 2) 渲染（用 ppt-master conda 的 python，系统 python3 常缺 Pillow）
DIR=~/KB/group-meetings/YYYY-MM-DD
/Users/wjb/miniconda3/envs/ppt-master/bin/python3 \
  ~/.claude/skills/group-meeting/scripts/latex_render.py \
  "$DIR/assets/formulas"

# 3) 插入：先 get --depth 1 定位置；高度按 PNG 宽高比 h = w * pixel_h / pixel_w
officecli add "$FILE" "/slide[N]" --type picture \
  --prop name=ImgFormula \
  --prop src="$DIR/assets/formulas/images/formula_foo.png" \
  --prop x=... --prop y=... --prop width=... --prop height=... \
  --prop alt='...'
```

- LaTeX 与对应笔记源对齐；manifest 项用 `color=#000000`、`transparent=true`、`dpi=300`
- 避免依赖本机 LaTeX；provider 链：`codecogs,quicklatex,mathpad,wikimedia`
- **不要**默认再用 `--type equation`（除非用户明确要可编辑 OMML）
- 公式 PNG 目录：`assets/formulas/images/`（`formula_*.png` + `formula_manifest.json`）
- 上游更新时：对照 `~/Workspace/ppt-master/skills/ppt-master/scripts/latex_render.py` 再拷一份覆盖

**Comparison table** — quote cells that contain commas. Use `officecli help pptx table` for props; size after `get --depth 1`.

**Pictures** — `add --type picture` with `src` under session `assets/` or paths from `session.yaml`; set `alt`.

**工作进展页** — 先跑摘要再写 bullets（勿臆造 commit）：

```bash
bash ~/.claude/skills/group-meeting/scripts/summarize_git.sh ~/Workspace/SomeRepo [since]
```

`since` 空则默认约 7 天；也可填上次组会日。

### 5. Footer fields

模板内容页页脚已是纯文本 `FooterDate` / `FooterPage`（Arial 10.5pt bold），**不要**再引入 PowerPoint `<a:fld>`。拷贝内容页后：

- 把 `FooterDate` 改成当次 `YYYY.MM.DD`
- 把 `FooterPage` 改成实际页码

若打开旧稿仍见 `#OCLI_NOTEVAL!{...}`：删掉 field shape，按同位置加回纯文本 footer（`get --depth 1` 看坐标）。

### 6. Zotero content pull（可选）

当 `session.yaml` 提供 item key 时：

```bash
zotero_get_item_metadata(item_key='...', format='json')  # .data.note may have HTML table
zotero_get_notes(item_key='...', truncate=False)
```

Prefer Zotero notes over paraphrasing abstracts. Mark uncertain items `needs-verify`.

### 7. QA & deliver

**机械门（必跑，非零 = 未完成）：**

```bash
bash ~/.claude/skills/group-meeting/scripts/qa_deck.sh "$FILE"
```

**视觉门（脚本不代替）：** 按官方 `pptx` skill Gate 3 看截图/svg；缺 Chrome 时用：

```bash
officecli view "$FILE" svg --start N --end N
```

交付 = `qa_deck.sh` PASS **且** 视觉检查收敛，然后：

```bash
officecli save "$FILE"
officecli close "$FILE"
```

## Boundaries

- Do **not** make one slide per paper/item unless asked.
- **ppt-master 整套 SVG 幻灯片**仅用于高设计答辩等；组会仍用 DUT 模板 + OfficeCLI。公式渲染用本 skill `scripts/latex_render.py`（vendored）。
- Preserve template fonts (微软雅黑), colors, and master layouts.

## 用户反馈（直接改 skill + 口头汇报）

当用户修改版式/措辞/规范后：

1. **不要**再覆盖用户手改的正文（先 `get --depth 2` 确认 `OverviewTop` 等 shape）。
2. 将可复用规则**直接写入本 `SKILL.md`**（Typography / layout / 反模式）；**不**另建 feedback 日志文件。
3. **口头汇报**：说明改了 skill 哪几段、为何改（一两句即可）。

示例反模式：整页 `bold=true`；单框塞满公式+分点+总述；默认用 `--type equation` 而非 `latex_render` PNG。
