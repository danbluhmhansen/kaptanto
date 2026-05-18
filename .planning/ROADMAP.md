# Roadmap: Kaptanto

## Milestones

- ✅ **v1.0 Postgres CDC Binary** — Phases 1–7.7 (shipped 2026-03-16)
- ✅ **v1.1 Production Hardening** — Phases 8–10 (shipped 2026-03-20)
- ✅ **v1.2 Benchmark Suite** — Phases 11–13 (shipped 2026-03-21)
- ✅ **v2.0 Distributed Architecture** — Phases 14–18 (shipped 2026-05-03)
- ✅ **v2.1 Queue Sinks** — Phases 19–28 (shipped 2026-05-09)
- 📋 **v2.2** — Phases 29+ (planned)

## Phases

<details>
<summary>✅ v1.0 Postgres CDC Binary (Phases 1–7.7) — SHIPPED 2026-03-16</summary>

- [x] **Phase 1: Foundation** — Shared event types, CLI skeleton, structured logging, pure Go build setup (completed 2026-03-07)
- [x] **Phase 2: Postgres Source and Parser** — WAL consumption, pgoutput decoding, TOAST cache, schema evolution, checkpoint store (completed 2026-03-08)
- [x] **Phase 3: Event Log** — Badger-based durable append-only store with partitioning, dedup, and TTL (completed 2026-03-08)
- [x] **Phase 4: Backfill Engine** — Snapshot coordination with watermark dedup, keyset cursors, crash recovery (completed 2026-03-08)
- [x] **Phase 5: Router and stdout Output** — Partitioned routing with per-key ordering, consumer isolation, poison pill handling, NDJSON output (completed 2026-03-08)
- [x] **Phase 6: SSE and gRPC Servers** — Full output server suite with consumer cursors, filtering, metrics, and health endpoint (completed 2026-03-12)
- [x] **Phase 7: Configuration and Multi-Source** — YAML config parsing, column filtering, SQL WHERE conditions (completed 2026-03-15)
- [x] **Phase 7.1: Infrastructure Fixes** [INSERTED] — LogEntry.PartitionID fix (CHK-02), Phase 6 formal verification (completed 2026-03-15)
- [x] **Phase 7.2: Pipeline Assembly** [INSERTED] — Wire all components into runPipeline; thread config filters to consumers (completed 2026-03-15)
- [x] **Phase 7.3: Milestone Gap Closure** [INSERTED] — Fix AppendAndQueue blocking channel (INT-01) and OldTuple decode for before field (INT-02) (completed 2026-03-15)
- [x] **Phase 7.4: Backfill Pipeline Wiring** [INSERTED] — Wire BackfillEngine into runPipeline, full snapshot/backfill flows live (completed 2026-03-16)
- [x] **Phase 7.5: Observability Hardening** [INSERTED] — Wire Prometheus metrics, add healthz probes, bound SSE shutdown (completed 2026-03-16)
- [x] **Phase 7.6: Backfill Correctness** [INSERTED] — Fix watermark SnapshotLSN init (BKF-02), concurrent Run race (SRC-06), SQLite pragma (BKF-03) (completed 2026-03-16)
- [x] **Phase 7.7: Stdout Metrics** [INSERTED] — Wire EventsDelivered metric into StdoutWriter (OBS-01) (completed 2026-03-16)

Full archive: `.planning/milestones/v1.0-ROADMAP.md`

</details>

<details>
<summary>✅ v1.1 Production Hardening (Phases 8–10) — SHIPPED 2026-03-20</summary>

- [x] **Phase 8: High Availability** — Postgres advisory lock leader election with shared checkpoint store and automatic standby takeover (completed 2026-03-17)
- [x] **Phase 9: MongoDB Connector** — Change Streams consumption, BSON normalization, resume token persistence, and re-snapshot on token expiry (completed 2026-03-17)
- [x] **Phase 9.1: MongoDB HA Guard** [INSERTED] — Guard against passing MongoDB URI to Postgres HA election; INT-03 gap closure (completed 2026-03-17)
- [x] **Phase 10: Rust FFI Acceleration** — Optional Rust-accelerated pgoutput decoding, TOAST cache, and JSON serialization behind build tag (completed 2026-03-17)

