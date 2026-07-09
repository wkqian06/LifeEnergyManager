# Changelog

This project uses date-based changelog entries until formal version tags are introduced.

## 2026-07-08 - Daily scoring model and direct evening report intake

### Added

- Added a tracker-level `Daily Scoring Model` section as the single source for the three daily metrics:
  energy reserve, predicted next-day drive, and actual drive.
- Added separate blind and calibrated agent values for reserve and predicted drive, plus a single blind `actualDrive` metric anchored on focus minutes and completions.
- Added a shared perspective switch in the HTML Recent State chart so reserve and predicted-drive lines can be viewed as Self, Agent blind, or Agent calibrated while actual drive stays visible.
- Added explicit actual-vs-predicted comparison notes as a calibration signal.

### Changed

- Replaced the old next-day drive-resistance framing with a same-direction 0-100 scoring model where higher is better across all three metrics.
- Updated Codex and Claude Code evening contracts, automation prompts, drive-resistance skills, and the Claude `energy-quant` agent to produce the three daily metrics instead of a single resistance score.
- Updated morning planning guidance so yesterday's energy reserve and actual drive influence today's intensity, while predicted-vs-actual gaps remain calibration-only.
- Updated the HTML workbench evening inputs from one drive-resistance self-score to two self-scores: energy reserve and predicted next-day drive.
- Updated the Recent State chart, legend, metric tiles, and report text to reflect reserve / predicted drive / actual drive rather than the prior agent-vs-user resistance view.
- Updated artifact and wallpaper specs so wallpapers explicitly exclude all energy/drive scores from the three-metric model.
- Updated evening flows so they immediately ask the user to paste the workbench report and wait, instead of scanning `outputs/` for an existing report file.

### Notes

- `outputs/` and `test/` remain local ignored runtime/test state and are not part of this release.
- This entry records the repository state after the scoring-model migration across both Codex and Claude Code editions.

## 2026-07-07 - Three-score history and artifact progress row refinement

### Added

- Added a three-score next-day drive-resistance model:
  `agent_energy_score` as a blind estimate from report evidence only,
  `agent_calibrated_score` as the final estimate after weighing the user self-score,
  and the user's own evening self-score as an independent signal.
- Added a dual-axis Recent State chart in the HTML workbench with focus-minute bars on the left axis and three score series on the right axis.
- Added a new Latest calibrated metric tile to the Recent State panel.
- Added explicit artifact QA checks for the wallpaper progress row: at most 5 bars total, month progress second-to-last, and phase progress last.
- Added progress-kind chips in the HTML plan stack so phase, month, week, sprint, and commitment progress are visually classified.

### Changed

- Moved today's intensity summary in the workflow diagram from the morning planning card to the evening reflection card so it reads as an end-of-day signal.
- Updated Codex and Claude Code evening contracts, drive-resistance skills, and energy/artifact QA instructions to keep the blind score independent from the user's self-score until calibration time.
- Updated wallpaper and artifact specs so the wallpaper now has a single constrained progress row instead of unconstrained progress bars.
- Updated the Windows wallpaper generator to enforce the single progress-row layout, resize the top-right summary block, and fit task cards more reliably.
- Updated the HTML workbench to sort plan-stack progress cards by kind, render commitment cards through the commitments panel, and keep ongoing commitments out of ordinary deferred-task summaries.

### Notes

- This entry captures both the already-landed three-score/history work and the current artifact-layout refinement so the changelog matches the repository state as of 2026-07-07.
- `outputs/` and `test/` remain local ignored runtime/test state and are not part of this release.

## 2026-07-06 - Ongoing commitments lifecycle

### Added

- Added an `Ongoing Commitments` lifecycle to replace ad hoc multi-day urgent task tracking.
- Added tracker rules for commitment entry, daily disposition, skip counting, inquiry triggers, exit criteria, closure logs, and the active-commitment cap.
- Added a required morning `Commitments digest` covering every active commitment with either a today-slice, explicit skip, or inquiry decision.
- Added evening settlement rules so Skip count is updated only during evening check-in and commitment closure requires exit-criterion evidence.
- Added Sunday review checks for stale or exit-ready commitments, including expired deadlines, high Skip counts, and unresolved migration markers.
- Added a workbench commitments panel label and report behavior that keeps ongoing commitments out of ordinary deferred-task summaries.

### Changed

- Replaced `Temporary Urgent Tasks` language with `Ongoing Commitments` across Codex prompts, Claude Code prompts, skills, and Claude subagents.
- Updated urgency triage to judge one-day versus multi-day extra tasks and propose tracker-ready commitment entries for accepted multi-day work.
- Updated daily planning inputs to include active ongoing commitments and their today-allocation decisions.
- Updated entry-point rules in `AGENTS.md` and `CLAUDE.md` so commitment dispositions stay in the main agent thread.
- Updated README workflow documentation to describe commitment carryover, skip approvals, mainline displacement decisions, and weekly commitment audits.
- Updated the graduation example tracker to use the new `Ongoing Commitments` table.

### Notes

- `outputs/` and `test/` remain local ignored runtime/test state and are not part of this release.
- This update preserves the Codex and Claude Code platform split introduced earlier while keeping the commitment lifecycle consistent across both editions.
