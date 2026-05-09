---
phase: 28-sqs-per-table-routing
verified: 2026-05-09T17:10:00Z
status: passed
score: 7/7 must-haves verified
re_verification: false
---

# Phase 28: SQS Per-Table Routing Verification Report

**Phase Goal:** Implement `QueueURLTemplate` support for the SQS sink so CDC events from different tables route to different SQS FIFO queues — closing the CFG-02 structural gap for SQS (analogous to the Phase 25 PubSub publisher pool).
**Verified:** 2026-05-09T17:10:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| #  | Truth                                                                                             | Status     | Evidence                                                                                                      |
|----|---------------------------------------------------------------------------------------------------|------------|---------------------------------------------------------------------------------------------------------------|
| 1  | When QueueURLTemplate is set, Deliver() routes each event to the template-resolved queue URL      | VERIFIED   | `resolveQueueURL` called at top of `Deliver()`; `SendMessage` uses `targetURL` not `c.queueURL`; `TestSQSSinkConsumer_Routing_PerTable` passes |
| 2  | When QueueURLTemplate is empty/absent, Deliver() uses cfg.QueueURL unchanged — no regression      | VERIFIED   | `resolveQueueURL` returns `c.queueURL` when `c.queueURLT == nil`; `TestSQSSinkConsumer_Routing_Regression_NoTemplate` passes |
| 3  | Each unique resolved queue URL is FIFO-validated exactly once via GetQueueAttributes (lazy pool)  | VERIFIED   | `getOrValidateQueue` double-checked locking with `sync.RWMutex`; `TestSQSSinkConsumer_Routing_PoolCaching` asserts `getQueueAttributesCallCount == 1` after 3 delivers |
| 4  | Template parse errors are caught at construction, not at first Deliver                            | VERIFIED   | `NewSQSSinkConsumer` calls `template.New("queue-url").Parse(cfg.QueueURLTemplate)` before AWS I/O; `TestSQSSinkConsumer_Routing_TemplateParseError` confirms invalid templates fail to parse |
| 5  | Close() remains a no-op — no per-queue stateful objects need draining                            | VERIFIED   | `validatedQueues` holds `map[string]bool` (no connections); `Close()` is no-op with doc comment confirming no drain needed |
| 6  | YAML round-trip for QueueURLTemplate parses correctly from sinks.sqs block                       | VERIFIED   | 3 tests pass: `TestSinks_SQS_QueueURLTemplate_FullBlock`, `TestSinks_SQS_QueueURLTemplate_TemplateOnly`, `TestSinks_SQS_QueueURLTemplate_AbsentTemplate` |
| 7  | All pre-existing SQS consumer tests pass (no regressions)                                        | VERIFIED   | 16 pre-existing tests + 5 new tests all pass; `CGO_ENABLED=0 go test ./internal/output/sqs/...` exits 0 |

**Score:** 7/7 truths verified

### Required Artifacts

| Artifact                                     | Expected                                                    | Status     | Details                                                                                     |
|----------------------------------------------|-------------------------------------------------------------|------------|---------------------------------------------------------------------------------------------|
| `internal/config/config.go`                  | `QueueURLTemplate` field on `SQSSinkConfig`                 | VERIFIED   | Field at line 60 with `yaml:"queue-url-template"` tag and doc comment; substantive (not stub) |
| `internal/output/sqs/consumer.go`            | `resolveQueueURL`, `getOrValidateQueue`, updated `Deliver`  | VERIFIED   | Both methods present (lines 193, 212); `Deliver()` calls both at lines 260-265; `newConsumerWithClient` takes 4th `queueURLT` param |
| `internal/config/sinks_test.go`              | 3 YAML round-trip tests for `QueueURLTemplate`              | VERIFIED   | `TestSinks_SQS_QueueURLTemplate_FullBlock`, `_TemplateOnly`, `_AbsentTemplate` all present and green |
| `internal/output/sqs/consumer_test.go`       | 5 routing/pool/error/regression tests + helper updates      | VERIFIED   | `newTemplateConsumer` helper at line 94; `getQueueAttributesCallCount` field in `fakeSQSClient`; 5 `TestSQSSinkConsumer_Routing_*` tests all present and green |

### Key Link Verification