Full archive: `.planning/milestones/v1.1-ROADMAP.md`

</details>

<details>
<summary>✅ v1.2 Benchmark Suite (Phases 11–13) — SHIPPED 2026-03-21</summary>

- [x] **Phase 11: Harness and Load Generator** — Docker Compose with all CDC tools against shared Postgres, plus loadgen binary with scenario modes (completed 2026-03-21)
- [x] **Phase 12: Metrics Collector and Scenarios** — Per-tool adapters writing to JSONL, all 5 benchmark scenarios executed (completed 2026-03-21)
- [x] **Phase 13: Report Generator** — Self-contained HTML report with charts and Markdown summary from JSONL data (completed 2026-03-21)

Full archive: `.planning/milestones/v1.2-ROADMAP.md`

</details>

<details>
<summary>✅ v2.0 Distributed Architecture (Phases 14–18) — SHIPPED 2026-05-03</summary>

- [x] **Phase 14: Shared State Foundation** — Shared Postgres cursor + backfill stores behind --cluster; cluster membership table with heartbeat-based node liveness (completed 2026-04-27)
- [x] **Phase 15: Distributed Event Log** — NATS JetStream embedded event log replacing node-local Badger; CHK-01 cluster-wide; pure Go binary preserved (completed 2026-04-28)
- [x] **Phase 16: Partition Ownership and Active/Active Delivery** — 64-partition ownership with atomic claim/steal/release; epoch fencing for zombie nodes; N-node active SSE/gRPC delivery (completed 2026-04-30)
- [x] **Phase 17: Distributed Source Coordination** — NATS KV WAL leader election with epoch fencing; MongoDB resume tokens in shared PostgresStore (completed 2026-04-30)
- [x] **Phase 18: MongoDB Cluster Infrastructure Wiring** [GAP-CLOSURE] — heartbeater.Run + pm.Run wired into runMongoPipeline errgroups; dead staleThreshold field and partition_assignments column removed (completed 2026-05-02)

Full archive: `.planning/milestones/v2.0-ROADMAP.md`

</details>

<details>
<summary>✅ v2.1 Queue Sinks (Phases 19–28) — SHIPPED 2026-05-09</summary>

- [x] **Phase 19: Sink Infrastructure and NATS Sink** — `sinks:` YAML config block, CLI flags, per-sink metrics and /healthz hooks, NATSSinkConsumer with JetStream at-least-once delivery (completed 2026-05-03)
- [x] **Phase 20: SQS Sink** — SQSConsumer with FIFO queue validation, MessageGroupId from primary key, IdempotencyKey as dedup attribute (completed 2026-05-04)
- [x] **Phase 21: Kafka Sink** — KafkaConsumer using franz-go (CGO-free mandatory), record key from primary key, SASL/TLS auth (completed 2026-05-05)
- [x] **Phase 22: Google Pub/Sub Sink** — PubSubConsumer with ordering key, synchronous result.Get confirmation, ResumePublish on ordering-key errors (completed 2026-05-06)
- [x] **Phase 23: RabbitMQ Sink** — RabbitMQConsumer with per-partition channel pool, publisher confirms, and explicit reconnect loop (completed 2026-05-06)
- [x] **Phase 24: Sink Config Surface Cleanup** [GAP-CLOSURE] — Fix stale `--output` flag help text; wire SQSSinkConfig.TLS into AWS SDK custom HTTP transport for CA pinning (completed 2026-05-07)
- [x] **Phase 25: PubSub Per-Table Topic Routing** [GAP-CLOSURE] — Implement publisher pool so `TopicTemplate` routes Deliver() to the correct per-topic publisher (completed 2026-05-08)
- [x] **Phase 26: SQS mTLS Wiring** [TECH-DEBT] — Wire CertFile/KeyFile into AWS SDK custom HTTP transport; startup validation for incomplete mTLS config (completed 2026-05-09)
- [x] **Phase 27: PubSub Config Tests and NATS Comment Fix** [TECH-DEBT] — 3 YAML round-trip tests for PubSubSinkConfig; fix misleading DLV-02 comment in NATS consumer (completed 2026-05-09)
- [x] **Phase 28: SQS Per-Table Routing** [TECH-DEBT] — QueueURLTemplate + validated queue URL pool for per-table SQS FIFO routing (completed 2026-05-09)

