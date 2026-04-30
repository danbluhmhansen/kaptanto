---
phase: 16-partition-ownership-and-active-active-delivery
plan: "03"
subsystem: cluster
tags: [cluster, router, partitions, cursor, ownership, active-active, shutdown]

# Dependency graph
requires:
  - phase: 16-partition-ownership-and-active-active-delivery
    plan: "01"
    provides: PartitionStore with ClaimUnclaimed, StealStalePartitions, ReleaseAll, EpochFor
  - phase: 16-partition-ownership-and-active-active-delivery
    plan: "02"
    provides: PartitionManager, epochCursorStore, NewEpochCursorStore, Router.SetOwnedPartitions
provides:
  - runPipeline with PartitionManager wired: OpenPartitionStore before Router, epochCursorStore wrapping cursorStore, pm.SetRouter after NewRouter, pm.Run in errgroup, pm.ReleaseAll after g.Wait
  - Correct shutdown ordering: goroutine drain + cursor flush -> pm.ReleaseAll explicit call
  - Non-cluster path: byte-for-byte identical to pre-Phase-16 behavior
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "PartitionStore + NodeHeartbeater opened before NewRouter — ensures cursorStore can be epoch-fenced before Router construction (DLVR-02)"
    - "pm.SetRouter(rtr) immediately after NewRouter — breaks circular dep, activates applyToRouter on first pm.Run tick"
    - "Shutdown ordering: g.Wait() drains all goroutines (cursor flush included) then pm.ReleaseAll called explicitly from root.go"
    - "pm nil guard in shutdown block — safe for non-cluster (pm is nil var *cluster.PartitionManager)"

key-files:
  created: []
  modified:
    - internal/cmd/root.go
    - internal/cmd/root_test.go

key-decisions:
  - "Cluster setup (heartbeater + partStore + pm) moved entirely before NewRouter — DLVR-02 requires epochCursorStore to be ready before Router is constructed"
  - "pm.ReleaseAll called in root.go after g.Wait() — canonical shutdown path; pm.Run does NOT call ReleaseAll internally"
  - "fakeEventLogForCmd added in cmd_test package to satisfy eventlog.EventLog interface without importing internal test helpers"

requirements-completed: [DLVR-01, DLVR-02, DLVR-03, DLVR-04]

# Metrics
duration: 4min
completed: 2026-04-30
---

# Phase 16 Plan 03: root.go Cluster Wiring Summary

**Active-active partition ownership fully activated in runPipeline: PartitionManager + epochCursorStore wired with correct pre-Router setup and graceful shutdown ordering**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-30T00:26:01Z
- **Completed:** 2026-04-30T00:30:05Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Moved all cluster setup (NodeHeartbeater + PartitionStore + PartitionManager) to before `router.NewRouter` so `cursorStore` is epoch-fenced (via `NewEpochCursorStore`) before being passed to the Router (DLVR-02)
- `pm.SetRouter(rtr)` injected immediately after `NewRouter` — activates `applyToRouter` on first `PartitionManager.tick()`
- `pm.Run` and `heartbeater.Run` added to errgroup for cluster mode; old Phase 14 cluster block inside errgroup deleted
- Shutdown ordering fixed: `g.Wait()` drains all goroutines (PostgresCursorStore cursor flush on ctx.Done) then `pm.ReleaseAll(context.Background())` called explicitly
- Compile-guard test `TestRouterSetOwnedPartitions` confirming `SetOwnedPartitions` signature stability
- `make build`, `make test` (19 packages all pass), and `make verify-no-cgo` all green

## Task Commits

Each task was committed atomically:

1. **Task 1: Wire PartitionManager into runPipeline** - `c1dee8a` (feat)
2. **Task 2: Add compile-guard test and run full verification** - `bc2b40a` (test)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `internal/cmd/root.go` — Phase 16 cluster block before NewRouter; pm.SetRouter after NewRouter; heartbeater.Run + pm.Run in errgroup; pm.ReleaseAll after g.Wait
- `internal/cmd/root_test.go` — fakeEventLogForCmd, TestRouterSetOwnedPartitions compile guard

## Decisions Made

- Cluster setup moved entirely before NewRouter — DLVR-02 requires epochCursorStore to be ready before Router is constructed; placing it inside the errgroup block (Phase 14 pattern) was too late
- pm.ReleaseAll called in root.go after g.Wait() — canonical shutdown path matches plan invariant; pm.Run does NOT call ReleaseAll internally
- fakeEventLogForCmd defined in cmd_test package — avoids importing internal router test helpers across package boundaries; minimal 4-method stub satisfies eventlog.EventLog interface

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

Disk space was nearly full during `make build` (link step failed with "no space left on device"). Resolved by running `go clean -cache` to free ~1.2GB of build cache. Code compilation was unaffected — `go build ./internal/cmd/...` succeeded before the cache clean.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 16 is fully complete. All four requirements (DLVR-01 through DLVR-04) are implemented across Plans 01-03.
- A Kaptanto cluster node now: starts, claims unclaimed partitions from `kaptanto_partitions`, exposes them to the Router via PartitionManager, blocks zombie cursor saves via epochCursorStore, and releases partitions on graceful shutdown.
- Crash-leave recovery happens on surviving node's next PartitionManager.tick() after staleThreshold elapses.
- Non-cluster deployments are byte-for-byte identical to pre-Phase-16.

## Self-Check: PASSED

- FOUND: internal/cmd/root.go
- FOUND: internal/cmd/root_test.go
- FOUND: .planning/phases/16-partition-ownership-and-active-active-delivery/16-03-SUMMARY.md
- FOUND commit: c1dee8a (Task 1)
- FOUND commit: bc2b40a (Task 2)

---
*Phase: 16-partition-ownership-and-active-active-delivery*
*Completed: 2026-04-30*
