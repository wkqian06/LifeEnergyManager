# LifeEnergyManager 14 天综合测试报告

## 结论

本轮确定性全链路模拟通过：14/14 天通过，共执行 56 项逐日契约检查；10 天按规则生成并验证 HTML + PNG，4 天因回滚、Sunday audit 或 `closure_required` 按规则不生成日计划产物。真实 `outputs/` 测试前后目录指纹一致，所有测试输出均位于 `test/14-day-simulation/`。

本测试验证的是场景状态、数据、产物契约与状态机规则，不冒充真实用户的 14 天交互记录。HTML 使用 Node DOM/storage harness 执行；wallpaper 使用正式 PowerShell renderer 生成 2560x1440 PNG 并检查尺寸。

## 汇总

- 测试区间：2026-07-14 至 2026-07-27，连续 14 天（America/New_York）
- 总结果：14/14 PASS
- 正常生成产物：10 天
- 预期不生成产物：4 天
- 真实 `outputs/`：未改变（fingerprint `BA18436086E18D99331190E5C69B0E2BAED0A6D6BF8E2A929A1C7EF3424D5D10`）
- HTML 行为验证：10 个 workbench 全部执行通过
- PNG renderer/尺寸 smoke test：10 张，全部由正式 renderer 生成且为 2560x1440
- 跨产物 Revision ID：全部一致
- 攻击型负例：退出后继续确认、空 hash、hard/soft 类型伪装与无锁 mutation control 均按预期被识别

### 历史置信度

- `high`: 2 天
- `low`: 12 天

### 修订类型

- `correction`: 4 天
- `inline`: 2 天
- `none`: 5 天
- `rebaseline`: 3 天

### 目标终态

- `completed`: 1
- `dropped`: 1
- `missed`: 1
- `partially_completed`: 1
- `superseded`: 2

五种终态均已覆盖；`partially_completed` 与 `superseded` 均验证 successor，`completed` 验证证据，`missed` 与 `dropped` 验证原因及剩余工作处置。

## 逐日结果

| Day | 日期 | 日类型 | 情景 | Guard | 权威 Revision | 要求/实际确认数 | 终态 | 产物 | 结果 |
|---:|---|---|---|---|---|---:|---|---|---|
| 1 | 2026-07-14 | normal | No-impact input; low-history baseline plan | pass | PR-20260714-0 | 0/0 | - | HTML + PNG | PASS |
| 2 | 2026-07-15 | normal | Small next-week reorder inside capacity | warning | PR-20260715-1 | 1/1 | - | HTML + PNG | PASS |
| 3 | 2026-07-16 | manual_catchup | Late catch-up plus commitment added within cap | warning | PR-20260716-1 | 1/1 | - | HTML + PNG | PASS |
| 4 | 2026-07-17 | recovery | Commitment cap overflow; confirmed write fails and rolls back | warning | PR-20260716-1 | 1/1 | - | 按规则不生成 | PASS |
| 5 | 2026-07-18 | normal | Month deadline and sequence correction | warning | PR-20260718-1 | 3/3 | - | HTML + PNG | PASS |
| 6 | 2026-07-19 | travel | Sunday drift audit escalates accumulated delay to rebaseline | rebaseline_required | PR-20260718-1 | 3/0 | - | 按规则不生成 | PASS |
| 7 | 2026-07-20 | normal | Phase rebaseline with facts-change confirmation reset | warning | PR-20260720-1 | 3/3 | superseded | HTML + PNG | PASS |
| 8 | 2026-07-21 | illness | Unsupported hard-deadline move is blocked; user exits correction | warning | PR-20260720-1 | 1/0 | - | HTML + PNG | PASS |
| 9 | 2026-07-22 | closure_blocked | Due goal has no exit evidence and user does not answer | closure_required | PR-20260720-1 | 0/0 | - | 按规则不生成 | PASS |
| 10 | 2026-07-23 | normal | Due goal closes completed with evidence | pass | PR-20260720-1 | 0/0 | completed | HTML + PNG | PASS |
| 11 | 2026-07-24 | normal | Due micro-sprint closes partially completed and creates successor | warning | PR-20260724-1 | 1/1 | partially_completed | HTML + PNG | PASS |
| 12 | 2026-07-25 | normal | Due weekly goal closes missed without rolling its date | pass | PR-20260724-1 | 0/0 | missed | HTML + PNG | PASS |
| 13 | 2026-07-26 | sunday_review | Sunday phase audit closes old goal superseded with high-confidence history | rebaseline_required | PR-20260726-1 | 3/3 | superseded | 按规则不生成 | PASS |
| 14 | 2026-07-27 | normal | Dropped commitment plus post-artifact unplanned work | pass | PR-20260726-1 | 0/0 | dropped | HTML + PNG | PASS |

## 关键规则验证

- 低于 7 个可比较工作日时使用配置基线并标记 low；达到 7 天后切换到加权历史容量和 high。
- 月/阶段及 rebaseline 的成功写入要求三个独立回复；事实变化会回到第 1 次确认。
- 用户退出、hard DDL 缺少证据与模拟事务写入失败都保持原 revision；回滚日禁止生成产物。
- 到期但没有终态选择时进入 `closure_required`，规划与产物生成同时阻塞。
- Goal debt 不因改日期清零；累计漂移能升级为 rebaseline。
- HTML 报告、wallpaper config 和 plan JSON 在每个产物日共享同一个 Goal/level/DDL/risk/required action/Revision 语义；PNG 由该 config 使用正式 renderer 生成。
- 产物锁以后到达的新工作只记入 `Unplanned work`，不修订、不重新生成。

## 验证边界

本轮没有启用真实浏览器像素级宽屏/窄屏交互；仓库现有安全策略禁止替代性浏览器自动化。HTML 结构、脚本、localStorage、报告、复制与下载契约由无头 harness 验证，PNG 则由正式 renderer 实际生成。真实桌面背景与人工缩放浏览仍属于发布前人工视觉验收项。
