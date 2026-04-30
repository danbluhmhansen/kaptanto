---
phase: 17-distributed-source-coordination
plan: 03
subsystem: infra
tags: [cluster, wal, leader-election, epoch-fencing, mongodb, checkpoint, go]

# Dependency graph
requires:
  - phase: 17-01-distributed-source-coordination
    provides: WalLeaderElector with Run/EpochGetter and NatsEventLog.Conn() accessor
  - phase: 17-02-distributed-source-coordination
    provides: PostgresConnector.SetEpochGetter injection method and ShouldSendStandby fence guard

provides:
  - root.go cluster block: WalLeaderElector constructed and running in errgroup (SRCC-02)
  - root.go connector: SetEpochGetter(walElector.EpochGetter) active in Postgres cluster mode (SRCC-01)
  - runMongoPipeline: ckStore overridden with PostgresStore(ClusterDSN) in cluster mode (SRCC-03)
  - Non-cluster paths: byte-for-byte identical to pre-Phase-17

affects:
  - v2.0 milestone complete: SRCC-01, SRCC-02, SRCC-03 all addressed
  - internal/cmd/root.go final form for distributed source coordination

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Optional walElector pattern: var walElector *cluster.WalLeaderElector declared before cluster block, assigned inside — nil means non-cluster or MongoDB path"
    - "ckStore override at top of runMongoPipeline: cluster block reassigns local var before any connector construction"
    - "Errgroup guard: if walElector != nil { g.Go(walElector.Run) } — safe for both Postgres and MongoDB source dispatch"

key-files:
  created: []
  modified:
    - internal/cmd/root.go

key-decisions:
  - "walElector declared before event log block (not inside if cfg.Cluster{}) so it is in scope for Insertions B and C without type assertions"
  - "walElector stays nil for MongoDB source: MongoDB is dispatched before the connector block, so EpochGetter is never injected into a MongoDB pipeline"
  - "runMongoPipeline overrides ckStore from cfg.ClusterDSN (not cfg.Source which is MongoDB URI) — pitfall in plan explicitly avoided"
  - "Both connector and connector2 (post-snapshot restart) use the same overridden ckStore — cluster resume token durability maintained across re-snapshots"

patterns-established:
  - "Cluster wiring pattern: declare optional cluster component as var before conditional block, assign inside, guard all uses with nil check"

requirements-completed:
  - SRCC-01
  - SRCC-02
  - SRCC-03

# Metrics
duration: 3min
completed: 2026-04-30
---

# Phase 17 Plan 03: root.go Cluster Wiring — WalLeaderElector + MongoDB PostgresStore Summary

**Final Phase 17 wiring: WalLeaderElector injected into Postgres cluster errgroup with epoch fencing via SetEpochGetter, and MongoDB ckStore overridden to PostgresStore(ClusterDSN) for durable resume token sharing (SRCC-01, SRCC-02, SRCC-03)**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-04-30T17:00:48Z
- **Completed:** 2026-04-30T17:03:00Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Declared `var walElector *cluster.WalLeaderElector` before the event log block so it is in scope for all three insertion points (A, B, C)
- Constructed `WalLeaderElector` inside the NATS cluster block via `natsEl.Conn()` and `nodeID` (SRCC-02)
- Injected epoch fencing via `connector.SetEpochGetter(walElector.EpochGetter)` after connector construction (SRCC-01)
- Added `walElector.Run(gctx)` to errgroup alongside `heartbeater.Run` and `pm.Run`, guarded by `if walElector != nil`
- Overrode `ckStore` in `runMongoPipeline` with `PostgresStore(cfg.ClusterDSN)` in cluster mode — both connector and connector2 use shared store (SRCC-03)
- All 22 packages build cleanly; all tests pass; `make verify-no-cgo` confirms no CGO leakage

## Task Commits

Each task was committed atomically:

1. **Task 1: Wire WalLeaderElector into Postgres cluster pipeline** - `70aa3f6` (feat)
2. **Task 2: Switch MongoDB ckStore to PostgresStore in cluster mode** - `9eee6b2` (feat)

## Files Created/Modified

- `internal/cmd/root.go` — Three-point WalLeaderElector wiring (Insertions A/B/C) + runMongoPipeline ckStore override

## Decisions Made

- `walElector` declared before the `if cfg.Cluster {` event log block (not inside) — this is the only way to make it available for SetEpochGetter and errgroup.Go without restructuring the entire cluster block
- `walElector` stays `nil` for MongoDB source: the MongoDB dispatch happens before the Postgres connector block, so `SetEpochGetter` is never called and the `if walElector != nil` guard in the errgroup is always false for MongoDB pipelines
- `runMongoPipeline` uses `cfg.ClusterDSN` (not `cfg.Source`) for the Postgres store DSN — the plan explicitly called out this pitfall (cfg.Source is the MongoDB URI)
- `defer pgStore.Close()` inside the cluster block in `runMongoPipeline` — the store is closed when the pipeline function returns, matching the lifecycle of the MongoDB pipeline

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 17 is complete: SRCC-01 (epoch fencing), SRCC-02 (leader election goroutine), SRCC-03 (MongoDB shared resume tokens) all addressed
- v2.0 Distributed Architecture milestone is complete
- All `make test`, `make verify-no-cgo`, and `CGO_ENABLED=0 go build ./...` pass

## Self-Check

### Files exist

- `internal/cmd/root.go` — verified: contains `walElector`, `SetEpochGetter`, `NewWalLeaderElector`, `checkpoint.OpenPostgres(ctx, cfg.ClusterDSN)` in runMongoPipeline

### Commits exist

- `70aa3f6` — feat(17-03): wire WalLeaderElector into Postgres cluster pipeline
- `9eee6b2` — feat(17-03): switch MongoDB ckStore to PostgresStore in cluster mode (SRCC-03)

## Self-Check: PASSED

---
*Phase: 17-distributed-source-coordination*
*Completed: 2026-04-30*
