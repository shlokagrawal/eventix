# Decision Log

> The single most important artifact of this project. Every meaningful choice gets an entry:
> **what** was chosen, **over what alternative**, and **why**. This is what turns the build into
> fluent "why X over Y" interview answers. Append new entries; don't delete old ones — if a
> decision is reversed, add a new entry that supersedes it and link back.

Format:
```
### [YYYY-MM-DD] Title
- **Decision:** ...
- **Alternatives considered:** ...
- **Why:** ...
- **Revisit if:** ... (optional)
```

---

### [2026-06-15] Build tool: Maven over Gradle
- **Decision:** Use Maven.
- **Alternatives considered:** Gradle.
- **Why:** Most Spring Boot documentation and reference material uses Maven, which lowers friction
  while learning. Gradle's faster builds and concise DSL aren't worth the extra reference-mismatch
  cost for a solo learning project.
- **Revisit if:** Build times become a real bottleneck.

### [2026-06-15] Local DB/cache: native Postgres + Redis over Docker Compose
- **Decision:** Run Postgres and Redis as native local installs for development.
- **Alternatives considered:** Docker Compose for both.
- **Why:** Postgres is already installed and Redis is a quick native install; Compose adds a moving
  part (Docker daemon) without benefit at this stage. The app connects to `localhost` either way.
- **Trade-off accepted:** Must install the pgvector extension manually (Week 6) and ensure the
  local Postgres major version roughly matches AWS RDS (Week 5) to avoid "works locally" drift.
- **Revisit if:** Onboarding a second dev, or local/prod version drift causes bugs.

### [2026-06-15] Role scope: backend-focused build
- **Decision:** Treat this as a backend-focused project; concentrate the Angular frontend in Week 8
  as a lighter effort.
- **Alternatives considered:** Full-stack with an early thin frontend slice at end of Week 2.
- **Why:** The senior signal lives in the backend (concurrency, observability, AWS, AI architecture).
  Splitting focus early is a junior trap; stabilize the API contract first, layer UI on top last.
- **Revisit if:** The target role turns out to require demonstrable Angular depth.

### [2026-06-15] Migrations: Flyway from day one
- **Decision:** Use Flyway for all schema changes starting with the first table.
- **Alternatives considered:** Liquibase; Hibernate auto-DDL (`ddl-auto: update`).
- **Why:** Versioned, reviewable, production-realistic migrations from the start. Auto-DDL hides
  schema drift and isn't safe for the AWS deploy later. Flyway's plain-SQL migrations are simpler
  to reason about than Liquibase's XML/YAML changelogs for this scope.
- **Revisit if:** Complex cross-DB or branching migration needs appear (unlikely here).

### [2026-06-18] Schema ownership: Flyway owns DDL, Hibernate set to `validate`
- **Decision:** Hand-write schema as Flyway migrations; set `spring.jpa.hibernate.ddl-auto: validate`
  so Hibernate only verifies entities match the migrated schema and never mutates it. Entities are
  written by hand to map onto the migration, not the other way around.
- **Alternatives considered:** Entity-first / `ddl-auto: update` (Hibernate generates and alters
  tables from `@Entity` classes); generating a DDL draft from Hibernate then editing into a migration.
- **Why:** `update` is non-deterministic, can't do destructive or data migrations, has no review or
  rollback, and is unsafe against a live DB — a recognised production footgun. Migration-first gives
  deterministic, reviewable, reproducible schema across environments; `validate` catches entity/schema
  drift at boot instead of letting it silently diverge. This is the industry-standard setup for
  production Spring Boot services.
- **Revisit if:** Never expected to reverse; if draft-generation becomes a useful shortcut, the
  migration still remains the committed source of truth.

### [2026-06-18] Enum columns: `VARCHAR + CHECK` over native Postgres `ENUM`
- **Decision:** Model fixed-set columns (`users.role`, `events.status`, etc.) as `VARCHAR` with a
  `CHECK (col IN (...))` constraint, mapped on the Java side via `@Enumerated(EnumType.STRING)`.
  The Java enum is the source of truth; the CHECK is a DB-level guardrail. CHECK string values must
  match the Java enum constant names exactly (same case).
- **Alternatives considered:** Native Postgres `ENUM` type; a lookup/reference table with a FK.
- **Why:** Native `ENUM` is rigid to evolve — `ALTER TYPE ... ADD VALUE` has a non-transactional
  gotcha (conflicts with Flyway's transactional migrations), and removing/renaming values means
  recreating the type. It also needs custom Hibernate type mapping. `VARCHAR + CHECK` evolves with
  plain transactional DDL and maps cleanly with `@Enumerated(STRING)`. A lookup table is more
  flexible but overkill (extra join) for small, rarely-changing sets.
- **Revisit if:** A set grows large or needs admin-managed values/metadata at runtime → promote that
  specific column to a lookup table.
