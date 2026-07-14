# LifeEnergyManager 14 天综合模拟报告（run2）

## 结论

本轮确定性全链路模拟通过：14/14 天通过，共执行 90 项逐日契约检查；10 天生成并验证 HTML + PNG，4 天因回滚、Sunday audit 或 `closure_required` 按规则不生成日产物。真实 `outputs/` 测试前后目录指纹一致。

本轮额外完整执行了每日打分链：先进行不读取自评分的 agent blind pass，再录入由测试代理模拟的用户自评分，最后生成 calibrated 分数与保守的次日调整。10 个存在晚间报告的日期完成评分；其余 4 天明确记录未评分原因，没有用占位分数补齐。

## 总览

- 测试区间：2026-07-14 至 2026-07-27，连续 14 天（America/New_York）
- 总结果：14/14 PASS
- 产物日：10 天；按规则不生成：4 天
- 完整评分日：10 天；明确跳过：4 天
- 自评平均值：剩余精力 48；次日动力预测 57
- Blind 平均值：剩余精力 52；次日动力预测 60；实际动力 75
- Calibrated 平均值：剩余精力 50；次日动力预测 58
- Blind 与自评预测相差 30+ 的日期：1 天
- 评分反馈实际降低后续目标分钟：4 天（Day 5: Reduced 120 min；Day 7: Recovery 90 min；Day 10: Recovery 90 min；Day 12: Reduced 120 min）
- HTML 行为验证：10 个 workbench 均通过，自评分输入、localStorage、报告、复制和下载均验证
- PNG：10 张，正式 renderer 生成，尺寸均为 2560×1440
- 真实 `outputs/`：未改变（fingerprint `BA18436086E18D99331190E5C69B0E2BAED0A6D6BF8E2A929A1C7EF3424D5D10`）

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

五种终态均已覆盖；`partially_completed` 与 `superseded` 验证 successor，`completed` 验证证据，`missed` 与 `dropped` 验证原因及剩余工作处置。

## 逐日结果

评分缩写：自 = self remaining/predicted drive；盲 = blind remaining/predicted drive；实 = actual drive；校 = calibrated remaining/predicted drive。

| Day | 日期 | 日类型 | Guard | 权威 Revision | 终态 | 计划强度/分钟 | 产物 | 评分 | 结果 |
|---:|---|---|---|---|---|---|---|---|---|
| 1 | 2026-07-14 | normal | pass | PR-20260714-0 | - | Standard / 180 min | HTML + PNG | 自 55/65; 盲 60/60; 实 72; 校 58/63 | PASS |
| 2 | 2026-07-15 | normal | warning | PR-20260715-1 | - | Standard / 180 min | HTML + PNG | 自 60/70; 盲 58/68; 实 80; 校 59/69 | PASS |
| 3 | 2026-07-16 | manual_catchup | warning | PR-20260716-1 | - | Manual catch-up / 120 min | HTML + PNG | 自 45/55; 盲 48/52; 实 68; 校 47/54 | PASS |
| 4 | 2026-07-17 | recovery | warning | PR-20260716-1 | - | - | 按规则不生成 | 未评分（无晚间输入） | PASS |
| 5 | 2026-07-18 | normal | warning | PR-20260718-1 | - | Reduced / 120 min | HTML + PNG | 自 20/25; 盲 45/60; 实 85; 校 33/34 | PASS |
| 6 | 2026-07-19 | travel | rebaseline_required | PR-20260718-1 | - | - | 按规则不生成 | 未评分（无晚间输入） | PASS |
| 7 | 2026-07-20 | normal | warning | PR-20260720-1 | superseded | Recovery / 90 min | HTML + PNG | 自 50/65; 盲 52/62; 实 84; 校 51/64 | PASS |
| 8 | 2026-07-21 | illness | warning | PR-20260720-1 | - | Reduced illness day / 90 min | HTML + PNG | 自 25/35; 盲 30/40; 实 45; 校 28/38 | PASS |
| 9 | 2026-07-22 | closure_blocked | closure_required | PR-20260720-1 | - | - | 按规则不生成 | 未评分（无晚间输入） | PASS |
| 10 | 2026-07-23 | normal | pass | PR-20260720-1 | completed | Recovery / 90 min | HTML + PNG | 自 65/70; 盲 62/68; 实 78; 校 64/69 | PASS |
| 11 | 2026-07-24 | normal | warning | PR-20260724-1 | partially_completed | Standard / 180 min | HTML + PNG | 自 45/55; 盲 48/58; 实 82; 校 47/57 | PASS |
| 12 | 2026-07-25 | normal | pass | PR-20260724-1 | missed | Reduced / 120 min | HTML + PNG | 自 55/60; 盲 55/60; 实 79; 校 55/60 | PASS |
| 13 | 2026-07-26 | sunday_review | rebaseline_required | PR-20260726-1 | superseded | - | 按规则不生成 | 未评分（无晚间输入） | PASS |
| 14 | 2026-07-27 | normal | pass | PR-20260726-1 | dropped | Standard / 180 min | HTML + PNG | 自 60/70; 盲 58/68; 实 76; 校 59/69 | PASS |