Full archive: `.planning/milestones/v2.1-ROADMAP.md`

</details>

### 📋 v2.2 (Planned)

*Requirements to be defined — run `/gsd:new-milestone` to start.*

## Progress

| Phase | Milestone | Plans | Status | Completed |
|-------|-----------|-------|--------|-----------|
| 1. Foundation | v1.0 | 2/2 | ✓ Complete | 2026-03-07 |
| 2. Postgres Source and Parser | v1.0 | 3/3 | ✓ Complete | 2026-03-08 |
| 3. Event Log | v1.0 | 2/2 | ✓ Complete | 2026-03-08 |
| 4. Backfill Engine | v1.0 | 2/2 | ✓ Complete | 2026-03-08 |
| 5. Router and stdout Output | v1.0 | 3/3 | ✓ Complete | 2026-03-08 |
| 6. SSE and gRPC Servers | v1.0 | 4/4 | ✓ Complete | 2026-03-12 |
| 7. Configuration and Multi-Source | v1.0 | 4/4 | ✓ Complete | 2026-03-15 |
| 7.1–7.7. Gap Closure [INSERTED] | v1.0 | 8/8 | ✓ Complete | 2026-03-16 |
| 8. High Availability | v1.1 | 3/3 | ✓ Complete | 2026-03-17 |
| 9. MongoDB Connector | v1.1 | 3/3 | ✓ Complete | 2026-03-17 |
| 9.1. MongoDB HA Guard [INSERTED] | v1.1 | 1/1 | ✓ Complete | 2026-03-17 |
| 10. Rust FFI Acceleration | v1.1 | 3/3 | ✓ Complete | 2026-03-17 |
| 11. Harness and Load Generator | v1.2 | 3/3 | ✓ Complete | 2026-03-21 |
| 12. Metrics Collector and Scenarios | v1.2 | 3/3 | ✓ Complete | 2026-03-21 |
| 13. Report Generator | v1.2 | 2/2 | ✓ Complete | 2026-03-21 |
| 14. Shared State Foundation | v2.0 | 3/3 | ✓ Complete | 2026-04-28 |
| 15. Distributed Event Log | v2.0 | 2/2 | ✓ Complete | 2026-04-28 |
| 16. Partition Ownership and Active/Active Delivery | v2.0 | 3/3 | ✓ Complete | 2026-04-30 |
| 17. Distributed Source Coordination | v2.0 | 3/3 | ✓ Complete | 2026-05-01 |
| 18. MongoDB Cluster Infrastructure Wiring [GAP] | v2.0 | 2/2 | ✓ Complete | 2026-05-02 |
| 19. Sink Infrastructure and NATS Sink | v2.1 | 3/3 | ✓ Complete | 2026-05-04 |
| 20. SQS Sink | v2.1 | 3/3 | ✓ Complete | 2026-05-04 |
| 21. Kafka Sink | v2.1 | 3/3 | ✓ Complete | 2026-05-05 |
| 22. Google Pub/Sub Sink | v2.1 | 3/3 | ✓ Complete | 2026-05-06 |
| 23. RabbitMQ Sink | v2.1 | 3/3 | ✓ Complete | 2026-05-06 |
| 24. Sink Config Surface Cleanup [GAP] | v2.1 | 2/2 | ✓ Complete | 2026-05-07 |
| 25. PubSub Per-Table Topic Routing [GAP] | v2.1 | 2/2 | ✓ Complete | 2026-05-08 |
| 26. SQS mTLS Wiring [TECH-DEBT] | v2.1 | 1/1 | ✓ Complete | 2026-05-09 |
| 27. PubSub Config Tests + NATS Comment Fix [TECH-DEBT] | v2.1 | 1/1 | ✓ Complete | 2026-05-09 |
| 28. SQS Per-Table Routing [TECH-DEBT] | v2.1 | 2/2 | ✓ Complete | 2026-05-09 |
