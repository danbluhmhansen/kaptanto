---
phase: 27-pubsub-config-tests-and-nats-comment-fix
plan: "01"
subsystem: config-tests, nats-sink
tags: [tech-debt, tests, comments, pubsub, nats]
requirements: [TECH-DEBT-27]

dependency_graph:
  requires: []
  provides:
    - PubSubSinkConfig YAML round-trip test coverage (3 tests)
    - Accurate DLV-02 comment in NATS consumer package doc
  affects:
    - internal/config/sinks_test.go
    - internal/output/nats/consumer.go

tech_stack:
  added: []
  patterns:
    - 4-step YAML round-trip test pattern (raw YAML → yaml.Unmarshal → require.NoError → require.NotNil + assert.Equal)

key_files:
  created: []
  modified:
    - internal/config/sinks_test.go
    - internal/output/nats/consumer.go

decisions:
  - PubSub YAML key is "pubsub" (not "pub-sub") — consistent with existing SinksConfig yaml tag

metrics:
  duration: "~1 minute"
  completed: "2026-05-09"
  tasks_completed: 2
  files_modified: 2
---

# Phase 27 Plan 01: PubSub Config Tests and NATS Comment Fix Summary

**One-liner:** 3 PubSubSinkConfig YAML round-trip tests added to close the only sink test gap, plus DLV-02 comment corrected to attribute per-key ordering to RTR-04 router (not NATS JetStream).

## What Was Built

### Task 1 — 3 PubSubSinkConfig YAML round-trip tests (commit: 29011cc)

Added three test functions to `internal/config/sinks_test.go` following the exact 4-step pattern used by all other sink tests (NATS, SQS, Kafka, RabbitMQ):

- **TestSinks_PubSub_FullBlock** — all four fields (project-id, topic-id, topic-template, credentials-file) parsed correctly
- **TestSinks_PubSub_NoCredentialsFile** — ADC path verified: CredentialsFile is "" when omitted
- **TestSinks_PubSub_AbsentBlock** — cfg.Sinks.PubSub is nil when sinks.pubsub block absent from YAML

### Task 2 — DLV-02 comment fix in NATS consumer package doc (commit: 73fe99d)

Corrected the package-level doc comment in `internal/output/nats/consumer.go`. The old two-line bullet implied NATS JetStream enforces per-key delivery ordering. The corrected three-line bullet now explicitly states that per-key ordering is an RTR-04 router guarantee, not a NATS JetStream feature. Comment-only change, zero behavior impact.

## Verification

- `CGO_ENABLED=0 go test ./internal/config/... -run TestSinks_PubSub -v` — all 3 PASS
- `CGO_ENABLED=0 go test ./internal/config/...` — full suite PASS (all existing + 3 new)
- `grep -n "RTR-04 router guarantee" internal/output/nats/consumer.go` — found at line 13
- `CGO_ENABLED=0 go build ./...` — PASS, no compilation errors

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check

### Files exist

- internal/config/sinks_test.go — FOUND (modified)
- internal/output/nats/consumer.go — FOUND (modified)

### Commits exist

- 29011cc — test(27-01): add 3 PubSubSinkConfig YAML round-trip tests
- 73fe99d — fix(27-01): correct misleading DLV-02 comment in NATS consumer package doc

## Self-Check: PASSED