| From                                 | To                                       | Via                                            | Status     | Details                                                                                   |
|--------------------------------------|------------------------------------------|------------------------------------------------|------------|-------------------------------------------------------------------------------------------|
| `internal/config/config.go`          | `internal/output/sqs/consumer.go`        | `cfg.QueueURLTemplate` parsed into `queueURLT` | WIRED      | `NewSQSSinkConsumer` at line 84-90 parses `cfg.QueueURLTemplate`; passes `queueURLT` to `newConsumerWithClient` at line 152 |
| `SQSSinkConsumer.Deliver`            | `resolveQueueURL` + `getOrValidateQueue` | Called at top of `Deliver` before `SendMessage` | WIRED      | Lines 260-265 in `consumer.go`; `SendMessage` at line 287 uses `aws.String(targetURL)` |
| `internal/config/sinks_test.go`      | `config.SQSSinkConfig.QueueURLTemplate`  | `yaml.Unmarshal` round-trip                    | WIRED      | Tests assert `.QueueURLTemplate` field value after unmarshal |
| `internal/output/sqs/consumer_test.go` | `SQSSinkConsumer.Deliver`              | `fake.lastSendInput.QueueUrl` assertion        | WIRED      | `TestSQSSinkConsumer_Routing_PerTable` asserts `*fake.lastSendInput.QueueUrl` equals template-resolved URL |

### Requirements Coverage

| Requirement | Source Plan      | Description                                                                               | Status    | Evidence                                                                                                     |
|-------------|------------------|-------------------------------------------------------------------------------------------|-----------|--------------------------------------------------------------------------------------------------------------|
| CFG-02      | 28-01, 28-02     | User can configure per-table topic/queue/subject routing via a Go template                | SATISFIED | `QueueURLTemplate` field on `SQSSinkConfig`; `Deliver()` routes per-template per-message; 5 routing tests green; ROADMAP marks Phase 28 complete for SQS CFG-02 gap |

**Note on REQUIREMENTS.md traceability table:** The traceability table at line 73 of `REQUIREMENTS.md` shows CFG-02 mapped to "Phase 19 + Phase 25 (gap)" and does not yet list Phase 28. This is a documentation lag in `REQUIREMENTS.md` — the roadmap at line 84 of `ROADMAP.md` explicitly states Phase 28 "closes CFG-02 structural gap for SQS" and marks it complete. The implementation fully satisfies CFG-02 for SQS.

### Anti-Patterns Found

None detected in the four modified files (`internal/config/config.go`, `internal/output/sqs/consumer.go`, `internal/config/sinks_test.go`, `internal/output/sqs/consumer_test.go`). No TODO/FIXME/HACK/PLACEHOLDER comments. No stub implementations (empty returns, console-log-only handlers).

### Human Verification Required

None. All success criteria are mechanically verifiable:
- Field existence and YAML tag: confirmed by grep
- Method presence and wiring: confirmed by grep and code inspection
- Test results: confirmed by running `CGO_ENABLED=0 go test`
- Build cleanliness: confirmed by `CGO_ENABLED=0 go build ./...`

### Commit Verification

All four commits documented in SUMMARY files exist in git history:
- `99c4fc7` — feat(28-01): add QueueURLTemplate to SQSSinkConfig
- `2f3415c` — feat(28-01): add QueueURLTemplate routing + validated queue pool to SQSSinkConsumer
- `1ac997f` — test(28-02): add 3 YAML round-trip tests for SQS QueueURLTemplate
- `49f4e6f` — test(28-02): add routing, pool caching, and error tests for SQS per-table routing

### ROADMAP Success Criteria Coverage

| # | Success Criterion                                                                                      | Status     |
|---|--------------------------------------------------------------------------------------------------------|------------|
| 1 | `SQSSinkConfig` has `QueueURLTemplate` field (yaml: `queue-url-template`); overrides `QueueURL` per-message | VERIFIED |
| 2 | `Deliver()` evaluates Go template per-message with `.Schema`, `.Table`, `.Operation`                  | VERIFIED   |
| 3 | Queue URL pool caches resolved URLs; FIFO validation runs once per unique URL                         | VERIFIED   |
| 4 | When `queue-url-template` absent, behavior identical to single-queue path                             | VERIFIED   |
| 5 | `Close()` cleans up pooled state (no stateful resources to drain)                                     | VERIFIED   |
| 6 | Tests cover per-table routing (2 queues), pool caching, template error, fallback path                 | VERIFIED   |
| 7 | `CGO_ENABLED=0 go test ./internal/output/sqs/...` passes                                              | VERIFIED   |

---

_Verified: 2026-05-09T17:10:00Z_
_Verifier: Claude (gsd-verifier)_
