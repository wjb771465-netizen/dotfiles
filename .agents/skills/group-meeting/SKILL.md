---
name: group-meeting
description: Generate lab group-meeting PPT content drafts from the DUT template, session.yaml, and optional notes/Zotero/git sources. Produces a reviewed session.md that a script fills into the template deck with a fixed preset format; human does the final layout. Trigger when the user mentions 组会, 组会PPT, group meeting, or weekly lab presentation slides.
---

# Group Meeting PPT（内容草稿版）

组会 deck 走「**内容草稿 → 脚本填充 → 人工排版**」三段式，不追求脚本直接产出精美 PPT。

1. 生成逐页 **`session.md` 草稿**（只写内容，不排版）
2. **人工审核 / 编辑** 草稿
3. `fill_deck.py` 按**预设格式**把文字填入每页正文文本框（微软雅黑 20pt / 1.25 行距），`**...**` 转 run 级真加粗
4. 人在 PowerPoint 里做**最终排版微调**（位置 / 图片 / 间距）

脚本不该参与排版的都交给人工。内容来源优先级：

1. **本地笔记**（`session.yaml` 指定的 md；先读再写）
2. **Zotero MCP**（对比表、单篇笔记；key 由当次 session 提供）
3. **git 进展摘要**（工作进展页；经 `scripts/summarize_git.sh`）
4. 用户当次手动改的 PPT 正文（**勿覆盖**）

## Dependencies

1. **python-pptx** — `fill_deck.py` / `check_draft.sh` 用（`base` 或 `ppt-master` conda env 已装 1.0.2）。填充全走 python-pptx，**不依赖 OfficeCLI**。
2. **OfficeCLI** — 仅可选，用于人工检查 pptx（`officecli view/get`）；非填充必需。
3. **Zotero MCP**（`user-zotero`）— 可选；Zotero desktop 开着读本地，写走 Web API。

## Paths

Skill root = `~/.agents/skills/group-meeting/`（下称 `$SKILL`）。脚本用 `$SKILL` 相对路径。

| Item | Path |
|------|------|
| Template | `$SKILL/ppt/组会模版.pptx`（**进 git**） |
| Session dir | `$SKILL/ppt/<YYYY-MM-DD>/`（**gitignore**） |
| Output | `$SKILL/ppt/<YYYY-MM-DD>/组会<月>.<日>王俊博.pptx` |
| Session manifest | `$SKILL/ppt/<YYYY-MM-DD>/session.yaml` |
| Session draft | `$SKILL/ppt/<YYYY-MM-DD>/session.md` |
| Assets / formulas | `$SKILL/ppt/<YYYY-MM-DD>/assets/`（公式在 `assets/formulas/`） |
| Scripts | `init_session.sh` · `fill_deck.py` · `check_draft.sh` · `summarize_git.sh` · `latex_render.py` |
| Session template | `$SKILL/templates/session.yaml` |

写内容前 `Read` session 与其笔记；勿凭记忆编造。不确定处标 `needs-verify`。

## Workflow

### 1. 初始化 session

```bash
bash ~/.claude/skills/group-meeting/scripts/init_session.sh YYYY-MM-DD
# 创建 ppt/<date>/，拷模板，写 session.yaml + session.md 空壳
FILE=$SKILL/ppt/<date>/组会M.D王俊博.pptx
```

### 2. 生成内容草稿（写入 `session.md`）

按来源优先级，把每一页内容写成 `session.md`（格式见下节）。公式先渲 PNG：

```bash
/Users/wjb/miniconda3/envs/ppt-master/bin/python3 \
  $SKILL/scripts/latex_render.py "$DIR/assets/formulas"
# 再把生成的 PNG 以 ![]() 引用进对应页面
```

### 3. 人工审核 `session.md`

**务必**由用户过一遍内容；用户可自由改语义、删页、调措辞。脚本不实现排版，所以只审内容。

默认用 Cursor 打开草稿，便于用户直接在编辑器里改：

```bash
cursor $DIR/session.md
```

### 4. 填充

```bash
bash $SKILL/scripts/check_draft.sh    $DIR/session.md     # 结构门：页数/图片存在/**成对/字数预算
python3 $SKILL/scripts/fill_deck.py   $FILE $DIR/session.md
```

`fill_deck.py` 从模板重建 deck：封面填日期，每个 `## 页面标题` 拷贝模板内容页并填入标题框 + 一个正文框（预设 20pt/1.25）、`**...**` 加粗、插图、页脚日期/页码。**重复运行会覆盖输出**。

### 5. 人工排版（最后一次 fill 之后）

人在 PowerPoint 里移动/缩放正文框、调图片、删装饰。**排版微调放在最后一次 fill 之后**——再跑 fill 会覆盖排版。

### 6. 打开 PPT

fill 成功后自动打开 PPT，不等用户开口：

```bash
open "$FILE"          # PPTX → 默认应用（PowerPoint）
```

## `session.md` 格式（固定语法）

```
## 封面                       <- 封面页：填日期(YYYY.MM.DD) + 姓名(模板已含)
## 页面标题                    <- 每张内容页开头 → 标题框(文本框 4)
普通段落文字                  <- 无前缀 → 正文普通段
- 项目符号点                  <- "- " 前缀 → bullet 段
**论文/关键锚点** 说明文字     <- ** ** 内 → 脚本转 run 加粗
![](assets/arch.png)          <- 图片引用，脚本插入(可带描述)
```

规则：
- 每行 = 正文框一个段落；**空行忽略**（段间隔由"段后 6pt"统一控制）。
- 每个 `## ` 开始新一页；`## 封面` 特判为封面页。
- 不做表、公式、多栏；公式统一先 `latex_render.py` 渲 PNG 再当图片。

## 填充预设格式（`fill_deck.py` 顶部常量，一处可调）

| 项目 | 值 |
|------|-----|
| 正文框字体 | 微软雅黑（Microsoft YaHei） |
| 正文字号 | 20pt |
| 行距 | 1.25 倍 |
| 段前 / 段后 | 0pt / 6pt |
| 对齐 | 左对齐 |
| 项目符号 | 单级 `•` |
| 加粗 | 仅 `**...**` 覆盖的 run |
| 标题框 | 模板 `文本框 4`，28pt 粗体，不改 |
| 页脚 | `FooterDate`/`FooterPage`（Arial 10.5pt bold），脚本填日期+页码 |
| 正文框位置 | `BODY_LEFT`/`BODY_TOP`（已按人工微调默认） |
| 图片 | 默认置于 `IMG_MIN_Y` 下方、宽 ≤ 60% 高 ≤ 40%，人工再移 |
| 每页字数预算 | 约 400 汉字（`check_draft.sh` 阈值） |

## Boundaries

- **不** 实现多栏/多框排版、公式定位、对比表自动排布——这些是旧方案的痛点。
- 不追求脚本产出的 PPT "好看"，只保证文字规范填进去；美观交给人工。
- 不用 OfficeCLI 做填充；OfficeCLI 仅可选手动检查。
- **ppt-master 整套 SVG 幻灯片**仅用于高设计答辩等；组会用 DUT 模板 + python-pptx。

## 用户反馈（直接改 skill + 口头汇报）

当用户修改版式/措辞/规范后：

1. **不要**覆盖用户手改的正文（`fill_deck` 重建前先确认）。
2. 将可复用规则（如新的默认正文框位置、字号、行距）**直接写入本 `SKILL.md`** 或 `fill_deck.py` 顶部常量；**不**另建 feedback 日志文件。
3. **口头汇报**：说明改了 skill 哪段、为何改（一两句即可）。
