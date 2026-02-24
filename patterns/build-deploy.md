---
description: Build and deployment patterns — App Store Connect, signing, CI/CD, TestFlight for FitToday
type: moc
---

# build-deploy

Build, deployment, and distribution patterns for FitToday. This guide covers XcodeBuildMCP integration, App Store Connect workflows, signing, and TestFlight distribution.

## Core Patterns

(Patterns will be added as they are captured and processed)

## Current Setup

- **Build:** XcodeBuildMCP integration (mcp__xcodebuildmcp__build_sim_name_proj)
- **Test:** mcp__xcodebuildmcp__test_sim_name_proj
- **Clean:** mcp__xcodebuildmcp__clean
- **Package Manager:** Swift Package Manager

## Skill Integration

The asc-* skills cover App Store Connect operations:
- asc-build-lifecycle, asc-release-flow, asc-signing-setup
- asc-submission-health, asc-testflight-orchestration
- asc-xcode-build, asc-metadata-sync

## Open Questions

- What CI/CD patterns work best for the project?
- How to optimize build times as the project grows?

---

Domains:
- [[index]]
