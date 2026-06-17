# Event Ticketing Platform — Design Document

> Living design doc. Started Week 1, Day 1. Update as decisions change.
> Companion file: [decision-log.md](./decision-log.md) — the running "chose X over Y because Z" record.

---

## 1. Problem statement

Organizers list events. Attendees buy tickets. The system must reliably take money, hand out
**exactly the right number of tickets**, confirm the purchase, and stay up under load — even when
thousands of people hit it in the same second.

The deceptively hard part, and the centerpiece of this build, is **selling the last few tickets
correctly**: 1,000 buyers, 10 tickets left → sell exactly 10, never 11 or 50.

**Scope note:** This is a backend-focused build. Weeks 1–7 are backend + infra + AI + load testing.
Angular frontend is a lighter, single-week effort in Week 8.

---

## 2. User types

| Role | What they do |
|------|--------------|
| **Attendee** | Browse/search events, view detail, buy tickets (Stripe), receive ticket + QR + email, view "My Tickets", ask the AI assistant about an event (RAG). |
| **Organizer** | Create/edit events (qty, price, venue, image), sales dashboard (tickets sold, revenue, sales-over-time), per-event sales detail, natural-language analytics. |
| **Admin** | Manage users + events, handle refunds/disputes, view platform-wide metrics. |

All non-public routes are behind JWT auth + role checks.

---

## 3. Core flows

### 3.1 Purchase flow (the centerpiece)
```
check availability → reserve → take payment → confirm + decrement
  → generate ticket + QR → queue confirmation email → update organizer stats
```

- **The bug to witness first:** naive code (read `available_quantity`, then write
  `available_quantity - n`) lets concurrent buyers read the same starting number and oversell.
- **Fixes, in order of learning:**
  1. **Optimistic locking** — `version` column; update fails if the row changed underneath; retry or reject. *Start here.*
  2. **Pessimistic locking** — `SELECT ... FOR UPDATE` to lock the row for the transaction.
  3. **Redis distributed lock** — when coordination spans more than one DB row or service.
- **Plus:** idempotency keys (double-click/retry doesn't double-charge), correct transaction
  boundaries, and a clean "sold out" response for losers of the race.

### 3.2 Async confirmation flow (Week 4)
On successful purchase, publish a message to **SQS** instead of doing email inline. A worker
generates the ticket + QR, sends the confirmation email via **SES**, and updates organizer stats.
Retries + **dead-letter queue** for messages that keep failing.

### 3.3 AI / RAG flow (Weeks 6–7)
- **Support assistant (lead feature):** user asks about refund policy / venue access / parking →
  answered from a knowledge base (event descriptions, venue info, FAQs, policies) via retrieval +
  grounded generation with citations. Returns "I don't have that information" on weak retrieval.
- **Semantic search:** "chill outdoor jazz this weekend" → embeddings search over event data.

---

## 4. Data model (core tables)

```
users          id, email, password_hash, role (attendee/organizer/admin), created_at
events         id, organizer_id, name, description, venue, event_date, image_url, status, created_at
ticket_types   id, event_id, name (General/VIP), price, total_quantity,
               available_quantity, version   ← optimistic locking happens here
orders         id, user_id, event_id, status (pending/paid/failed/refunded),
               total_amount, idempotency_key, created_at
order_items    id, order_id, ticket_type_id, quantity, unit_price
tickets        id, order_id, ticket_type_id, qr_code, status (valid/used/refunded)
kb_documents   /  kb_chunks   — RAG knowledge base (chunk text + embedding vector via pgvector)
```

`available_quantity` + `version` on `ticket_types` are where the concurrency fight happens.

---

## 5. API surface (REST)

**Auth:** `POST /auth/register`, `POST /auth/login` (returns JWT)

**Events (public):** `GET /events`, `GET /events/{id}`, `GET /events/search?q=...` (semantic)

**Events (organizer):** `POST /events`, `PUT /events/{id}`, `GET /events/{id}/sales`

**Purchase:** `POST /orders` (with `Idempotency-Key` header), `GET /orders/{id}`, `POST /orders/{id}/pay`

**Tickets:** `GET /me/tickets`

**AI:** `POST /events/{id}/ask` (RAG assistant), `POST /organizer/analytics/ask` (NL analytics)

**Admin:** `GET /admin/users`, `GET /admin/events`, `POST /admin/orders/{id}/refund`

---

## 6. Tech stack

| Layer | Choice |
|-------|--------|
| Language / framework | Java 21, Spring Boot 3, Spring MVC, Spring Data JPA, Spring Security |
| Build tool | **Maven** |
| AI | Spring AI (RAG, embeddings, LLM calls) |
| DB | PostgreSQL + pgvector (primary store + vector store in one) |
| Cache / locks | Redis |
| Async | SQS (with DLQ) |
| Payments | Stripe (test mode) |
| Email | SES |
| Frontend | Angular + Angular Material (Week 8, lighter) |
| Containers | Docker → ECS/Fargate, images in ECR |
| IaC | Terraform |
| CI/CD | GitHub Actions |
| Observability | CloudWatch (logs, metrics, alarms); optionally Prometheus + Grafana |
| Testing | JUnit 5, Mockito, integration tests |
| Load testing | k6 (primary), JMeter (one pass) |

**Local dev note:** Postgres + Redis run as **native local installs** (not Docker Compose), since
they're already available. Versions will be pinned when containerizing for AWS in Week 5; pgvector
extension installed locally in Week 6. See decision log.

---

## 7. AWS architecture

```
                          Internet
                             │
                  [ API Gateway / ALB ]
                             │
         [ ECS Fargate — Spring Boot app ]  ←── images from ECR
              │              │             │
          [ RDS ]      [ ElastiCache ]   [ SQS ] ──► [ Worker / DLQ ]
          Postgres        Redis            │
                                           ▼
                                       [ SES ]   confirmation emails

  [ S3 ]              event images / ticket assets
  [ Secrets Manager ] DB creds, Stripe key, LLM key
  [ IAM / VPC ]       permissions + private networking
  [ CloudWatch ]      logs, metrics, alarms (incl. queue-depth + billing alarm)
```

**Core services:** ECS/Fargate, ECR, RDS, ElastiCache, SQS, S3, IAM, VPC, CloudWatch.
**Very likely:** SNS, SES, Secrets Manager, API Gateway. **All provisioned via Terraform.**
Optional only with clear reason: DynamoDB, Bedrock, CloudFront.

---

## 8. Cross-cutting disciplines

- **Decision log** — every "chose X over Y because Z," maintained all 8 weeks.
- **Post-mortems** — one per chaos drill (what broke, how detected, root cause, fix, monitoring added).
- **Observability** — structured logs + correlation IDs threaded through app *and* async worker;
  metrics + dashboards that visibly react during load tests; alarms on error-rate, queue depth, billing.

---

## 9. If behind, cut in this order
1. **Never cut:** concurrency flow (Wk 3), deployment (Wk 5), observability + 1–2 chaos drills (Wk 6–7).
2. Trim first: frontend polish (keep buy-flow, drop admin UI refinement).
3. Then: reduce AI to RAG-only (drop NL analytics).
4. Then: fewer chaos drills (keep oversell, queue backup, one AI drill).
