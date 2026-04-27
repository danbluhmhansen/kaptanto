---
phase: 14-shared-state-foundation
plan: "01"
subsystem: database
tags: [postgres, pgx, cursor-store, cdc, checkpoint, ha, cluster]

requires: []
provides:
  - "Cluster bool and ClusterDSN string fields in Config struct with Merge() support"
  - "PostgresCursorStore: Postgres-backed ConsumerCursorStore with dirty-map batched-flush"
  - "kaptanto_cursors table auto-created on connection (TIMESTAMPTZ, BIGINT, PRIMARY KEY)"
  - "OpenPostgresCursorStore constructor, SetMetrics setter, Run/Close lifecycle methods"
affects:
  - 14-02
  - 14-03
  - 16-partition-handoff

tech-stack:
  added: []
  patterns:
    - "Dirty-map batched flush: SaveCursor writes to in-memory map (zero Postgres I/O on hot path); flush() snapshots, clears, upserts in single pgx.Tx on ticker"
    - "Snapshot restore on flush failure: dirty entries restored only if not already re-dirtied by concurrent SaveCursor"
    - "pgx.Connect (not pgxpool) for single-connection Postgres stores — consistent with PostgresStore pattern"
    - "TIMESTAMPTZ + BIGINT schema types (no SQLite-style DATETIME or INTEGER)"
    - "LoadCursor returns 1 (not 0) on pgx.ErrNoRows — seq 0 is the dedup sentinel (RTR-03)"

key-files:
  created:
    - internal/checkpoint/postgres_cursor_store.go
    - internal/checkpoint/postgres_cursor_store_test.go
  modified:
    - internal/config/config.go

key-decisions:
  - "Used uint32 for partitionID to match ConsumerCursorStore interface exactly (not int as in PLAN SQL pseudocode)"
  - "Test file uses nil pgx.Conn (newTestPostgresCursorStore) so all tests run without Postgres — dirty-map paths, SQL constants, and restore logic all verifiable in unit tests"
  - "Snapshot restore re-inserted to dirty map only when key not already present, preventing overwrite of newer SaveCursor calls that arrived during in-flight tx"

patterns-established:
  - "PostgresCursorStore: open with OpenPostgresCursorStore, start Run(ctx) goroutine, call Close() on shutdown"
  - "SetMetrics() setter follows SetBackfillEngine/SetWatermark pattern — inject after construction, before Run"

requirements-completed:
  - STATE-01

duration: 4min
completed: "2026-04-27"
---

# Phase 14 Plan 01: Shared State Foundation - PostgresCursorStore Summary

**Postgres-backed ConsumerCursorStore with dirty-map batched flush and --cluster/--cluster-dsn config flags, enabling surviving nodes to resume delivery after crash (STATE-01)**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-04-27T19:19:49Z
- **Completed:** 2026-04-27T19:22:55Z
- **Tasks:** 2
- **Files modified:** 3 (1 modified, 2 created)

## Accomplishments
- Added `Cluster bool` and `ClusterDSN string` fields to `Config` struct with full `Merge()` flag support — mirrors the existing `HA` field pattern exactly
- Implemented `PostgresCursorStore` satisfying `ConsumerCursorStore` interface: dirty-map fast path for `SaveCursor`, dual-lookup (dirty map → Postgres) for `LoadCursor`, `pgx.Tx` batch upsert in `flush()`
- `LoadCursor` correctly returns `seq=1` on `pgx.ErrNoRows` (RTR-03 invariant: seq 0 is dedup sentinel)
- `flush()` snapshot-restore logic prevents cursor loss on transaction failure without overwriting newer `SaveCursor` calls
- 8 unit tests covering dirty-map path, idempotent saves, flush-failure restore, newer-save precedence, SQL constant integrity, and multi-partition correctness — all pass with `CGO_ENABLED=0`

## Task Commits

Each task was committed atomically:

1. **Task 1: Add Cluster config fields** - `dd5977f` (feat)
2. **Task 2: Implement PostgresCursorStore** - `f3cf3cf` (feat)

## Files Created/Modified
- `internal/config/config.go` - Added `Cluster bool` and `ClusterDSN string` fields with YAML tags and `Merge()` handlers
- `internal/checkpoint/postgres_cursor_store.go` - Full `PostgresCursorStore` implementation: constructor, SaveCursor, LoadCursor, flush, Run, Close, SetMetrics
- `internal/checkpoint/postgres_cursor_store_test.go` - 8 unit tests covering all in-memory paths (nil conn, no Postgres required)

## Decisions Made
- `partitionID` kept as `uint32` to match the `ConsumerCursorStore` interface exactly (plan pseudocode used `int`; casting to `int` done at `tx.Exec` call site for the SQL parameter)
- Tests use `newTestPostgresCursorStore()` with `nil` pgx.Conn to run without Postgres — dirty-map behavior, SQL constants, and restore logic are all independently testable
- Snapshot restore in `flush()` uses "only insert if not already dirty" to prevent overwriting newer `SaveCursor` calls that arrive during an in-flight transaction

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- Minor: unused `ctx` variable in `TestPostgresCursorStoreDefaultReturnsOne` (build error on first attempt) — removed immediately, no impact.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `PostgresCursorStore` is a drop-in replacement for `SQLiteCursorStore` — ready for `root.go` wiring in Plan 03
- `Config.Cluster` and `Config.ClusterDSN` fields available for Cobra flag registration in Plan 03
- No blockers for Phase 14 Plan 02

---
*Phase: 14-shared-state-foundation*
*Completed: 2026-04-27*
