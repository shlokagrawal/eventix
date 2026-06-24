-- V1: core reference tables (users, events, ticket_types)
-- Schema is owned by Flyway; Hibernate runs in `validate` mode and never alters it.

-- ---------------------------------------------------------------------------
-- users: people who interact with the system (attendees, organizers, admins)
-- ---------------------------------------------------------------------------
CREATE TABLE users (
    id            BIGINT      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email         VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role          VARCHAR(20)  NOT NULL
                  CHECK (role IN ('ATTENDEE', 'ORGANIZER', 'ADMIN')),
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- events: an event put on by an organizer (a user)
-- ---------------------------------------------------------------------------
CREATE TABLE events (
    id            BIGINT       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    organizer_id  BIGINT       NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    name          VARCHAR(200) NOT NULL,
    venue         VARCHAR(255),
    starts_at     TIMESTAMPTZ,
    status        VARCHAR(20)  NOT NULL DEFAULT 'DRAFT'
                  CHECK (status IN ('DRAFT', 'PUBLISHED', 'CANCELLED')),
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- Postgres does NOT auto-index FK columns; index it for joins / lookups by organizer.
CREATE INDEX idx_events_organizer_id ON events(organizer_id);

-- ---------------------------------------------------------------------------
-- ticket_types: a class of ticket for an event (e.g. "VIP", "General").
-- `available_quantity` is the stock decremented at purchase.
-- `version` is the optimistic-locking column (maps to JPA @Version).
-- ---------------------------------------------------------------------------
CREATE TABLE ticket_types (
    id                 BIGINT        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_id           BIGINT        NOT NULL REFERENCES events(id) ON DELETE RESTRICT,
    name               VARCHAR(100)  NOT NULL,
    price              NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
    available_quantity INTEGER       NOT NULL CHECK (available_quantity >= 0),
    version            BIGINT        NOT NULL DEFAULT 0,
    created_at         TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ   NOT NULL DEFAULT now()
);

CREATE INDEX idx_ticket_types_event_id ON ticket_types(event_id);
