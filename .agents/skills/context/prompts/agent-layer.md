# Agent 层：生成或更新 CLAUDE.md

## 判断分支

### 分支 A：CLAUDE.md 不存在（新建）

按以下模板生成 `CLAUDE.md`，内容从对话 + 仓库探索中提取：

```markdown
# [项目名]

## Background
[1-3 句话：项目是什么 + 当前目标/正在做什么。从对话的 plan/ask 阶段提取核心信息。]

## Key Paths
| 路径 | 用途 |
|------|------|
| [path] | [用途] |

> Key Paths 粒度以**目录**为主，只在单个文件确实值得单独说明时才列出文件级条目。目标是让 agent 理解目录结构，而非穷举每个文件。

## Rules
- [约束、规范、注意事项。无则省略此段。]

## Tech Stack
- [语言、框架、关键依赖]
```

生成后，评估内容量：
- 若涉及 ≥3 个独立领域（前端/后端/基础设施等），向用户提出路由建议：
  ```
  项目涉及多个独立领域，建议拆分为路由结构：
  - CLAUDE.md（路由器，~20行，含阅读顺序和链接）
  - .claude/doc/paths.md（详细路径索引）
  - .claude/doc/rules.md（规则与约束，若内容多）
  是否按此拆分？
  ```
  路由入口格式参考（仿照 LAG-paper/AGENTS.md 风格）：
  ```markdown
  # [项目名]

  [1-2句 background + goal]

  ## 阅读顺序
  1. [`.claude/doc/paths.md`](.claude/doc/paths.md) — 路径索引
  2. [`.claude/doc/rules.md`](.claude/doc/rules.md) — 规则与约束

  ## 关键约束
  - [最重要的 1-3 条规则直接写在这里]
  ```
  等待用户确认后再生成子文档；用户拒绝则保持单文件。

### 分支 B：CLAUDE.md 已存在（更新）

1. 读取现有 `CLAUDE.md` 内容
2. **优先更新** `Key Paths` 表：对比仓库文件树与现有路径，补充新增文件，移除已删除路径
3. 其余段落（Background、Rules、Tech Stack）仅在对话中有明确新信息时才更新，否则保留原内容
4. 不覆盖用户手动添加的内容

## 写入

将结果写入项目根目录 `CLAUDE.md`。完成后告知用户更新了哪些内容。
