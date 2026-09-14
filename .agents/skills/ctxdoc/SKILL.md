---
name: ctxdoc
description: Generate or refresh a project's context docs — CLAUDE.md (agent layer) and README.md (human layer) — from repo exploration plus the current conversation. Use when the user asks to write/update CLAUDE.md or README, 初始化项目文档, 生成项目上下文, 补 CLAUDE.md, or when a repo has no CLAUDE.md but the conversation already established its background and rules. Not the builtin /init — this covers both layers and updates in place instead of overwriting.
argument-hint: "[agent | readme] - 默认生成两层"
version: 1.0.0
---

# ctxdoc Skill

## 探索阶段（所有路由共用）

执行以下步骤收集信息：

1. 运行 `find . -type f | grep -v ".git" | head -80` 获取项目文件树
   - 若当前目录不是 git 仓库、或明显混着多个不相关项目：**先停下来问用户目标项目**，不要在根目录硬生成
2. 运行 `git log --oneline -10` 了解最近提交历史
3. 检查根目录是否存在 `CLAUDE.md` → 决定走「新建」还是「更新」分支
4. 若存在 `README.md`，读取内容（后续增量更新，不覆盖）
5. 从当前对话中提取：background（含 goal）、关键路径、规则/约束、技术栈
   - 若当前对话没有项目上下文（刚开 session 就调本技能），**不要凭空编 background**：改从仓库自行推断（`README*`、`package.json` / `pyproject.toml` / `Cargo.toml`、入口目录、`git log`），把推断结果先复述给用户确认，再落笔

---

## 路由

根据 `$ARGUMENTS` 分发：

- 空 / `init` → 执行 Agent 层 + Human 层
- `agent` → 仅执行 Agent 层
- `readme` → 仅执行 Human 层

---

## Agent 层

读取并执行 `prompts/agent-layer.md`（相对本 SKILL.md 所在目录）

---

## Human 层

读取并执行 `prompts/readme-layer.md`（相对本 SKILL.md 所在目录）
