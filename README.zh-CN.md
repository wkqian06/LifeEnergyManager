# LifeEnergyManager

**简体中文** | [English](README.md)

> 长期进展的瓶颈，往往不是任务清单有多长，而是你有多少精力真正采取行动。

<p align="center">
  <img src="assets/workflow.zh-CN.svg" alt="LifeEnergyManager 工作流：目标守卫与计划修正确认先于每日计划确认和产物锁定；晚间校准与周日复盘再反馈到下一轮计划。" width="100%">
</p>

LifeEnergyManager 是一套由智能体驱动的每日计划工作流。它根据长期目标、当前优先级、阻塞因素和实际可用精力，生成一份今天真正做得完的计划。项目提供两个并行版本：**Codex**（定时任务）和 **Claude Code**（本地例程）。

每天，它会帮助你生成：

- 一份现实可行的晨间计划；
- 一个本地 HTML 清单和工作台；
- 一张桌面壁纸提醒；
- 一次更新持续追踪记录的晚间复盘。

在生成这些产物前，Goal Drift Guard（目标漂移守卫）会关闭已经到期的目标，在安全容量即将耗尽时发出警告，并把会影响未来计划的变化转入明确的计划修正模式。月度、阶段和重设基线的变化需要三次独立回复确认；最终日计划还需要单独确认。

它适合那些需要依据真实状态安排工作，而不是按照“理想的一天”硬塞任务的人。

| 问题 | LifeEnergyManager 会怎么做 |
| --- | --- |
| 我今天应该做什么？ | 把更大的计划转化成现实可行的日计划。 |
| 什么任务值得我投入最好的精力？ | 为最重要的工作保护时间。 |
| 哪些事情正在卡住？ | 追踪阻塞与漂移，避免问题悄悄累积。 |
| 明天的计划应该怎样调整？ | 用今天的实际结果，让下一份计划更容易执行。 |

## 核心理念

**行动优先，记录服务于行动。** 只追踪能帮助明天采取行动的信息。

LifeEnergyManager 不追求完美计划，也不要求穷尽式的自我量化。它真正做的是：每天先检查长期目标有没有到期、漂移或超出剩余容量，再结合你最近真实完成工作的速度，提出一份需要你确认的今日计划；确认后生成可执行的 HTML 工作台和桌面壁纸，晚上再把实际用时、成果和阻塞写回记录，用来校准下一天。

它的目标是减少决策疲劳、降低开始行动的成本，并让重要工作在精力有限时仍能持续向前推进。

## 平台分流

两个版本在目录中完全分开，避免智能体混用另一平台的指令。每个平台只读取自己的这一列：

| | Codex | Claude Code |
| --- | --- | --- |
| 自动读取的入口 | `AGENTS.md` | `CLAUDE.md` |
| 工作流提示词 | `codex/prompts/` | `claudecode/prompts/` |
| Skills | `codex/skills/`（可安装的 `$life-energy-*`） | `.claude/skills/`（自动发现的 `life-energy-*`） |
| Subagents | 按 `codex/prompts/subagents.md` 使用 subagent 工具 | `.claude/agents/` 中的定义 |
| 调度方式 | 使用 RRULE `BYHOUR`/`BYMINUTE` 的本地 Codex 定时任务 | Claude Code 桌面应用中的本地 routines（系统调度器作为后备） |

平台共用的中立资源包括 `templates/`、`examples/` 和你自己的 `outputs/` 目录。两个版本的工作流逻辑、任务名称、审计区块和决策边界完全一致。

两个版本都提供相同的九个工作流 skill/角色，其中包括 `life-energy-goal-drift-guard` 和 `life-energy-plan-revision`。

## 快速开始

1. 创建你自己的 `user_plan.md`。
   - 从 `templates/user_plan.md` 开始。
   - 可参考 `examples/graduation/` 或 `examples/product_launch/user_plan.md` 中的具体示例。
   - 至少填写阶段计划和当前月计划。建议同时填写日程与输出偏好，因为它们会决定自动化任务的运行时间。

2. 使用下面与你的平台对应的提示词，让智能体配置工作流和自动化任务。

### Codex

