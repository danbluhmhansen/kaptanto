---
phase: 28-sqs-per-table-routing
plan: 01
subsystem: sinks
tags: [sqs, aws, fifo, template, routing, cdc, go-templates]

# Dependency graph
requires:
  - phase: 26-sqs-tls-mtls
    provides: SQSSinkConsumer with TLS/mTLS, newConsumerWithClient internal constructor
  - phase: 25-pubsub-per-table-topic-routing
    provides: resolveTopicID + getOrCreatePublisher patterns (direct analog for SQS implementation)
provides:
  - QueueURLTemplate field on SQSSinkConfig (yaml:"queue-url-template")
  - resolveQueueURL method on SQSSinkConsumer — template-based per-event URL resolution
  - getOrValidateQueue method — lazy double-checked FIFO validation pool (sync.RWMutex)
  - Updated Deliver() uses resolved targetURL for SendMessage, not hardcoded c.queueURL
  - Updated newConsumerWithClient accepts 4th queueURLT *template.Template param
  - Template parse errors caught at construction in NewSQSSinkConsumer
affects:
  - 28-02-PLAN.md — routing tests build on these new methods

# Tech tracking
tech-stack:
  added: [bytes, strings, sync, text/template (stdlib only)]
  patterns:
    - double-checked locking with sync.RWMutex for lazy per-URL validation pool
    - template nil-guard for backward-compat default path (mirrors Phase 25 PubSub pattern)
    - fail-fast template parse in constructor before any AWS I/O

key-files:
  created: []
  modified:
    - internal/config/config.go
    - internal/output/sqs/consumer.go
    - internal/output/sqs/consumer_test.go

key-decisions:
  - "QueueURLTemplate nil-check in resolveQueueURL ensures zero-regression for existing single-queue deployments — identical behavior to Phase 20"
  - "validatedQueues seeded with default queueURL at construction so the no-template fast path never calls GetQueueAttributes at Deliver time"
  - "Template parsed before AWS config loading in NewSQSSinkConsumer — fail fast on bad template, avoid wasted AWS SDK init"
  - "getOrValidateQueue uses same double-checked locking pattern as Phase 25 getOrCreatePublisher — proven, consistent across sinks"
  - "Ping() continues to use c.queueURL (default queue) — no GetQueueAttributes added to Ping"

patterns-established:
  - "Per-table routing via Go template: resolveXxx + getOrValidateXxx double-checked pool pattern, now applied to SQS (matching Phase 25 PubSub)"
  - "Constructor parses template first, fails fast before any network I/O"

requirements-completed: [CFG-02]

# Metrics
duration: 3min
completed: 2026-05-09
---

# Phase 28 Plan 01: SQS Per-Table Routing Summary

**SQS per-table FIFO queue routing via Go template with lazy double-checked validation pool, closing CFG-02 for the SQS sink**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-05-09T16:46:48Z
- **Completed:** 2026-05-09T16:49:12Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added `QueueURLTemplate string` field to `SQSSinkConfig` with `yaml:"queue-url-template"` tag and doc comment
- Implemented `resolveQueueURL` and `getOrValidateQueue` on `SQSSinkConsumer` mirroring the Phase 25 PubSub pattern exactly
- Updated `Deliver()` to route each event to the template-resolved queue URL rather than always using `c.queueURL`
- All 16 existing SQS tests pass with zero regressions; `CGO_ENABLED=0 go build ./...` clean

## Task Commits

Each task was committed atomically:

1. **Task 1: Add QueueURLTemplate to SQSSinkConfig** - `99c4fc7` (feat)
2. **Task 2: Add template routing + validated queue pool to SQSSinkConsumer** - `2f3415c` (feat)

## Files Created/Modified

- `/Users/lucasandrade/kaptanto/internal/config/config.go` - Added `QueueURLTemplate` field and updated doc comment on `SQSSinkConfig`
- `/Users/lucasandrade/kaptanto/internal/output/sqs/consumer.go` - Added `queueURLT`, `validatedQueues`, `mu` fields; `resolveQueueURL`, `getOrValidateQueue` methods; updated `Deliver` and `newConsumerWithClient`; updated `Close` doc comment
- `/Users/lucasandrade/kaptanto/internal/output/sqs/consumer_test.go` - Updated `newTestConsumer` to seed `validatedQueues`; added `nil` 4th arg to two `newConsumerWithClient` calls

## Decisions Made

- `validatedQueues` is seeded with the default `queueURL` at construction time so the no-template path never hits `GetQueueAttributes` during `Deliver` — zero overhead for existing deployments
- Template parsing happens before any AWS SDK I/O in `NewSQSSinkConsumer` — invalid templates fail fast without wasting 10-second AWS config timeout
- `Ping()` deliberately continues to use `c.queueURL` (the default queue) — no change to health check behavior

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `resolveQueueURL` and `getOrValidateQueue` are in place; Plan 02 adds routing tests covering template path, empty-string guard, non-FIFO detection on dynamic URLs, and concurrent safety
- `newConsumerWithClient` signature updated; Plan 02 test helpers will pass `nil` or a parsed template as the 4th arg

---
*Phase: 28-sqs-per-table-routing*
*Completed: 2026-05-09*
