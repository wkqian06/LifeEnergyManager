# Changelog

This project uses date-based changelog entries until formal version tags are introduced.

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
