# Event Ticketing Platform

A production-grade, end-to-end event ticketing system — built to demonstrate senior Java backend
capability: real concurrency handling, full observability, AWS deployment, a RAG/AI feature, and an
Angular frontend.

The centerpiece is **selling the last few tickets correctly under load** — 1,000 buyers, 10 tickets
left, sell exactly 10.

## Status
🚧 Week 1 — Design & foundation.

## Tech stack
Java 21 · Spring Boot 3 · Spring Data JPA · Spring Security · Maven · PostgreSQL + pgvector ·
Redis · SQS · Stripe (test) · SES · Spring AI · Docker → ECS/Fargate · Terraform · GitHub Actions ·
CloudWatch · k6 · Angular + Angular Material.

## Local development
Postgres and Redis run as **native local installs** (not Docker Compose). See
[docs/design.md](docs/design.md) §6 and the [decision log](docs/decision-log.md).

## Docs
- [Design document](docs/design.md)
- [Decision log](docs/decision-log.md) — every "chose X over Y because Z"
- [Week 1 plan](week_1_work.md)

## Roadmap (8 weeks)
| Week | Milestone |
|------|-----------|
| 1 | Design doc, diagram, schema, running skeleton |
| 2 | Secured CRUD APIs + JWT auth |
| 3 | Concurrency-safe purchase flow (centerpiece) |
| 4 | Reliable async confirmation + DLQ |
| 5 | Deployed on AWS via CI/CD, infra in Terraform |
| 6 | Full observability + RAG retrieval |
| 7 | Hardened RAG + load tests + post-mortems |
| 8 | Angular frontend + rehearsed interview narrative |
