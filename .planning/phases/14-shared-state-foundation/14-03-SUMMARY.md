---
phase: 14-shared-state-foundation
plan: "03"
subsystem: database
tags: [postgres, pgx, cluster, cursor-store, backfill, heartbeat, cdc, ha, cmd]

requires:
  - phase: 14-01
    provides: "PostgresCursorStore + Cluster/ClusterDSN config fields"
  - phase: 14-02
    provides: "PostgresBackfillStore + NodeHeartbeater"
provides:
  - "--cluster and --cluster-dsn flags registered in root.go CLI"
  - "Conditional PostgresCursorStore wiring in runPipeline behind cfg.Cluster"
  - "Conditional PostgresBackfillStore wiring in runPipeline behind cfg.Cluster"
  - "NodeHeartbeater opened and run as errgroup goroutine when cfg.Cluster"
  - "Ping(ctx) method on PostgresCursorStore for /healthz endpoint"
  - "runMongoPipeline updated to accept ConsumerCursorStore interface + cursorRun func"
affects:
  - 15-partition-aware-routing
  - 16-partition-handoff

tech-stack:
  added: []
  patterns:
    - "Conditional store wiring: cfg.Cluster branch opens Postgres stores; else branch leaves SQLite paths byte-for-byte identical"
    - "cursorRun/cursorPing/cursorSetMetrics closures abstract concrete type methods behind interface usage"
    - "NodeHeartbeater added to errgroup after store opens — same lifecycle as all other background goroutines"
    - "runMongoPipeline signature uses router.ConsumerCursorStore interface + cursorRun func, not concrete *SQLiteCursorStore"

key-files:
  created: []
  modified:
    - internal/cmd/root.go
    - internal/cmd/root_test.go
    - internal/checkpoint/postgres_cursor_store.go

key-decisions:
  - "cursorRun/cursorPing/cursorSetMetrics closures used to bridge concrete method dispatch through interface variable — avoids type assertion at every call site"
  - "Ping(ctx context.Context) added to PostgresCursorStore (Rule 2 auto-fix) — /healthz probe requires it; SQLiteCursorStore.Ping() had no-arg signature so closure adapts both"
  - "runMongoPipeline signature changed to router.ConsumerCursorStore interface + explicit cursorRun func parameter — preserves MongoDB path compatibility with cluster mode"
  - "NodeHeartbeater wired after store opens but before g.Wait() — ensures heartbeat starts only when all stores are healthy"

patterns-established:
  - "Abstract lifecycle methods (Run, Ping, SetMetrics) via closures when switching between concrete store types behind an interface"

requirements-completed:
  - STATE-01
  - STATE-02
  - STATE-03

duration: 5min
completed: "2026-04-27"
---

# Phase 14 Plan 03: Shared State Foundation - root.go Wiring Summary

**--cluster / --cluster-dsn flag wiring in root.go: PostgresCursorStore, PostgresBackfillStore, and NodeHeartbeater conditionally activated behind cfg.Cluster, completing Phase 14 shared-state foundation**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-04-27T19:25:53Z
- **Completed:** 2026-04-27T19:28:45Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Registered `--cluster` (bool) and `--cluster-dsn` (string) flags in `NewRootCmd` — mirror the existing `--ha` flag pattern exactly
- Added validation guard: `--cluster-dsn is required when --cluster is set` — fails before any connection is attempted
- `PostgresCursorStore` replaces `SQLiteCursorStore` in the cursor store branch when `cfg.Cluster`; SQLite else-branch left byte-for-byte identical
- `PostgresBackfillStore` replaces `SQLiteBackfillStore` in the backfill store branch when `cfg.Cluster`; SQLite else-branch left byte-for-byte identical
- `NodeHeartbeater` opened and run as an `errgroup` goroutine when `cfg.Cluster` — maintains `kaptanto_nodes` heartbeats
- Added `Ping(ctx context.Context) error` to `PostgresCursorStore` for `/healthz` probe compatibility
- Updated `runMongoPipeline` signature to use `router.ConsumerCursorStore` interface and explicit `cursorRun func(ctx context.Context)` parameter
- `TestClusterFlagRegistered` and `TestClusterWithoutDSNReturnsError` tests confirm flag registration and validation guard
- `make test` green (CGO_ENABLED=0) — all existing tests pass, 2 new tests added
- `make verify-no-cgo` green — linux/amd64 + darwin/arm64 cross-compile clean

## Task Commits

Each task was committed atomically:

1. **Task 1: Register --cluster flags and wire Postgres stores in root.go** - `ef1f75d` (feat)
2. **Task 2: Full suite pass and CGO verification** - `1e7a577` (chore)

## Files Created/Modified
- `internal/cmd/root.go` - --cluster/--cluster-dsn flags, validation guard, conditional cursor/backfill/heartbeater store wiring, updated runMongoPipeline call
- `internal/cmd/root_test.go` - Added TestClusterFlagRegistered and TestClusterWithoutDSNReturnsError
- `internal/checkpoint/postgres_cursor_store.go` - Added Ping(ctx) method for /healthz probe

## Decisions Made
- `cursorRun`, `cursorPing`, and `cursorSetMetrics` closure variables abstract the concrete `Run`/`Ping`/`SetMetrics` method dispatch, avoiding type assertions at each call site while keeping `cursorStore` as the `router.ConsumerCursorStore` interface
- `Ping(ctx context.Context) error` was added to `PostgresCursorStore` (auto-fix Rule 2 — missing critical functionality) — the `/healthz` probe requires a ping function and `SQLiteCursorStore.Ping()` had a zero-arg signature requiring a closure adapter regardless
- `runMongoPipeline` signature updated to `router.ConsumerCursorStore` interface + `cursorRun func(ctx context.Context)` — MongoDB path is now cluster-mode compatible with no further changes needed

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added Ping(ctx) to PostgresCursorStore**
- **Found during:** Task 1 (wiring cursor store health probe)
- **Issue:** `/healthz` requires a ping function for the cursors probe; `PostgresCursorStore` had no `Ping` method
- **Fix:** Added `Ping(ctx context.Context) error` calling `s.conn.Ping(ctx)`
- **Files modified:** `internal/checkpoint/postgres_cursor_store.go`
- **Verification:** Build passes, health probe closure compiles correctly
- **Committed in:** `ef1f75d` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 missing critical)
**Impact on plan:** Auto-fix required for /healthz correctness. No scope creep.

## Issues Encountered
None — build and tests green on first attempt after all edits.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 14 complete: all three shared-state stores (PostgresCursorStore, PostgresBackfillStore, NodeHeartbeater) wired and conditionally active behind `--cluster`
- Single-node deployments (no `--cluster`) are completely unaffected
- Phase 15 (partition-aware routing) can use `NodeHeartbeater.StaleNodes()` to detect failed nodes
- Phase 16 (partition handoff) can use `PostgresCursorStore` for cursor position sharing across nodes

## Self-Check: PASSED

- [x] `internal/cmd/root.go` modified — --cluster flags, guard, conditional stores
- [x] `internal/cmd/root_test.go` modified — 2 new cluster tests
- [x] `internal/checkpoint/postgres_cursor_store.go` modified — Ping method added
- [x] Task 1 commit `ef1f75d` verified in git log
- [x] Task 2 commit `1e7a577` verified in git log
- [x] `make test` passes (CGO_ENABLED=0)
- [x] `make verify-no-cgo` passes

---
*Phase: 14-shared-state-foundation*
*Completed: 2026-04-27*
