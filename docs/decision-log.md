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
