# Changelog

All notable changes to the **squad** plugin will be documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/). Versioning follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.3.0] - 2026-03-01

### Added

- add auto-versioning with conventional commits
- add marketplace configuration for squad plugins

### Fixed

- add startup health check and fallback for stale agent deployment


## [0.2.0] - 2026-03-01

### Added

- 7-stage pipeline: RECON → PLAN → EXECUTE → INTEGRATE → VERIFY → DEBRIEF → RETRO
- INTEGRATE stage with additive merge methodology
- Convoy deployment for large teams (batched agent spawning)
- Agent output standardization: manifest.md, interface-changes.md, .complete
- Contract-ack mechanism to verify agent liveness
- Dynamic gate escalation rules (3+ conflict files, 20+ commit drift, baseline regression)
- Isolation strategy selection: worktree / file-boundary / none
- Knowledge aging mechanism in retrospective
- Integration reflection metrics
- Resilience config: startup_timeout, respawn, fallback_to_direct

### Changed

- Upgraded squad.md to v0.2 pipeline (from 5-stage to 7-stage)
- Expanded gate-check with INTEGRATE gate and dynamic escalation
- Status report updated to include INTEGRATE section and 7-stage format
- Mission planning now includes isolation strategy and convoy planning
- Role forging includes contract-ack, artifact typing, output standardization

## [0.1.0] - 2026-02-28

### Added

- Initial plugin scaffold
- /squad command — main orchestration entry point
- 6 skills: gate-check, mission-planning, role-forging, retrospective, status-report, tool-forging
- Stop hook to protect active missions
- Config defaults and knowledge base bootstrap templates
- NATO phonetic agent naming (Alpha~Foxtrot)