```text
请根据 LifeEnergyManager 和我的 user_plan.md 创建自动化任务。

要求：
- 读取 LifeEnergyManager/AGENTS.md、codex/prompts/setup.md、codex/prompts/automation.md、codex/prompts/subagents.md 和我的 user_plan.md。忽略 claudecode/、.claude/ 和 CLAUDE.md；它们属于 Claude Code 版本。
- 根据 user_plan.md 初始化 outputs/life_energy_tracker.md。
- 将所有需要持续保存的输出放在 outputs/ 下。
- 将三个定时任务分别命名为 `LifeEnergyManager - <project name> (morning planning)`、`LifeEnergyManager - <project name> (evening check-in)` 和 `LifeEnergyManager - <project name> (Sunday review)`。
- 根据 codex/prompts/automation.md 创建三个定时任务：晨间计划、晚间检查和周日复盘。
- 对本地 Codex 自动化，按照 codex/prompts/automation.md 使用 RRULE `BYHOUR`/`BYMINUTE` 编码时间；不要使用 `DTSTART;TZID=...`、浮动 `DTSTART` 或 UTC `DTSTART...Z`。
- 创建任务后，核对日程摘要和 Next run 是否都显示预期的本地时间。
- 默认使用 codex/skills/ 中对应的 LifeEnergyManager skill，或已安装的 $life-energy-* skill。只有在 codex/prompts/subagents.md 定义的独立复核、并行分析、容易产生偏差的判断或影响重大的计划变更中，才升级到对应 subagent。Goal Guard 和 Plan Revision 角色遵循各自更窄的 `only` 列表。如果两者都不可用，记录由主线程回退执行。
```

### Claude Code

```text
请根据 LifeEnergyManager 和我的 user_plan.md 创建自动化任务。

要求：
- 读取 LifeEnergyManager/CLAUDE.md、claudecode/prompts/setup.md、claudecode/prompts/automation.md、claudecode/prompts/subagents.md 和我的 user_plan.md。忽略 codex/ 和 AGENTS.md；它们属于 Codex 版本。
- 根据 user_plan.md 初始化 outputs/life_energy_tracker.md。
- 将所有需要持续保存的输出放在 outputs/ 下。
- 将三个 routines 分别命名为 `LifeEnergyManager - <project name> (morning planning)`、`LifeEnergyManager - <project name> (evening check-in)` 和 `LifeEnergyManager - <project name> (Sunday review)`。
- 根据 claudecode/prompts/automation.md 创建三个 routines：晨间计划、晚间检查和周日复盘。它们必须是 Claude Code 桌面应用中的本地 routines（Routines -> New routine -> Local），使用当前工作区作为工作目录，并使用交互式权限模式。不要使用 cloud routines。
- 创建 routines 后，核对日程摘要和显示的 next run 是否都为预期的本地时间。
- 默认使用 .claude/skills/ 中对应的 life-energy-* skill。只有在 claudecode/prompts/subagents.md 定义的独立复核、并行分析、容易产生偏差的判断或影响重大的计划变更中，才升级到 .claude/agents/ 中对应的 subagent。Goal Guard 和 Plan Revision 角色遵循各自更窄的 `only` 列表。如果两者都不可用，记录由主线程回退执行。
```

3. 完成设置后，白天使用生成的 HTML 工作台。晚上，把工作台生成的报告粘贴到晚间检查自动化任务中。

自动化任务始终使用 `LifeEnergyManager - <project name> (morning planning | evening check-in | Sunday review)` 格式：括号前是自定义项目名，括号内是工作流类型。Skill pipeline 是默认执行路径；subagent 只用于独立复核、并行分析、容易产生偏差的判断和影响重大的变更。

## 文档

面向使用者的指南：

- **[中文用户指南](docs/user-guide.zh-cn.md)**：功能、日常流程、流程图、HTML/壁纸模块和不同场景下的显示差异。
- **[English User Guide](docs/user-guide.en.md)**：features, daily flow, diagram, HTML/wallpaper modules, and situation-specific displays.

实现层面的工作流契约请参阅 **[中文参考手册](REFERENCE.zh-CN.md)**，其中包括晨间/晚间/周日流程、每日评分模型、skill 与 subagent 对应关系、工作区文件布局、模板说明和示例。

## 安全说明

- 每日 energy 和 drive 分数是测试阶段的计划启发式指标，不是诊断工具。
- 不要把这套工作流用于医疗、心理、法律或财务建议。
- 不要因为某一天没有完成，就自动增加第二天的工作量。应先判断原因是精力不足、计划过量、阻塞、外部义务还是回避。

## 许可证

本项目使用 Apache License 2.0，详见 `LICENSE` 和 `NOTICE`。
