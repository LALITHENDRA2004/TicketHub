-- TicketHub initial schema. Money is stored as integer paise, never floating point.
-- Enums are VARCHAR + CHECK so JPA @Enumerated(STRING) maps directly.

CREATE TABLE users (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email          VARCHAR(320) NOT NULL,
    password_hash  VARCHAR(100) NOT NULL,
    full_name      VARCHAR(120) NOT NULL,
    role           VARCHAR(20)  NOT NULL DEFAULT 'USER' CHECK (role IN ('USER', 'ORGANIZER', 'ADMIN')),
    email_verified BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX uk_users_email ON users (lower(email));

CREATE TABLE refresh_tokens (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    token_hash VARCHAR(64) NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked    BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_refresh_tokens_user ON refresh_tokens (user_id);

CREATE TABLE venues (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizer_id UUID         NOT NULL REFERENCES users (id),
    name         VARCHAR(150) NOT NULL,
    city         VARCHAR(80)  NOT NULL,
    address      VARCHAR(300) NOT NULL,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE INDEX idx_venues_city ON venues (city);

CREATE TABLE seats (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    venue_id    UUID        NOT NULL REFERENCES venues (id) ON DELETE CASCADE,
    row_label   VARCHAR(5)  NOT NULL,
    seat_number INT         NOT NULL CHECK (seat_number > 0),
    category    VARCHAR(20) NOT NULL CHECK (category IN ('SILVER', 'GOLD', 'PLATINUM')),
    CONSTRAINT uk_seats_position UNIQUE (venue_id, row_label, seat_number)
);

CREATE TABLE events (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizer_id UUID         NOT NULL REFERENCES users (id),
    title        VARCHAR(200) NOT NULL,
    description  TEXT,
    genre        VARCHAR(40)  NOT NULL,
    poster_url   VARCHAR(500),
    status       VARCHAR(20)  NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'PUBLISHED', 'CANCELLED')),
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE INDEX idx_events_status_genre ON events (status, genre);

CREATE TABLE shows (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id   UUID        NOT NULL REFERENCES events (id) ON DELETE CASCADE,
    venue_id   UUID        NOT NULL REFERENCES venues (id),
    starts_at  TIMESTAMPTZ NOT NULL,
    status     VARCHAR(20) NOT NULL DEFAULT 'SCHEDULED' CHECK (status IN ('SCHEDULED', 'CANCELLED', 'COMPLETED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_shows_event_starts ON shows (event_id, starts_at);

CREATE TABLE show_prices (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    show_id     UUID        NOT NULL REFERENCES shows (id) ON DELETE CASCADE,
    category    VARCHAR(20) NOT NULL CHECK (category IN ('SILVER', 'GOLD', 'PLATINUM')),
    price_paise BIGINT      NOT NULL CHECK (price_paise >= 0),
    CONSTRAINT uk_show_prices_category UNIQUE (show_id, category)
);

CREATE TABLE bookings (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID        NOT NULL REFERENCES users (id),
    show_id         UUID        NOT NULL REFERENCES shows (id),
    status          VARCHAR(20) NOT NULL DEFAULT 'PENDING'
                        CHECK (status IN ('PENDING', 'CONFIRMED', 'CANCELLED', 'EXPIRED')),
    total_paise     BIGINT      NOT NULL CHECK (total_paise >= 0),
    hold_expires_at TIMESTAMPTZ NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_bookings_user_created ON bookings (user_id, created_at DESC);
CREATE INDEX idx_bookings_pending_expiry ON bookings (hold_expires_at) WHERE status = 'PENDING';

CREATE TABLE show_seats (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    show_id    UUID        NOT NULL REFERENCES shows (id) ON DELETE CASCADE,
    seat_id    UUID        NOT NULL REFERENCES seats (id),
    status     VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE' CHECK (status IN ('AVAILABLE', 'BOOKED')),
    booking_id UUID REFERENCES bookings (id),
    version    BIGINT      NOT NULL DEFAULT 0,
    CONSTRAINT uk_show_seats UNIQUE (show_id, seat_id)
);
CREATE INDEX idx_show_seats_show_status ON show_seats (show_id, status);

CREATE TABLE booking_seats (
    booking_id   UUID NOT NULL REFERENCES bookings (id) ON DELETE CASCADE,
    show_seat_id UUID NOT NULL REFERENCES show_seats (id),
    PRIMARY KEY (booking_id, show_seat_id)
);

CREATE TABLE payments (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id          UUID        NOT NULL REFERENCES bookings (id),
    provider            VARCHAR(20) NOT NULL,
    provider_order_id   VARCHAR(100) NOT NULL,
    provider_payment_id VARCHAR(100) UNIQUE,
    status              VARCHAR(20) NOT NULL DEFAULT 'CREATED'
                            CHECK (status IN ('CREATED', 'CAPTURED', 'FAILED', 'REFUND_PENDING', 'REFUNDED')),
    amount_paise        BIGINT      NOT NULL CHECK (amount_paise >= 0),
    raw_payload         JSONB,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_payments_booking ON payments (booking_id);
CREATE UNIQUE INDEX uk_payments_provider_order ON payments (provider, provider_order_id);

CREATE TABLE tickets (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id  UUID        NOT NULL REFERENCES bookings (id),
    ticket_code VARCHAR(40) NOT NULL UNIQUE,
    qr_payload  TEXT        NOT NULL,
    used_at     TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_tickets_booking ON tickets (booking_id);

CREATE TABLE audit_logs (
    id        BIGSERIAL PRIMARY KEY,
    actor_id  UUID,
    action    VARCHAR(60) NOT NULL,
    entity    VARCHAR(60) NOT NULL,
    entity_id VARCHAR(64),
    at        TIMESTAMPTZ NOT NULL DEFAULT now()
);
