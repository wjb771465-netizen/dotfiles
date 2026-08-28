---
name: context
description: Context is all your need.
argument-hint: "[agent | readme] - 默认生成两层"
version: 1.0.0
---

# Context Skill

## 探索阶段（所有路由共用）

执行以下步骤收集信息：

1. 运行 `find . -type f | grep -v ".git" | head -80` 获取项目文件树
2. 运行 `git log --oneline -10` 了解最近提交历史
3. 检查根目录是否存在 `CLAUDE.md` → 决定走「新建」还是「更新」分支
4. 若存在 `README.md`，读取内容（后续增量更新，不覆盖）
5. 从当前对话中提取：background（含 goal）、关键路径、规则/约束、技术栈

---

## 路由

根据 `$ARGUMENTS` 分发：

- 空 / `init` → 执行 Agent 层 + Human 层
- `agent` → 仅执行 Agent 层
- `readme` → 仅执行 Human 层

---

## Agent 层

读取并执行 `/Users/wjb/.claude/skills/context/prompts/agent-layer.md`

---

## Human 层

读取并执行 `/Users/wjb/.claude/skills/context/prompts/readme-layer.md`
