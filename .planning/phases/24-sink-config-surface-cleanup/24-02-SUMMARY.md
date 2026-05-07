---
phase: 24-sink-config-surface-cleanup
plan: "02"
subsystem: sqs-sink
tags: [tls, sqs, cfg-03, ca-pinning, http-transport]
dependency_graph:
  requires: ["24-01"]
  provides: ["CFG-03"]
  affects: ["internal/output/sqs/consumer.go", "internal/output/sqs/consumer_test.go"]
tech_stack:
  added: []
  patterns: ["x509.NewCertPool + AppendCertsFromPEM", "awsconfig.WithHTTPClient with custom *http.Transport", "TDD RED/GREEN with stdlib crypto for self-signed CA generation"]
key_files:
  created: []
  modified:
    - internal/output/sqs/consumer.go
    - internal/output/sqs/consumer_test.go
decisions:
  - "CheckRedirect guard added to *http.Client to prevent the AWS SDK from following redirects through the custom transport"
  - "pemData variable name used instead of pem to avoid shadowing encoding/pem package name"
  - "mTLS (CertFile/KeyFile) explicitly out of scope for Phase 24 — only CAFile is wired"
  - "generateTestCAPEM uses stdlib crypto/rsa + crypto/x509 — no external test deps"
metrics:
  duration: "3 minutes"
  completed: "2026-05-08"
  tasks_completed: 2
  files_modified: 2
---

# Phase 24 Plan 02: SQS TLS CAFile Wiring Summary

SQS TLS CA pinning functional via x509.NewCertPool + AppendCertsFromPEM + awsconfig.WithHTTPClient, closing CFG-03 gap where SQSSinkConfig.TLS was parsed but silently ignored.

## What Was Built

`NewSQSSinkConsumer` now checks `cfg.TLS.CAFile` before loading the AWS config. When set it reads the PEM file, validates it contains at least one certificate block, builds an `*http.Transport` with the custom CA pool (TLS 1.2 minimum), and injects a `*http.Client` via `awsconfig.WithHTTPClient`. Both error paths return messages containing `"ca-file"` so callers can identify TLS construction failures distinctly from AWS/network errors.

Three new unit tests cover the full error surface:
- `TestNewSQSSinkConsumer_TLS_MissingCAFile` — missing file returns error with "ca-file"
- `TestNewSQSSinkConsumer_TLS_EmptyPEM` — invalid PEM content returns error with "ca-file"
- `TestNewSQSSinkConsumer_TLS_ValidCA` — valid self-signed CA passes TLS construction; any error comes from AWS/network

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 (RED) | 1d8ae57 | test(24-02): add failing TLS tests for NewSQSSinkConsumer |
| 2 (GREEN) | fcd9a39 | feat(24-02): wire TLS CAFile into NewSQSSinkConsumer (CFG-03) |

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check

- [x] `internal/output/sqs/consumer.go` modified with TLS wiring
- [x] `internal/output/sqs/consumer_test.go` has three new TLS tests
- [x] `AppendCertsFromPEM` present in consumer.go
- [x] `WithHTTPClient` present in consumer.go
- [x] All 15 SQS tests pass
- [x] `CGO_ENABLED=0 go build ./...` clean
- [x] Commits 1d8ae57 and fcd9a39 exist

## Self-Check: PASSED
