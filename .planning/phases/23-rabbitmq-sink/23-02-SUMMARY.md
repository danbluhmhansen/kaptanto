---
phase: 23-rabbitmq-sink
plan: 02
subsystem: output/rabbitmq
tags: [rabbitmq, amqp091-go, publisher-confirms, tdd, reconnect, interface-injection]

# Dependency graph
requires:
  - phase: 23-01
    provides: RabbitMQSinkConfig struct, amqp091-go v1.11.0 (indirect)
provides:
  - RabbitMQSinkConsumer implementing router.Consumer
  - AMQPChannelAPI interface (exported for test injection)
  - DeferredConfirmAPI interface (exported for test injection)
  - NewRabbitMQSinkConsumer (production constructor — dials + reconnect goroutine)
  - NewConsumerWithChannels (test constructor — no dial, no reconnect)
  - amqp091-go promoted from indirect to direct dependency
affects: [23-03-PLAN.md]

# Tech tracking
tech-stack:
  added: [github.com/rabbitmq/amqp091-go v1.11.0 (now direct)]
  patterns:
    - "AMQPChannelAPI + DeferredConfirmAPI interface injection pattern (mirrors sqsAPI from sqssink)"
    - "64-channel pool matching EventLog partition count (RTR-04)"
    - "realChannel + realDeferredConfirm thin wrappers adapting concrete AMQP types to interfaces"
    - "NewConsumerWithChannels internal test constructor (mirrors newConsumerWithClient from sqssink)"
    - "reconnectLoop: background goroutine, exponential backoff 1s→30s+50% jitter"
    - "buildTLSConfig: CA pool + mTLS cert (identical structure to kafkasink.buildTLSConfig)"

key-files:
  created:
    - internal/output/rabbitmq/consumer.go
    - internal/output/rabbitmq/consumer_test.go
  modified:
    - go.mod
    - go.sum

key-decisions:
  - "AMQPChannelAPI + DeferredConfirmAPI exported — test package (rabbitmqsink_test) implements fakeAMQPChannel; exported types keep the interface in one place while allowing external test packages to depend on them"
  - "64-channel pool uses entry.PartitionID % 64 — AMQP channels are not goroutine-safe; one channel per partition slot is the correct serialization boundary"
  - "WaitContext called after publish (not PublishWithContext) — CHK-01 requires blocking until broker ack before returning nil to the router"
  - "Latency observed after WaitContext returns — includes full broker round-trip, giving accurate end-to-end latency signal"
  - "Reconnect loop stops on notifyClose ok=false — that is the graceful Close() signal; avoids spurious reconnect after intentional shutdown"
  - "go mod tidy run in Plan 02 — amqp091-go promoted from indirect (Plan 01) to direct (Plan 02) by first import"

# Metrics
duration: 4min
completed: 2026-05-07
---

# Phase 23 Plan 02: RabbitMQ Sink — RabbitMQSinkConsumer Summary

**RabbitMQSinkConsumer with 64-channel pool, publisher confirms (WaitContext), reconnect loop with exponential backoff, and full unit test coverage using AMQPChannelAPI + DeferredConfirmAPI interface injection**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-05-06T22:51:29Z
- **Completed:** 2026-05-07
- **Tasks:** 2 (TDD RED + GREEN)
- **Files created:** 2
- **Files modified:** 2 (go.mod, go.sum)

## Accomplishments

- Defined `AMQPChannelAPI` and `DeferredConfirmAPI` interfaces (exported for external test packages)
- Implemented `realChannel` and `realDeferredConfirm` thin wrappers adapting concrete amqp091-go types
- `RabbitMQSinkConsumer` struct with 64-slot channel array (protected by `sync.RWMutex`)
- `Deliver`: per-partition channel selection, routing key template execution, JSON marshal,
  `DeliveryMode=amqp.Persistent`, `Kaptanto-Idempotency-Key` header, `WaitContext` confirm (CHK-01)
- `Ping`: returns error when `conn` is nil or `conn.IsClosed()` returns true
- `Close`: cancels reconnect goroutine, closes all 64 channels, closes connection
- `reconnectLoop`: background goroutine watching `NotifyClose`, re-dials with 1s→30s exponential backoff + 50% jitter
- `NewConsumerWithChannels` internal constructor for unit test injection (no dial, no reconnect goroutine)
- `buildTLSConfig`: CA pool + mTLS client cert (identical structure to kafkasink)
- Compile-time assertion: `var _ router.Consumer = (*RabbitMQSinkConsumer)(nil)`
- All 10 `TestRabbitMQSink_*` tests pass
- `go mod tidy`: amqp091-go v1.11.0 promoted from indirect to direct dependency
- `make verify-no-cgo`: passes for linux/amd64 and darwin/arm64
- Full `go test ./...` suite: all packages pass

## Task Commits

Each task was committed atomically:

1. **TDD RED — failing RabbitMQSinkConsumer tests** - `f9e5cdb` (test)
2. **GREEN — consumer.go implementation + go mod tidy** - `88c54e1` (feat)

_Note: TDD tasks have two commits (test → feat)_

**Plan metadata:** committed as part of final docs commit

## Files Created/Modified

- `internal/output/rabbitmq/consumer.go` - Full RabbitMQSinkConsumer implementation
- `internal/output/rabbitmq/consumer_test.go` - 10 unit tests using interface injection
- `go.mod` - amqp091-go v1.11.0 promoted from indirect to direct
- `go.sum` - Updated checksums

## Decisions Made

- AMQPChannelAPI + DeferredConfirmAPI exported — test package implements fakes; exported types keep interface in one place
- 64-channel pool maps entry.PartitionID % 64 — AMQP channels are not goroutine-safe; one channel per partition is the correct serialization boundary
- WaitContext blocks after publish — CHK-01 requires broker ack before returning nil to router
- Latency observed after WaitContext — includes full broker round-trip for accurate end-to-end latency
- Reconnect loop stops on notifyClose ok=false — graceful Close() signal, avoids spurious reconnect
- go mod tidy run in Plan 02 — mirrors Phase 21/22 pattern (indirect in Plan 01, direct in Plan 02)

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED

---
*Phase: 23-rabbitmq-sink*
*Completed: 2026-05-07*
