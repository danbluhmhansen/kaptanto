---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: Distributed Architecture
status: unknown
last_updated: "2026-04-27T19:30:00.000Z"
progress:
  total_phases: 22
  completed_phases: 21
  total_plans: 53
  completed_plans: 53
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-27)

**Core value:** Every database change is captured and delivered reliably, in order, with zero infrastructure dependencies beyond the database itself.
**Current focus:** v2.0 — Phase 14: Shared State Foundation

## Current Position

Phase: 14 of 17 (Shared State Foundation)
Plan: 03 complete — Phase 14 DONE
Status: In Progress
Last activity: 2026-04-27 — Completed 14-03 (root.go cluster wiring)

Progress: [███░░░░░░░] 30% (3/3 plans complete in Phase 14)

## Performance Metrics

**Velocity:**
- Total plans completed: 0 (v2.0)
- Average duration: —
- Total execution time: —

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| - | - | - | - |

*Updated after each plan completion*
| Phase 14 P02 | 196 | 2 tasks | 4 files |
| Phase 14-shared-state-foundation P01 | 4 | 2 tasks | 3 files |
| Phase 14-shared-state-foundation P03 | 5 | 2 tasks | 3 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Path A (NATS JetStream + etcd) is the recommended distributed stack — NATS sidecar (15MB Go binary) for event log, etcd embedded peer for coordination. Path B (hashicorp/raft + Badger) is viable if a time-boxed spike confirms Badger v4 raft-badger compatibility.
- Phase 14 is the critical-path unlock — shared cursor state must exist before partition handoff (Phase 16) is possible.
- 64-partition FNV-1a scheme is fixed for lifetime of cluster — changing it invalidates all cursor positions.
- WAL source does not scale horizontally (hard Postgres protocol constraint) — distribute delivery side only.
- [Phase 14]: markOffline uses context.Background() so DELETE executes after graceful shutdown ctx cancellation
- [Phase 14]: StaleNodes returns non-nil empty slice to avoid nil-check bugs in callers
- [Phase 14-shared-state-foundation]: PostgresCursorStore uses uint32 for partitionID to match ConsumerCursorStore interface exactly
- [Phase 14-shared-state-foundation]: Test suite uses nil pgx.Conn so all PostgresCursorStore tests run without Postgres (dirty-map paths independently testable)
- [Phase 14-shared-state-foundation]: Snapshot restore in flush() only inserts if key not already dirty, preventing overwrite of newer SaveCursor calls during in-flight transaction
- [Phase 14-shared-state-foundation]: cursorRun/cursorPing/cursorSetMetrics closures abstract concrete method dispatch through interface variable — avoids type assertions at each call site
- [Phase 14-shared-state-foundation]: runMongoPipeline signature updated to router.ConsumerCursorStore interface + cursorRun func — MongoDB path cluster-mode compatible
- [Phase 14-shared-state-foundation]: Ping(ctx) added to PostgresCursorStore for /healthz probe (not on original store, added as Rule 2 auto-fix)

### Pending Todos

None yet.

### Blockers/Concerns

- Path A vs Path B decision must be made before Phase 15 planning. Recommend a 1-day spike: attempt hashicorp/raft + bsm/raft-badger with Badger v4. If cluster forms, Path B is viable; otherwise commit to Path A (NATS sidecar).
- etcd embed CGO impact must be verified before Phase 17 planning — `make verify-no-cgo` must pass with etcd embed included.

## Session Continuity

Last session: 2026-04-27T19:30:00Z
Stopped at: Completed 14-03-PLAN.md (root.go cluster wiring — Phase 14 complete)
Resume file: None
