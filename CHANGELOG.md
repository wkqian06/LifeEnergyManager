# Changelog

This project uses date-based changelog entries until formal version tags are introduced.

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
