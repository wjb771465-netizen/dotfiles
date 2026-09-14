# Human 层：生成或更新 README.md

## 判断分支

### 分支 A：README.md 不存在（新建）

按以下模板生成 `README.md`：

```markdown
# [项目名]

## Overview
[项目简介，2-3句：是什么、解决什么问题、当前阶段]

## Architecture
[系统结构描述，说明核心模块及其关系。可用简单列表或文字段落。]

## Getting Started
[如何运行项目，包含环境要求和启动命令]

## Key Workflows
[主要使用场景或操作流程，1-3个]
```

### 分支 B：README.md 已存在（增量更新）

读取现有 README.md，仅更新或插入 `Overview` 和 `Architecture` 两个段落：
- 若段落已存在且内容仍准确，保留原内容
- 若对话中有新信息，更新对应段落
- 其余段落（Getting Started、安装、贡献指南等）一律保留不动

## 写入

将结果写入项目根目录 `README.md`。完成后告知用户更新了哪些段落。
