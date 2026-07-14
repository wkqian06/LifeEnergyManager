const fs = require("fs");
const path = require("path");

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function countBy(items, key) {
  return items.reduce((counts, item) => {
    const value = item[key] || "none";
    counts[value] = (counts[value] || 0) + 1;
    return counts;
  }, {});
}

function bulletCounts(counts, suffix = "") {
  return Object.entries(counts)
    .sort(([left], [right]) => left.localeCompare(right))
    .map(([name, count]) => `- \`${name}\`: ${count}${suffix}`)
    .join("\n");
}

function average(items, selector) {
  const values = items.map(selector);
  return Math.round(values.reduce((sum, value) => sum + value, 0) / values.length);
}

function buildSummary(result) {
  const days = result.days;
  assert(result.status === "pass", "Top-level simulation status is not pass");
  assert(result.outputsFingerprintBefore === result.outputsFingerprintAfter,
    "Real outputs fingerprint changed during the simulation");
  assert(result.nodeVerification && result.nodeVerification.status === "pass" &&
    result.nodeVerification.totalDays === 14 && result.nodeVerification.artifactDays === 10 &&
    result.nodeVerification.scoredDays === 10,
  "Node workbench or self-score verification is incomplete");
  assert(result.selfTests &&
    result.selfTests.confirmationNegativeCases === "pass" &&
    result.selfTests.hardDeadlineAuthoritySpoof === "pass" &&
    result.selfTests.weightedMedianRecentSeven === "pass" &&
    result.selfTests.unlockedArtifactMutation &&
    result.selfTests.unlockedArtifactMutation.blocked === false &&
    result.selfTests.unlockedArtifactMutation.htmlHashUnchanged === false &&
    result.selfTests.unlockedArtifactMutation.wallpaperHashUnchanged === false &&
    result.selfTests.unlockedArtifactMutation.planSurfaceHashesUnchanged === false,
  "Attack-oriented self-tests are incomplete");
  assert(days.length === 14, `Expected 14 days, found ${days.length}`);
  days.forEach(day => {
    assert(day.status === "pass", `Day ${day.dayIndex}: day status is not pass`);
    assert(Array.isArray(day.checks) && day.checks.length > 0,
      `Day ${day.dayIndex}: executable checks are missing`);
    assert(day.checks.every(check => check.status === "pass" && check.evidence),
      `Day ${day.dayIndex}: a check failed or lacks evidence`);
  });

  const artifactDays = days.filter(day => day.artifactExpected).length;
  const blockedDays = days.length - artifactDays;
  const scoredDays = days.filter(day => day.scoring && day.scoring.expected);
  const skippedScoreDays = days.filter(day => !day.scoring || !day.scoring.expected);
  const scoreAdjustedDays = days.filter(day => day.scoreFeedbackApplied &&
    ["Reduced", "Recovery"].includes(day.planFocusMode));
  assert(artifactDays === 10 && blockedDays === 4,
    `Expected 10 artifact days and 4 blocked days, found ${artifactDays}/${blockedDays}`);
  assert(scoredDays.length === 10 && skippedScoreDays.length === 4,
    `Expected 10 scored days and 4 explicit skips, found ${scoredDays.length}/${skippedScoreDays.length}`);

  const requiredTerminalOutcomes = ["completed", "partially_completed", "missed", "superseded", "dropped"];
  const observedTerminalOutcomes = new Set(days.map(day => day.terminalOutcome).filter(Boolean));
  requiredTerminalOutcomes.forEach(outcome =>
    assert(observedTerminalOutcomes.has(outcome), `Missing terminal outcome: ${outcome}`));

  const checkCount = days.reduce((total, day) => total + day.checks.length, 0);
  const terminalDays = days.filter(day => day.terminalOutcome);
  const rows = days.map(day => {
    const terminal = day.terminalOutcome || "-";
    const artifact = day.artifactExpected ? "HTML + PNG" : "按规则不生成";
    const plan = day.artifactExpected ? `${day.planFocusMode} / ${day.planFocusTargetMinutes} min` : "-";
    const score = day.scoring.expected
      ? `自 ${day.scoring.selfScores.remainingSelf}/${day.scoring.selfScores.predDriveSelf}; 盲 ${day.scoring.blindPass.remainingBlind}/${day.scoring.blindPass.predDriveBlind}; 实 ${day.scoring.blindPass.actualDrive}; 校 ${day.scoring.calibrated.remainingCalibrated}/${day.scoring.calibrated.predDriveCalibrated}`
      : "未评分（无晚间输入）";
    return `| ${day.dayIndex} | ${day.date} | ${day.dayLabel} | ${day.guardStatus} | ${day.revisionAfter} | ${terminal} | ${plan} | ${artifact} | ${score} | PASS |`;
  }).join("\n");

  const scoreRows = scoredDays.map(day => {
    const score = day.scoring;
    const comparison = score.actualVsPriorPredictionGap == null
      ? "无前一晚预测"
      : `${score.actualVsPriorPredictionGap >= 0 ? "+" : ""}${score.actualVsPriorPredictionGap}`;
    return `| ${day.dayIndex} | ${day.date} | ${score.selfScores.remainingSelf} | ${score.blindPass.remainingBlind} | ${score.calibrated.remainingCalibrated} | ${score.selfScores.predDriveSelf} | ${score.blindPass.predDriveBlind} | ${score.calibrated.predDriveCalibrated} | ${score.blindPass.actualDrive} | ${comparison} | ${score.divergenceFlag ? "是" : "否"} |`;
  }).join("\n");

  return `# LifeEnergyManager 14 天综合模拟报告（run2）

## 结论

本轮确定性全链路模拟通过：14/14 天通过，共执行 ${checkCount} 项逐日契约检查；${artifactDays} 天生成并验证 HTML + PNG，${blockedDays} 天因回滚、Sunday audit 或 \`closure_required\` 按规则不生成日产物。真实 \`outputs/\` 测试前后目录指纹一致。

本轮额外完整执行了每日打分链：先进行不读取自评分的 agent blind pass，再录入由测试代理模拟的用户自评分，最后生成 calibrated 分数与保守的次日调整。${scoredDays.length} 个存在晚间报告的日期完成评分；其余 ${skippedScoreDays.length} 天明确记录未评分原因，没有用占位分数补齐。

## 总览

- 测试区间：${result.startDate} 至 ${result.endDate}，连续 14 天（${result.timezone}）
- 总结果：14/14 PASS
- 产物日：${artifactDays} 天；按规则不生成：${blockedDays} 天
- 完整评分日：${scoredDays.length} 天；明确跳过：${skippedScoreDays.length} 天
- 自评平均值：剩余精力 ${average(scoredDays, day => day.scoring.selfScores.remainingSelf)}；次日动力预测 ${average(scoredDays, day => day.scoring.selfScores.predDriveSelf)}
- Blind 平均值：剩余精力 ${average(scoredDays, day => day.scoring.blindPass.remainingBlind)}；次日动力预测 ${average(scoredDays, day => day.scoring.blindPass.predDriveBlind)}；实际动力 ${average(scoredDays, day => day.scoring.blindPass.actualDrive)}
- Calibrated 平均值：剩余精力 ${average(scoredDays, day => day.scoring.calibrated.remainingCalibrated)}；次日动力预测 ${average(scoredDays, day => day.scoring.calibrated.predDriveCalibrated)}
- Blind 与自评预测相差 30+ 的日期：${scoredDays.filter(day => day.scoring.divergenceFlag).length} 天
- 评分反馈实际降低后续目标分钟：${scoreAdjustedDays.length} 天（${scoreAdjustedDays.map(day => `Day ${day.dayIndex}: ${day.planFocusMode} ${day.planFocusTargetMinutes} min`).join("；")}）
- HTML 行为验证：${result.nodeVerification.artifactDays} 个 workbench 均通过，自评分输入、localStorage、报告、复制和下载均验证
- PNG：${artifactDays} 张，正式 renderer 生成，尺寸均为 2560×1440
- 真实 \`outputs/\`：未改变（fingerprint \`${result.outputsFingerprintAfter}\`）

### 历史置信度

${bulletCounts(countBy(days, "confidence"), " 天")}

### 修订类型

${bulletCounts(countBy(days, "revisionKind"), " 天")}

### 目标终态

${bulletCounts(countBy(terminalDays, "terminalOutcome"))}

五种终态均已覆盖；\`partially_completed\` 与 \`superseded\` 验证 successor，\`completed\` 验证证据，\`missed\` 与 \`dropped\` 验证原因及剩余工作处置。

## 逐日结果

评分缩写：自 = self remaining/predicted drive；盲 = blind remaining/predicted drive；实 = actual drive；校 = calibrated remaining/predicted drive。

| Day | 日期 | 日类型 | Guard | 权威 Revision | 终态 | 计划强度/分钟 | 产物 | 评分 | 结果 |
|---:|---|---|---|---|---|---|---|---|---|
${rows}

## 评分明细

| Day | 日期 | 剩余自评 | 剩余盲评 | 剩余校准 | 动力自评 | 动力盲评 | 动力校准 | 实际动力 | 实际-前晚校准预测 | 30+ 分歧 |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
${scoreRows}

评分证据保存在每天的 \`scoring-evidence.json\`。文件明确记录 blind → self-read → calibration 的顺序、证据与推断、次日预测目标日期、前晚预测误差以及 planning adjustment。Day 5 特意模拟了“高产出但主观精力严重耗尽”，用于验证系统不会因为完成量高而惩罚性增加次日负载。

## 关键规则验证

- 评分严格使用 0–100 同向量表；模拟自评分遵循 HTML 输入的 5 分步长。
- Blind pass 标记为未读取自评分；blind 值生成后保持不变，calibrated 值位于 blind 与 self 之间。
- 今晚的 predicted drive 写入下一日期行；次日 actual drive 只用于校准比较，不直接决定负载。
- 次日计划读取最近评分历史；剩余精力 calibrated 值和 actual drive 用于保守调整，不因低完成率自动加量。
- 低于 7 个可比较工作日时使用配置基线并标记 low；达到 7 天后切换到加权历史容量和 high。
- 月/阶段及 rebaseline 的成功写入要求三个独立回复；到期无终态时 \`closure_required\` 阻塞规划和产物。
- Goal debt 不因改日期清零；产物锁后的新工作只记入 unplanned work，不修订、不重新生成。

## 验证边界

这是确定性的测试代理模拟，不冒充真实用户记录。自评分由测试代理基于各日设定的状态叙事模拟；agent blind/calibrated 值用于验证评分顺序、存储、展示和反馈接口，不构成医学或心理诊断。
`;
}

function run() {
  const [resultPath, runSummaryPath, canonicalSummaryPath] = process.argv.slice(2);
  assert(resultPath && runSummaryPath && canonicalSummaryPath,
    "Usage: node build-summary-zh.js <results.json> <run-summary.md> <canonical-summary.md>");
  const testRoot = path.resolve(__dirname);
  const outputPaths = [...new Set([runSummaryPath, canonicalSummaryPath].map(value => path.resolve(value)))];
  outputPaths.forEach(outputPath => {
    assert(outputPath.startsWith(`${testRoot}${path.sep}`),
      `Summary output escaped the test root: ${outputPath}`);
  });
  const result = JSON.parse(fs.readFileSync(resultPath, "utf8"));
  const summary = buildSummary(result);
  outputPaths.forEach(outputPath => fs.writeFileSync(outputPath, summary, "utf8"));
  process.stdout.write(JSON.stringify({ status: "pass", summary: path.resolve(runSummaryPath) }));
}

try {
  run();
} catch (error) {
  process.stderr.write(`${error.stack || error.message}\n`);
  process.exit(1);
}
