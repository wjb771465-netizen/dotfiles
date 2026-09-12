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

Skill root = `~/.claude/skills/group-meeting/`（下称 `$SKILL`）。脚本用 `$SKILL` 相对路径，不依赖 `~/KB`。

| Item | Path |
|------|------|
| Template | `$SKILL/ppt/组会模版.pptx`（**进 git**） |
| Session dir | `$SKILL/ppt/<YYYY-MM-DD>/`（**gitignore**） |
| Output | `$SKILL/ppt/<YYYY-MM-DD>/组会<月>.<日>王俊博.pptx` |
| Session manifest | `$SKILL/ppt/<YYYY-MM-DD>/session.yaml` |
| Assets / formulas | `$SKILL/ppt/<YYYY-MM-DD>/assets/`（公式在 `assets/formulas/`） |
| Formula script | `$SKILL/scripts/latex_render.py`（vendored from ppt-master） |
| Init / git / QA | `scripts/init_deck.sh` · `summarize_git.sh` · `qa_deck.sh` |
| Session template | `$SKILL/templates/session.yaml` |
| KB 软链（可选） | `~/KB/group-meetings` → `$SKILL/ppt` |

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
FILE=$SKILL/ppt/YYYY-MM-DD/组会M.D王俊博.pptx
# edit session.yaml (slides / sources / repos), then:
officecli open "$FILE"
```

**Git 版本追踪：** 每个 session 目录初始化 git，每轮制作/修改 PPT 后提交：

```bash
cd $SKILL/ppt/YYYY-MM-DD
git init
echo "*.pptx" >> .gitignore  # PPT 文件太大，不进 git（或单独追踪）
git add .
git commit -m "v1: 初始创建"

# 每轮修改后
git add -A
git commit -m "v2: 重构文本框布局"
```

回退机制：
```bash
git log --oneline           # 查看历史版本
git stash                   # 临时回退
git checkout <commit-id>    # 回退到指定版本
```

### 2. Orient

```bash
officecli view "$FILE" outline
officecli view "$FILE" annotated
officecli get "$FILE" "/slide[1]" --depth 1   # cover shape names / ids
```

Template content slides use layout **`Blank Slide`**. Copy an existing content slide instead of `layout=blank`:

```bash
officecli add "$FILE" / --type slide --from '/slide[2]' --index 2
```

**Shape handle rule：** `id=` 每次 `add --from` 拷贝都会重排，**不可作锚**；`name=` 拷贝后保持稳定。用 `get --depth 1` 读出 shape 的 `name=` 字段，再以 `shape[@name="..."]` 定位。模板各页的稳定 name 见 §3（封面）、§4（标题/正文）、§5（页脚）。

### 3. Cover (slide 1)

Cover shapes are located by `name=`, **not** `id=`（`id` 每次拷贝都会重排）。`get --depth 1` 先确认 name 再做 set：

- Date: 定位**白色 20pt、文本形如 `2026.6.1`** 的 shape，改为 `YYYY.MM.DD`（与 session.date 一致）。模板里通常即 `/slide[1]/shape[@name="CustomShape 4"]`（`get --depth 1` 确认后再 set，勿信死 id）。
- Name: `/slide[1]/table[@name="Table 3"]` cell 已是 王俊博

### 4. Fill content slides

Reuse copied slide title/body textboxes by stable **`name=`**（`id` 随每次 `add --from` 重排，不可作锚；`name=` 复制后保持不变）。模板两栏内容页：

- Title: `shape[@name="文本框 4"]`（28pt bold）
- Body: `shape[@name="文本框 1"]`（18pt）

`get --depth 1` 读 shape 的 `name=` 字段确认；自己新建的框也要起名（见下），别名后即可用 `name=` 定位。

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
DIR=$SKILL/ppt/YYYY-MM-DD
/Users/wjb/miniconda3/envs/ppt-master/bin/python3 \
  $SKILL/scripts/latex_render.py \
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

模板内容页页脚已是纯文本 `FooterDate` / `FooterPage`（Arial 10.5pt bold），**不要**再引入 PowerPoint `<a:fld>`。用 `shape[@name="FooterDate"]` / `shape[@name="FooterPage"]` 定位（name 稳定，id 会变）。拷贝内容页后：

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

**视觉核验（人工）：** 视觉门已降级为人工——**不**跑截图/svg 渲染（多模态耗时长）。交付前由人在 PowerPoint 里逐页过一遍溢出/重叠/深底深字/美观。判据以 `qa_deck.sh` 机械门为准。

交付 = `qa_deck.sh` PASS，然后：

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
