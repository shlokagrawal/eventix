# Week 1 — Design & Foundation

**Goal:** A written design, a running skeleton app, and the full data model — connecting to local **native Postgres + Redis** (no Docker Compose).

---

## Day-by-day

### Day 1 — Design doc + repo
- Problem statement, three user types (attendee / organizer / admin), core flows.
- AWS architecture diagram.
- Start the **decision log** ("chose X over Y because Z") — including:
  *"Chose native Postgres/Redis over Docker Compose because already installed; will pin versions when containerizing in Week 5."*
- Set up the GitHub repo.

### Day 2 — Local environment
- Scaffold Spring Boot 3 / Java 21 project (Spring Web, Data JPA, Security, Validation, Flyway, PostgreSQL driver, Redis).
- Confirm **native Postgres** is running; create the project database + DB user.
- Install + start **native Redis** (`brew install redis`, `brew services start redis`).
- Point `application.yml` at `localhost:5432` (Postgres) and `localhost:6379` (Redis).
- App boots, connects to DB, exposes a working `/health` endpoint *(ideally one that reports DB + Redis connectivity)*.

### Day 3 — Data model part 1
- Define + migrate `users`, `events`, `ticket_types` (with `available_quantity` + `version` — the concurrency column).
- Use **Flyway** for migrations from day one.

### Day 4 — Data model part 2
- `orders`, `order_items`, `tickets` (+ stub `kb_documents` / `kb_chunks` for RAG later).
- Wire up JPA entities + repositories. Seed some test data.

### Day 5 — Review + buffer
- Verify schema, clean up, write the first few unit tests (start the testing habit).
- Catch up if behind.

---

## What's different from the original plan
- ❌ ~~Docker Compose for Postgres + Redis~~ → ✅ use native installs
- ➕ One extra Day-2 task: install/start native Redis + create the Postgres DB by hand
- 📝 One note logged for later: install **pgvector** extension in Week 6, and check that the local Postgres major version roughly matches what RDS will run in Week 5

---

## Definition of done
- ✅ Running skeleton app — boots, connects to Postgres + Redis, `/health` works
- ✅ Full schema migrated (all core tables)
- ✅ Design doc + architecture diagram committed
- ✅ Decision log started

---

## Open decision
- **Build tool:** Maven or Gradle? Default recommendation: **Maven** (matches most Spring docs/references).
