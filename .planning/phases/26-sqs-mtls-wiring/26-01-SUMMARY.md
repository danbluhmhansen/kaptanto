---
phase: 26-sqs-mtls-wiring
plan: "01"
subsystem: infra
tags: [sqs, tls, mtls, aws-sdk-go-v2, x509, crypto]

# Dependency graph
requires:
  - phase: 24-sink-config-surface-cleanup
    provides: CA-only TLS block in NewSQSSinkConsumer (CFG-03 SQS TLS CA pinning)
provides:
  - Unified CA+mTLS TLS block in NewSQSSinkConsumer — tls.LoadX509KeyPair, single WithHTTPClient call
  - Startup validation error when only one of cert-file / key-file is set
  - generateTestClientKeypair helper for mTLS test cert/key generation
  - Three new mTLS tests: BothFieldsSet, PartialConfig_CertOnly, PartialConfig_KeyOnly
affects: [phase-27, phase-28, sqs-sink-consumers, integration-tests]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Unified TLS block: all TLS fields (CAFile, CertFile, KeyFile) merged into one tls.Config, one WithHTTPClient call"
    - "XOR guard on cert-file + key-file: (CertFile != '') != (KeyFile != '') returns error before any network call"
    - "PKCS#1 RSA key encoding (RSA PRIVATE KEY block type) for tls.LoadX509KeyPair compatibility"

key-files:
  created: []
  modified:
    - internal/output/sqs/consumer.go
    - internal/output/sqs/consumer_test.go

key-decisions:
  - "Single unified TLS block with one awsconfig.WithHTTPClient call — AWS SDK v2 silently overwrites options; second call would discard CA pool"
  - "XOR guard returns error before AWS credential loading so misconfiguration is caught immediately, not at first SendMessage"
  - "generateTestClientKeypair uses PKCS#1 (RSA PRIVATE KEY) not PKCS#8 (PRIVATE KEY) — tls.LoadX509KeyPair requires PKCS#1 for RSA keys"
  - "No buildTLSConfig helper extracted — SQS consumer configures TLS once; inline is correct per research anti-patterns"

patterns-established:
  - "Unified TLS block pattern: single tls.Config built from all TLS fields, single HTTP client override"
  - "PKCS#1 client keypair helper: generateTestClientKeypair following generateTestCAPEM convention"

requirements-completed: [CFG-03]

# Metrics
duration: 5min
completed: 2026-05-09
---

# Phase 26 Plan 01: SQS mTLS Wiring Summary

**SQS client certificate wired via tls.LoadX509KeyPair into unified CA+mTLS tls.Config with XOR validation guard and three new passing tests**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-09T13:01:29Z
- **Completed:** 2026-05-09T13:06:48Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Replaced the Phase 24 CA-only `if cfg.TLS.CAFile != ""` block with a unified block covering all three TLS fields (CAFile, CertFile, KeyFile) in a single `tls.Config` and a single `awsconfig.WithHTTPClient` call
- Added XOR validation guard that returns `"cert-file and key-file must both be set for mTLS"` before any AWS SDK or network call when only one of the pair is set
- Added `generateTestClientKeypair` helper (PKCS#1 RSA encoding) and three mTLS unit tests; all 16 tests in the SQS package pass with CGO_ENABLED=0

## Task Commits

Each task was committed atomically:

1. **Task 1: Replace CA-only TLS block with unified CA+mTLS block** - `56bb9af` (feat)
2. **Task 2: Add generateTestClientKeypair helper and three mTLS tests** - `df84bb5` (test)

**Plan metadata:** (docs commit follows)

_Note: TDD tasks may have multiple commits (test → feat → refactor)_

## Files Created/Modified
- `internal/output/sqs/consumer.go` - CA-only block replaced with unified CA+mTLS block; XOR guard; tls.LoadX509KeyPair; single WithHTTPClient
- `internal/output/sqs/consumer_test.go` - generateTestClientKeypair helper + 3 mTLS tests (BothFieldsSet, PartialConfig_CertOnly, PartialConfig_KeyOnly)

## Decisions Made
- **Single unified TLS block:** AWS SDK v2 `WithHTTPClient` is last-write-wins in the options slice — a second call would silently discard the CA pool. Merging all TLS fields into one `tls.Config` and one call is the only correct approach.
- **XOR guard before AWS loading:** Misconfiguration is caught immediately at construction time, not at the first live `SendMessage` call, matching the fail-fast pattern used throughout the codebase.
- **PKCS#1 key encoding:** `tls.LoadX509KeyPair` requires PKCS#1 (`RSA PRIVATE KEY` block) for RSA keys. Using PKCS#8 (`PRIVATE KEY`) would cause `tls.LoadX509KeyPair` to return an error in the test helper.
- **No helper function extracted:** The SQS consumer configures TLS exactly once. Extracting a `buildTLSConfig` function would be premature abstraction per the plan research anti-patterns.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- CFG-03 (SQS mTLS scope) fully closed
- SQS sink now supports full mTLS: CA-only, mTLS, or combined CA+mTLS — single code path, no regression
- Phase 27 and 28 (tech debt gap-closure) can proceed without any dependency on this phase

---
*Phase: 26-sqs-mtls-wiring*
*Completed: 2026-05-09*
