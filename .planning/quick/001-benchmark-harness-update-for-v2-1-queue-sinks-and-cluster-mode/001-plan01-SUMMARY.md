---
phase: quick-001
plan: 01
subsystem: bench-harness
tags: [bench, kafka, kaptanto, redpanda, franz-go]
dependency_graph:
  requires: [redpanda service in docker-compose.yml, franz-go indirect dep in bench/go.mod]
  provides: [RunKaptantoKafka adapter, kaptanto-kafka compose service, bench/config/kaptanto-kafka.yaml]
  affects: [bench/cmd/collector/main.go, bench/docker-compose.yml]
tech_stack:
  added: []
  patterns: [franz-go kgo.ConsumerGroup poll loop, peerdb.go clone with distinct group and tool tag]
key_files:
  created:
    - bench/internal/collector/adapters/kaptanto_kafka.go
    - bench/config/kaptanto-kafka.yaml
  modified:
    - bench/cmd/collector/main.go
    - bench/docker-compose.yml
decisions:
  - "Consumer group bench-collector-kaptanto-kafka — distinct from bench-collector (PeerDB) to prevent shared offset state between two independent tools reading the same Redpanda topic"
  - "franz-go promoted from indirect to direct dep by importing kgo in kaptanto_kafka.go — no go get required per plan constraint"
  - "kaptanto-kafka service command uses --config only (no --source/--output flags); CLI flags would win per CLAUDE.md invariant, but config file contains all required settings so no redundancy needed"
metrics:
  duration: ~4 minutes
  completed: 2026-05-18
  tasks_completed: 2
  files_modified: 4
---

# Phase quick-001 Plan 01: Kaptanto Kafka Sink Adapter Summary

One-liner: franz-go Kafka consumer adapter for kaptanto's Kafka sink path, wired into bench collector with Redpanda-backed compose service on port 7657.

## What Was Built

Added the kaptanto-kafka measurement path to the benchmark harness. kaptanto writes CDC events to Redpanda via its Kafka sink; the new `RunKaptantoKafka` adapter in the bench collector reads those events from Redpanda using franz-go (the same library already used by `RunPeerDB`) and emits `EventRecord{Tool: "kaptanto-kafka"}` records into the metrics pipeline.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | kaptanto_kafka.go adapter | b5e5650 | bench/internal/collector/adapters/kaptanto_kafka.go |
| 2 | Wire into collector main + compose + config | b5e5650 | bench/cmd/collector/main.go, bench/docker-compose.yml, bench/config/kaptanto-kafka.yaml |

## Deviations from Plan

None — plan executed exactly as written.

## Verification

```
go build ./...               exit 0
RunKaptantoKafka in file     OK
kaptanto-kafka-brokers flag  OK
kaptanto-kafka: in compose   OK
bootstrap-servers in yaml    OK
kaptanto-kafka-data volume   OK
```

## Self-Check: PASSED

- bench/internal/collector/adapters/kaptanto_kafka.go: FOUND
- bench/config/kaptanto-kafka.yaml: FOUND
- Commit b5e5650: FOUND
