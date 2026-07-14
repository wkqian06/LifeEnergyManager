const fs = require("fs");
const path = require("path");
const { createWorkbenchHarnessFromHtml } = require("../plan-revision-guard/workbench_harness.js");

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

async function verifyWorkbench(dayDirectory, result) {
  const htmlPath = path.join(dayDirectory, "workbench.html");
  const wallpaperPath = path.join(dayDirectory, "wallpaper.png");
  if (!result.artifactExpected) {
    assert(!fs.existsSync(htmlPath), `Day ${result.dayIndex}: blocked day emitted workbench.html`);
    assert(!fs.existsSync(wallpaperPath), `Day ${result.dayIndex}: blocked day emitted wallpaper.png`);
    return false;
  }

  assert(fs.existsSync(htmlPath), `Day ${result.dayIndex}: workbench.html is missing`);
  assert(fs.existsSync(wallpaperPath), `Day ${result.dayIndex}: wallpaper.png is missing`);
  const plan = JSON.parse(fs.readFileSync(path.join(dayDirectory, "plan.json"), "utf8"));
  const wallpaperConfig = JSON.parse(fs.readFileSync(path.join(dayDirectory, "wallpaper-config.json"), "utf8"));
  assert(plan.planRevisionId === result.revisionAfter,
    `Day ${result.dayIndex}: plan revision differs from result`);
  assert(wallpaperConfig.planRevisionId === plan.planRevisionId,
    `Day ${result.dayIndex}: wallpaper config revision differs from plan`);
  const html = fs.readFileSync(htmlPath, "utf8");
  const harness = createWorkbenchHarnessFromHtml(html, {}, htmlPath);
  const report = harness.nodes.get("report").value;
  assert(report.includes(`Plan revision: ${result.revisionAfter}`),
    `Day ${result.dayIndex}: generated report revision mismatch`);
  assert(report.includes("Goal alerts:"), `Day ${result.dayIndex}: report omitted Goal alerts`);
  assert(report.includes("Unplanned work:"), `Day ${result.dayIndex}: report omitted Unplanned work`);
  assert(result.scoring && result.scoring.expected,
    `Day ${result.dayIndex}: artifact day is missing simulated evening scoring`);
  assert(result.scoring.stages.map(stage => stage.name).join(",") ===
    "blind_pass_persisted,self_fixture_loaded,calibration" &&
    result.scoring.stages[0].selfScoresVisible === false &&
    result.scoring.blindResultHashBeforeSelf === result.scoring.blindResultHashAfterCalibration &&
    result.scoring.stages.every(stage => stage.blindResultHash === result.scoring.blindResultHashBeforeSelf),
  `Day ${result.dayIndex}: scoring order does not preserve blind-pass isolation`);
  if (result.dayIndex === 1) {
    assert(plan.scoringInput && plan.scoringInput.applied === false,
      "Day 1: scoring feedback should be explicitly unavailable before any evening history exists");
  } else {
    assert(plan.scoringInput && plan.scoringInput.applied === true &&
      Number.isFinite(Number(plan.scoringInput.remainingCalibrated)) &&
      Number.isFinite(Number(plan.scoringInput.actualDrive)) && plan.scoringInput.planningAdjustment,
    `Day ${result.dayIndex}: next-day plan did not consume the latest completed score row`);
    if (plan.scoringInput.predictionTargetDate) {
      assert(plan.scoringInput.predictionTargetDate === plan.date &&
        Number.isFinite(Number(plan.scoringInput.predDriveCalibrated)),
      `Day ${result.dayIndex}: current-day prediction is not target-date aligned`);
    }
    assert(harness.nodes.get("recordedDays").textContent !== "0 / 7",
      `Day ${result.dayIndex}: Recent State did not render scoring history`);
  }
  const expectedScoreAdjustedTargets = { 5: 120, 7: 90, 10: 90, 12: 120 };
  if (expectedScoreAdjustedTargets[result.dayIndex]) {
    assert(plan.focusTargetMinutes === expectedScoreAdjustedTargets[result.dayIndex],
      `Day ${result.dayIndex}: score feedback did not change focus target to ${expectedScoreAdjustedTargets[result.dayIndex]}`);
  }

  const alerts = plan.goalAlerts || [];
  if (alerts.length === 0) {
    assert(report.includes("Goal alerts:\n- none"), `Day ${result.dayIndex}: no-alert report is inconsistent`);
    assert(!wallpaperConfig.goalAlert, `Day ${result.dayIndex}: no-alert plan emitted wallpaper alert`);
    assert(harness.nodes.get("primaryGoalTitle").textContent === "Goal Guard passed",
      `Day ${result.dayIndex}: no-alert DOM did not render pass state`);
  } else {
    const primary = alerts[0];
    assert(wallpaperConfig.goalAlert.goalId === primary.goalId,
      `Day ${result.dayIndex}: wallpaper Goal ID differs from plan`);
    assert(wallpaperConfig.goalAlert.goalLevel === primary.level,
      `Day ${result.dayIndex}: wallpaper goal level differs from plan`);
    assert(wallpaperConfig.goalAlert.deadline === primary.currentDeadline,
      `Day ${result.dayIndex}: wallpaper deadline differs from plan`);
    assert(wallpaperConfig.goalAlert.level === primary.proximity,
      `Day ${result.dayIndex}: wallpaper risk differs from plan`);
    assert(wallpaperConfig.goalAlert.requiredToday === primary.requiredToday,
      `Day ${result.dayIndex}: wallpaper required action differs from plan`);
    assert(wallpaperConfig.goalAlert.additionalCount === alerts.length - 1,
      `Day ${result.dayIndex}: wallpaper additional alert count differs from plan`);

    const primaryMeta = harness.nodes.get("primaryGoalMeta").textContent;
    const primaryAction = harness.nodes.get("primaryGoalAction").textContent;
    assert(primaryMeta.includes(primary.goalId) && primaryMeta.includes(primary.level) &&
      primaryMeta.includes(primary.currentDeadline) && primaryMeta.includes(primary.feasibility),
    `Day ${result.dayIndex}: primary alert DOM lacks Goal ID/level/deadline/feasibility`);
    assert(harness.nodes.get("primaryGoalSeverity").textContent === primary.proximity,
      `Day ${result.dayIndex}: primary alert DOM risk differs from plan`);
    assert(primaryAction.includes(primary.requiredToday),
      `Day ${result.dayIndex}: primary alert DOM required action differs from plan`);
    const cardsHtml = harness.nodes.get("goalAlertCards").innerHTML;
    const cardSegments = cardsHtml.split('<article class="goal-alert-card ').slice(1);
    for (const alert of alerts) {
      const reportLine = `- ${alert.goalId} | ${alert.level} | ${alert.proximity} | ${alert.feasibility} | due ${alert.currentDeadline} | required today: ${alert.requiredToday}`;
      assert(report.includes(reportLine), `Day ${result.dayIndex}: report alert semantics differ for ${alert.goalId}`);
      const cardHtml = cardSegments.find(segment => segment.includes(escapeHtml(alert.goalId)));
      assert(cardHtml, `Day ${result.dayIndex}: no dedicated alert card for ${alert.goalId}`);
      for (const value of [alert.goalId, alert.level, alert.currentDeadline, alert.proximity, alert.requiredToday]) {
        assert(cardHtml.includes(escapeHtml(value)), `Day ${result.dayIndex}: ${alert.goalId} card lacks ${value}`);
      }
    }
  }

  await harness.dispatchBody("input", {
    dataset: { field: "unplannedWork" }, value: "persisted review request", type: "textarea"
  });
  await harness.dispatchBody("input", {
    dataset: { field: "unplannedMinutes" }, value: "45", type: "number"
  });
  await harness.dispatchBody("input", {
    dataset: { field: "unplannedDisplaced" }, value: "optional maintenance", type: "textarea"
  });
  const selfScores = result.scoring.selfScores;
  for (const [field, value, type] of [
    ["remainingSelf", String(selfScores.remainingSelf), "number"],
    ["remainingNote", selfScores.remainingNote, "text"],
    ["predDriveSelf", String(selfScores.predDriveSelf), "number"],
    ["predDriveNote", selfScores.predDriveNote, "text"]
  ]) {
    await harness.dispatchBody("input", { dataset: { field }, value, type });
  }
  const reloaded = createWorkbenchHarnessFromHtml(html, Object.fromEntries(harness.storage), htmlPath);
  const reloadedReport = reloaded.nodes.get("report").value;
  assert(reloadedReport.includes("Work: persisted review request") &&
    reloadedReport.includes("Minutes: 45") && reloadedReport.includes("What it displaced: optional maintenance"),
  `Day ${result.dayIndex}: localStorage fields did not survive reload`);
  assert(reloadedReport.includes(`Energy remaining, self: ${selfScores.remainingSelf} / 100`) &&
    reloadedReport.includes(`Predicted next-day drive, self: ${selfScores.predDriveSelf} / 100`) &&
    reloadedReport.includes(selfScores.remainingNote) && reloadedReport.includes(selfScores.predDriveNote),
  `Day ${result.dayIndex}: simulated self-scores were not persisted into the generated report`);

  await reloaded.click("copyReport");
  assert(reloaded.clipboardText === reloadedReport, `Day ${result.dayIndex}: copy report did not preserve content`);
  await reloaded.click("downloadReport");
  assert(reloaded.createdAnchors.length === 1, `Day ${result.dayIndex}: download did not create one anchor`);
  return true;
}

