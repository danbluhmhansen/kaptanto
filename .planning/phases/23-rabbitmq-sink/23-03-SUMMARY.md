---
phase: 23-rabbitmq-sink
plan: "03"
subsystem: cli
tags: [rabbitmq, amqp, sink, cobra, cli, wiring]

# Dependency graph
requires:
  - phase: 23-rabbitmq-sink
    provides: RabbitMQSinkConfig (Plan 01) and RabbitMQSinkConsumer with 64-channel pool (Plan 02)
  - phase: 22-google-pubsub-sink
    provides: pubsub case pattern used as template for rabbitmq case
provides:
  - "case \"rabbitmq\": wiring block in root.go: nil-guard, NewRabbitMQSinkConsumer, defer Close(), SetMetrics, Register, HealthProbe, obs HTTP server"
  - "Updated default: error string including rabbitmq in valid modes list"
  - "TestOutputMode_RabbitMQ_MissingConfig and TestOutputMode_RabbitMQ_InvalidMode in root_test.go"
  - "SNK-02 satisfied — Phase 23 complete"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "rabbitmqsink import alias mirrors natssink/sqssink/kafkasink/pubsubsink convention — consistent naming for all sink packages"
    - "defer rabbitmqSink.Close() required — RabbitMQ maintains persistent TCP connections, unlike stateless HTTP SQS"
    - "RabbitMQ obs server uses cfg.Port (not cfg.Port+1) — publishes to external broker; no TCP server beyond observability"

key-files:
  created: []
  modified:
    - internal/cmd/root.go
    - internal/cmd/root_test.go

key-decisions:
  - "rabbitmqsink import alias mirrors natssink/sqssink/kafkasink/pubsubsink convention — consistent naming pattern for all sink packages"
  - "defer rabbitmqSink.Close() required — RabbitMQ maintains persistent TCP connections, unlike stateless HTTP SQS sink"
  - "RabbitMQ obs server uses cfg.Port (not cfg.Port+1) — RabbitMQ publishes to external broker; no TCP server binds cfg.Port in rabbitmq mode"

patterns-established:
  - "Queue sink case pattern complete: nil-check cfg.Sinks.X, construct consumer, defer Close(), SetMetrics, rtr.Register, append HealthProbe, serve /metrics + /healthz on cfg.Port"

requirements-completed:
  - SNK-02

# Metrics
duration: 2min
completed: "2026-05-07"
---

# Phase 23 Plan 03: RabbitMQ Sink CLI Wiring Summary

**`case "rabbitmq":` wired into root.go with nil-guard, consumer init, defer Close(), metrics, router registration, health probe, and obs server; two cmd tests confirm nil-config and invalid-mode errors**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-07T22:57:26Z
- **Completed:** 2026-05-07T23:00:07Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Added `rabbitmqsink` import alias to root.go alongside natssink/sqssink/kafkasink/pubsubsink
- Inserted `case "rabbitmq":` block with full pipeline wiring: nil-guard on cfg.Sinks.RabbitMQ, NewRabbitMQSinkConsumer, defer Close(), SetMetrics, rtr.Register, HealthProbe{Name: "rabbitmq"}, obs HTTP server on cfg.Port
- Updated default: error string from "...pubsub" to "...pubsub, rabbitmq"
- Added TestOutputMode_RabbitMQ_MissingConfig (error contains "sinks.rabbitmq") and TestOutputMode_RabbitMQ_InvalidMode (error contains "rabbitmq")
- `make test CGO_ENABLED=0`, `make build CGO_ENABLED=0`, and `make verify-no-cgo` all green

## Task Commits

Each task was committed atomically:

1. **Task 1: Add case "rabbitmq": to root.go** - `394341b` (feat)
2. **Task 2: Add RabbitMQ cmd tests to root_test.go** - `5904464` (test)

**Plan metadata:** (docs commit — see below)

## Files Created/Modified
- `internal/cmd/root.go` - rabbitmqsink import alias, case "rabbitmq": wiring block, updated default error string
- `internal/cmd/root_test.go` - TestOutputMode_RabbitMQ_MissingConfig and TestOutputMode_RabbitMQ_InvalidMode

## Decisions Made
- rabbitmqsink import alias mirrors natssink/sqssink/kafkasink/pubsubsink convention — consistent naming pattern for all sink packages
- defer rabbitmqSink.Close() required — RabbitMQ maintains persistent TCP connections (AMQP channel pool), unlike stateless HTTP SQS sink
- RabbitMQ obs server uses cfg.Port (not cfg.Port+1) — RabbitMQ publishes to external broker; no TCP server binds cfg.Port in rabbitmq mode

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Phase 23 complete — SNK-02 satisfied
- RabbitMQ is now a fully wired output mode: `--output rabbitmq` with `sinks.rabbitmq:` YAML block activates the 64-channel AMQP pool with publisher confirms, reconnect loop, and graceful Close()
- All five queue sinks (NATS, SQS, Kafka, Pub/Sub, RabbitMQ) are production-ready

---
*Phase: 23-rabbitmq-sink*
*Completed: 2026-05-07*
