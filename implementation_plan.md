# Implementation Plan - Milestone 0 (Revised Architecture Analysis)

This implementation plan details the revised architecture analysis and master roadmap for **House of SIYA's Business Management Suite**.

## User Review Required

> [!IMPORTANT]
> Milestone 0 has been **re-evaluated and revised** to correct 8 architectural areas identified during detailed prompt review.
> Please review the updated architecture proposal artifact: [`architecture_proposal.md`](file:///C:/Users/veera/.gemini/antigravity/brain/fa7b2f86-2e37-47b6-8548-5f952883267e/architecture_proposal.md).

## Summary of Revisions & Architectural Corrections

1. **Storage Layer Rationalization**: Removed redundant `Hive`/`Isar` local DB layer. Cloud Firestore native offline persistence is now the sole local storage & offline sync engine for structured business records. `flutter_secure_storage` is kept solely for PIN hashes, tokens, and device keys.
2. **GCP Backup Schedule**: Clarified daily automated Firestore exports with 30-day daily retention + long-term monthly backups via GCP Bucket lifecycle rules.
3. **Serverless RBAC**: Firebase Auth Custom Claims (`role: 'owner' | 'manager'`) will enforce zero-trust security at the Firestore Security Rules layer without needing an always-on backend.
4. **Document Number Timing & Exhaustion**: Sequence numbers are assigned strictly upon record save/confirmation. Exhausted offline blocks fall back gracefully to a `PENDING-` status until network connectivity is restored.
5. **Payment & Refund Scope**: Formalized multi-entity support across both **Orders** and **Classes (Student Fees)**.
6. **Photo Offline Pipeline**: Captured photos are saved to app storage immediately (`file://`), rendered instantly in UI offline, uploaded in the background when online, and Firestore metadata updated upon completion.
7. **Platform Offline Matrix**: Mobile/Tablet is fully offline-first. The Web application is strictly online-only.

## Verification Plan

### Automated & Manual Verification Plan for Upcoming Milestones
- **Unit Tests**: Payment/refund ledgers, unit conversions (inches/cm), offline document range allocation & fallback `PENDING-` status generation, rental date collision detection.
- **Security Tests**: Firestore rule verification using Firebase Emulator verifying Manager denial for invoices, reports, classes, and settings.
- **Offline Sync Tests**: Disconnect network, create entities/photos/PDFs, verify local rendering, reconnect, and confirm seamless Firestore/Storage sync.