## 评分明细

| Day | 日期 | 剩余自评 | 剩余盲评 | 剩余校准 | 动力自评 | 动力盲评 | 动力校准 | 实际动力 | 实际-前晚校准预测 | 30+ 分歧 |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 1 | 2026-07-14 | 55 | 60 | 58 | 65 | 60 | 63 | 72 | 无前一晚预测 | 否 |
| 2 | 2026-07-15 | 60 | 58 | 59 | 70 | 68 | 69 | 80 | +17 | 否 |
| 3 | 2026-07-16 | 45 | 48 | 47 | 55 | 52 | 54 | 68 | -1 | 否 |
| 5 | 2026-07-18 | 20 | 45 | 33 | 25 | 60 | 34 | 85 | 无前一晚预测 | 是 |
| 7 | 2026-07-20 | 50 | 52 | 51 | 65 | 62 | 64 | 84 | 无前一晚预测 | 否 |
| 8 | 2026-07-21 | 25 | 30 | 28 | 35 | 40 | 38 | 45 | -19 | 否 |
| 10 | 2026-07-23 | 65 | 62 | 64 | 70 | 68 | 69 | 78 | 无前一晚预测 | 否 |
| 11 | 2026-07-24 | 45 | 48 | 47 | 55 | 58 | 57 | 82 | +13 | 否 |
| 12 | 2026-07-25 | 55 | 55 | 55 | 60 | 60 | 60 | 79 | +22 | 否 |
| 14 | 2026-07-27 | 60 | 58 | 59 | 70 | 68 | 69 | 76 | 无前一晚预测 | 否 |

评分证据保存在每天的 `scoring-evidence.json`。文件明确记录 blind → self-read → calibration 的顺序、证据与推断、次日预测目标日期、前晚预测误差以及 planning adjustment。Day 5 特意模拟了“高产出但主观精力严重耗尽”，用于验证系统不会因为完成量高而惩罚性增加次日负载。

## 关键规则验证

- 评分严格使用 0–100 同向量表；模拟自评分遵循 HTML 输入的 5 分步长。
- Blind pass 标记为未读取自评分；blind 值生成后保持不变，calibrated 值位于 blind 与 self 之间。
- 今晚的 predicted drive 写入下一日期行；次日 actual drive 只用于校准比较，不直接决定负载。
- 次日计划读取最近评分历史；剩余精力 calibrated 值和 actual drive 用于保守调整，不因低完成率自动加量。
- 低于 7 个可比较工作日时使用配置基线并标记 low；达到 7 天后切换到加权历史容量和 high。
- 月/阶段及 rebaseline 的成功写入要求三个独立回复；到期无终态时 `closure_required` 阻塞规划和产物。
- Goal debt 不因改日期清零；产物锁后的新工作只记入 unplanned work，不修订、不重新生成。

## 验证边界

这是确定性的测试代理模拟，不冒充真实用户记录。自评分由测试代理基于各日设定的状态叙事模拟；agent blind/calibrated 值用于验证评分顺序、存储、展示和反馈接口，不构成医学或心理诊断。
