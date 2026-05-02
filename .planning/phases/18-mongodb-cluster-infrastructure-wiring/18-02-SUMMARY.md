---
phase: 18-mongodb-cluster-infrastructure-wiring
plan: 02
subsystem: infra
tags: [cluster, postgres, membership, heartbeater, dead-code-removal]

# Dependency graph
requires:
  - phase: 18-01
    provides: runMongoPipeline wired with heartbeater and pm goroutines
  - phase: 16-partition-ownership-and-active-active-delivery
    provides: NodeHeartbeater, OpenNodeHeartbeater constructor
provides:
  - NodeHeartbeater without staleThreshold (4-field struct, 5-param constructor)
  - createNodesTableSQL with 3 columns (no partition_assignments JSONB)
  - upsertNodeSQL INSERT with 3 columns (no partition_assignments)
  - Accurate walElector comment in root.go describing allocated-but-not-Run lifecycle
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Dead code removal: fields that mislead readers without influencing behavior are removed immediately on audit discovery"
    - "Backward-compatible DDL: CREATE TABLE IF NOT EXISTS means existing tables with the removed column are unaffected"

key-files:
  created: []
  modified:
    - internal/cluster/membership.go
    - internal/cluster/membership_test.go
    - internal/cmd/root.go

key-decisions:
  - "staleThreshold removed from NodeHeartbeater struct and OpenNodeHeartbeater signature — field was never read; PartitionManager.tick computes its own threshold independently"
  - "partition_assignments removed from DDL INSERT list only (not ALTER TABLE DROP) — existing deployments keep the column harmlessly with DEFAULT '[]'; new deployments get correct 3-column schema"
  - "walElector comment corrected: walElector IS allocated for MongoDB+cluster (non-nil), just never Run — prior comment falsely implied it stays nil"

patterns-established:
  - "Audit-driven dead code removal: staleThreshold and partition_assignments were both audit findings from the v2.0 milestone review"

requirements-completed: [STATE-02, DLVR-01, DLVR-02, DLVR-03]

# Metrics
duration: 5min
completed: 2026-05-02
---

# Phase 18 Plan 02: Dead Code Removal Summary

**NodeHeartbeater struct trimmed to 4 fields, DDL cleaned to 3 columns, and walElector comment corrected — v2.0 audit dead code fully eliminated**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-05-02T14:00:00Z
- **Completed:** 2026-05-02T14:05:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Removed `staleThreshold int` field from `NodeHeartbeater` struct (4 fields remain: conn, nodeID, address, interval)
- Dropped `staleThreshold int` parameter from `OpenNodeHeartbeater` (5 params now: ctx, dsn, nodeID, address, interval)
- Removed `partition_assignments JSONB` column from `createNodesTableSQL` DDL and `upsertNodeSQL` INSERT list
- Fixed walElector comment in root.go: accurately states walElector is allocated regardless of source type, only Run for Postgres
- Updated all 5 `OpenNodeHeartbeater` call sites in membership_test.go to drop the removed argument
- Removed JSONB assertion from `TestNodeHeartbeatSQLConstants`; updated schema comment
- `make verify-no-cgo` passes; `CGO_ENABLED=0 go build ./...` and `go vet ./...` clean

## Task Commits

Each task was committed atomically:

1. **Task 1: Remove staleThreshold and partition_assignments dead code from membership.go** - `f6b7c7c` (refactor)
2. **Task 2: Update root.go call site and fix walElector comment; update membership_test.go** - `d7778ba` (refactor)

**Plan metadata:** _(docs commit follows)_

## Files Created/Modified
- `internal/cluster/membership.go` - NodeHeartbeater struct (4 fields), OpenNodeHeartbeater (5 params), DDL 3-column, upsert 3-column
- `internal/cluster/membership_test.go` - 5 call sites updated, JSONB assertion removed, comment updated
- `internal/cmd/root.go` - OpenNodeHeartbeater call drops trailing 30 arg; walElector comment corrected

## Decisions Made
- `staleThreshold` dropped entirely — it was assigned in the constructor but never read anywhere in the codebase; `PartitionManager.tick` computes its own stale threshold independently
- `partition_assignments` removed from the INSERT list only, not via ALTER TABLE DROP COLUMN — idiomatic for Go apps that do schema-on-first-use: existing tables keep the column with its `DEFAULT '[]'`, new deployments get the correct 3-column schema
- walElector comment updated to reflect actual lifecycle: for MongoDB+cluster it IS constructed (non-nil) but never `.Run()` — the previous comment said "stays nil for MongoDB callers" which was factually wrong after Phase 17 wiring

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Phase 18 complete — all 2 plans done
- MongoDB cluster infrastructure wiring is fully cleaned up: goroutines wired (Plan 01) and dead code removed (Plan 02)
- No outstanding blockers; v2.0 milestone audit items STATE-02, DLVR-01, DLVR-02, DLVR-03 all addressed

---
*Phase: 18-mongodb-cluster-infrastructure-wiring*
*Completed: 2026-05-02*
