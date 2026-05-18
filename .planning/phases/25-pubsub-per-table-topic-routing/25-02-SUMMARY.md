---
phase: 25-pubsub-per-table-topic-routing
plan: 02
subsystem: testing
tags: [pubsub, google-cloud, publisher-pool, topic-routing, pstest, cgo-free, tdd]

# Dependency graph
requires:
  - phase: 25-pubsub-per-table-topic-routing
    provides: PubSubSinkConsumer with lazy publisher pool (resolveTopicID + getOrCreatePublisher) from plan 25-01
provides:
  - Full test suite for PubSubSinkConsumer publisher pool behaviour (5 new tests)
  - Per-table routing verified via pstest srv.Messages().Topic
  - Pool reuse, Close-drains-all, empty-template guard, and no-template regression verified
affects: [CFG-02, pubsub sink integration tests]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "pstest fake-server pattern: create topics before publishing, use strings.Contains for topic matching"
    - "TDD green-only pattern: implementation pre-exists from plan 25-01; tests verify correct behaviour"

key-files:
  created: []
  modified:
    - internal/output/pubsub/consumer_test.go

key-decisions:
  - "strings.Contains(m.Topic, topicID) used for topic matching — pstest fully-qualifies topics as projects/{id}/topics/{name}"
  - "Both topics created on fake server before consumer construction — pstest does not auto-create topics"
  - "conn.Close() after c.Close() in CloseDrainsAllPublishers test — consumer drains publishers first, then gRPC conn is safe to close"
  - "{{if false}}something{{end}} template used for empty-string guard test — Go templates do not error on missing fields by default"

patterns-established:
  - "pstest topic assertion pattern: srv.Messages() + strings.Contains for robust topic matching regardless of fully-qualified format"

requirements-completed: [CFG-02]

# Metrics
duration: 2min
completed: 2026-05-08
---

# Phase 25 Plan 02: PubSub Publisher Pool Tests Summary

**5 new pstest-based tests verify per-table topic routing, lazy pool reuse, Close drain-all, empty template guard, and no-template regression for the Phase 25-01 publisher pool refactor (CFG-02)**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-08T09:47:59Z
- **Completed:** 2026-05-08T09:49:39Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- Added 5 new test functions to `internal/output/pubsub/consumer_test.go` alongside 6 existing Phase 22 tests (11 total, all passing)
- Verified per-table routing: two events for different tables land on two different Pub/Sub topics via `srv.Messages().Topic`
- Verified pool reuse: two delivers to the same resolved topic produce 2 messages, no crash or duplication
- Verified Close drains all publishers: no panic when publisher pool contains 2 pooled publishers
- Verified empty-string template guard: `{{if false}}something{{end}}` returns non-nil error containing "empty string"
- Verified no-template regression: empty TopicTemplate publishes to `cfg.TopicID` exactly as Phase 22
- Full build (`CGO_ENABLED=0 go build ./...`) and full test suite (`CGO_ENABLED=0 go test ./...`) both pass

## Task Commits

Each task was committed atomically:

1. **Task 1: Add new test functions for publisher pool behaviour** - `ca92809` (test)
2. **Task 2: Full build and test verification** - no commit (verification-only task, no files changed)

**Plan metadata:** (docs commit — see below)

## Files Created/Modified
- `internal/output/pubsub/consumer_test.go` - Added `"strings"` import + 5 new test functions: PerTableRouting, PoolReusesSamePublisher, CloseDrainsAllPublishers, Deliver_EmptyTemplateResult, Deliver_NoTemplate_Regression

## Decisions Made
- `strings.Contains(m.Topic, topicID)` used for topic matching rather than exact equality — pstest fully-qualifies topic names as `projects/{id}/topics/{name}`, so contains is the correct comparison
- Both routing topics created on the fake server before constructing the consumer — pstest does not auto-create topics; missing this causes publish failures
- `conn.Close()` is called after `c.Close()` in `CloseDrainsAllPublishers` — publisher Stop() drains in-flight messages; closing the gRPC conn before Stop() would cut them off
- `{{if false}}something{{end}}` chosen for the empty-string guard test — Go templates do not return errors for missing fields by default, so this is the canonical way to produce an empty rendered string

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- CFG-02 is fully satisfied: implementation (25-01) and tests (25-02) are both complete
- Phase 25 is complete — all plans done
- No blockers for subsequent phases

---
*Phase: 25-pubsub-per-table-topic-routing*
*Completed: 2026-05-08*

## Self-Check: PASSED

- FOUND: internal/output/pubsub/consumer_test.go
- FOUND: .planning/phases/25-pubsub-per-table-topic-routing/25-02-SUMMARY.md
- FOUND: ca92809 (task 1 commit)
- FOUND: daf8ca9 (metadata commit)