async function main() {
  const resultsRoot = process.argv[2];
  assert(resultsRoot, "Usage: node verify-generated-workbenches.js <results-root>");
  const dayDirectories = fs.readdirSync(resultsRoot, { withFileTypes: true })
    .filter(entry => entry.isDirectory() && /^day-\d{2}-/.test(entry.name))
    .sort((left, right) => left.name.localeCompare(right.name));
  assert(dayDirectories.length === 14, `Expected 14 day directories, found ${dayDirectories.length}`);

  let artifactDays = 0;
  let scoredDays = 0;
  for (const entry of dayDirectories) {
    const dayDirectory = path.join(resultsRoot, entry.name);
    const resultPath = path.join(dayDirectory, "result.json");
    assert(fs.existsSync(resultPath), `${entry.name}: result.json is missing`);
    const result = JSON.parse(fs.readFileSync(resultPath, "utf8"));
    if (result.scoring && result.scoring.expected) scoredDays += 1;
    if (await verifyWorkbench(dayDirectory, result)) artifactDays += 1;
  }
  assert(artifactDays === 10, `Expected 10 artifact days, found ${artifactDays}`);
  assert(scoredDays === 10, `Expected 10 scored evening days, found ${scoredDays}`);
  process.stdout.write(JSON.stringify({ status: "pass", totalDays: 14, artifactDays, scoredDays }));
}

main().catch(error => {
  process.stderr.write(`${error.stack || error.message}\n`);
  process.exit(1);
});
