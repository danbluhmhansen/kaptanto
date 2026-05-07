---
phase: 24-sink-config-surface-cleanup
plan: "01"
subsystem: cmd
tags: [cli, config, help-text, cfd-04]
dependency_graph:
  requires: []
  provides: [CFG-04]
  affects: [internal/cmd/root.go, internal/cmd/root_test.go]
tech_stack:
  added: []
  patterns: [TDD red-green, pflag.Flag.Usage assertion]
key_files:
  created: []
  modified:
    - internal/cmd/root.go
    - internal/cmd/root_test.go
decisions:
  - "Updated --output flag Usage string in one place only (line 113); runtime error at line 725 was already correct and left unchanged"
  - "TestFlagOutputUsageComplete follows TestHAFlagHelpText pattern exactly — direct f.Usage field access, same package cmd_test"
metrics:
  duration: "~3 minutes"
  completed: "2026-05-08"
  tasks_completed: 1
  tasks_total: 1
  files_changed: 2
---

# Phase 24 Plan 01: Fix --output flag usage string Summary

**One-liner:** Updated pflag Usage string on --output flag from 5 modes to all 8 (stdout | sse | grpc | nats | sqs | kafka | pubsub | rabbitmq), closing CFG-04 gap with a new TestFlagOutputUsageComplete test.

## What Was Built

Fixed the stale `--output` flag help text in `internal/cmd/root.go` so `kaptanto --help` lists all 8 valid output modes. Added `TestFlagOutputUsageComplete` to `internal/cmd/root_test.go` to lock the usage string completeness.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Fix --output flag usage string and add TestFlagOutputUsageComplete | 9fd3f18 | internal/cmd/root.go, internal/cmd/root_test.go |

## Decisions Made

- Updated only `root.go` line 113 (the pflag Usage string); the runtime error at line 725 was already correct and was not touched.
- `TestFlagOutputUsageComplete` uses the same `f.Usage` direct field access pattern as `TestHAFlagHelpText` (pflag v1.0.9 pattern, package `cmd_test`).

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED

- internal/cmd/root.go: FOUND
- internal/cmd/root_test.go: FOUND
- Commit 9fd3f18: FOUND
