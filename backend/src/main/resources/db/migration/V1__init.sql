-- TicketHub initial schema (MySQL 8.0.16+). Money is stored as integer paise, never floating point.
-- Enums are VARCHAR + CHECK so JPA @Enumerated(STRING) maps directly.
-- UUIDs are BINARY(16), Hibernate's default UUID mapping on MySQL.
-- Emails are unique case-insensitively through the default utf8mb4_0900_ai_ci collation.

CREATE TABLE users (
    id             BINARY(16)   NOT NULL DEFAULT (UUID_TO_BIN(UUID())) PRIMARY KEY,
    email          VARCHAR(320) NOT NULL,
    password_hash  VARCHAR(100) NOT NULL,
    full_name      VARCHAR(120) NOT NULL,
    role           VARCHAR(20)  NOT NULL DEFAULT 'USER' CHECK (role IN ('USER', 'ORGANIZER', 'ADMIN')),
    email_verified BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at     DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at     DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    CONSTRAINT uk_users_email UNIQUE (email)
) ENGINE = InnoDB;

CREATE TABLE refresh_tokens (
    id         BINARY(16)  NOT NULL DEFAULT (UUID_TO_BIN(UUID())) PRIMARY KEY,
    user_id    BINARY(16)  NOT NULL,
    token_hash VARCHAR(64) NOT NULL UNIQUE,
    expires_at DATETIME(6) NOT NULL,
    revoked    BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    INDEX idx_refresh_tokens_user (user_id),
    CONSTRAINT fk_refresh_tokens_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE TABLE venues (
    id           BINARY(16)   NOT NULL DEFAULT (UUID_TO_BIN(UUID())) PRIMARY KEY,
    organizer_id BINARY(16)   NOT NULL,
    name         VARCHAR(150) NOT NULL,
    city         VARCHAR(80)  NOT NULL,
    address      VARCHAR(300) NOT NULL,
    created_at   DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at   DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    INDEX idx_venues_city (city),
    CONSTRAINT fk_venues_organizer FOREIGN KEY (organizer_id) REFERENCES users (id)
) ENGINE = InnoDB;

CREATE TABLE seats (
    id          BINARY(16)  NOT NULL DEFAULT (UUID_TO_BIN(UUID())) PRIMARY KEY,
    venue_id    BINARY(16)  NOT NULL,
    row_label   VARCHAR(5)  NOT NULL,
    seat_number INT         NOT NULL CHECK (seat_number > 0),
    category    VARCHAR(20) NOT NULL CHECK (category IN ('SILVER', 'GOLD', 'PLATINUM')),
    CONSTRAINT uk_seats_position UNIQUE (venue_id, row_label, seat_number),
    CONSTRAINT fk_seats_venue FOREIGN KEY (venue_id) REFERENCES venues (id) ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE TABLE events (
    id           BINARY(16)   NOT NULL DEFAULT (UUID_TO_BIN(UUID())) PRIMARY KEY,
    organizer_id BINARY(16)   NOT NULL,
    title        VARCHAR(200) NOT NULL,
    description  TEXT,
    genre        VARCHAR(40)  NOT NULL,
    poster_url   VARCHAR(500),
    status       VARCHAR(20)  NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'PUBLISHED', 'CANCELLED')),
    created_at   DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at   DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    INDEX idx_events_status_genre (status, genre),
    CONSTRAINT fk_events_organizer FOREIGN KEY (organizer_id) REFERENCES users (id)
) ENGINE = InnoDB;

CREATE TABLE shows (
    id         BINARY(16)  NOT NULL DEFAULT (UUID_TO_BIN(UUID())) PRIMARY KEY,
    event_id   BINARY(16)  NOT NULL,
    venue_id   BINARY(16)  NOT NULL,
    starts_at  DATETIME(6) NOT NULL,
    status     VARCHAR(20) NOT NULL DEFAULT 'SCHEDULED' CHECK (status IN ('SCHEDULED', 'CANCELLED', 'COMPLETED')),
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    INDEX idx_shows_event_starts (event_id, starts_at),
    CONSTRAINT fk_shows_event FOREIGN KEY (event_id) REFERENCES events (id) ON DELETE CASCADE,
    CONSTRAINT fk_shows_venue FOREIGN KEY (venue_id) REFERENCES venues (id)
) ENGINE = InnoDB;

CREATE TABLE show_prices (
    id          BINARY(16)  NOT NULL DEFAULT (UUID_TO_BIN(UUID())) PRIMARY KEY,
    show_id     BINARY(16)  NOT NULL,
    category    VARCHAR(20) NOT NULL CHECK (category IN ('SILVER', 'GOLD', 'PLATINUM')),
    price_paise BIGINT      NOT NULL CHECK (price_paise >= 0),
    CONSTRAINT uk_show_prices_category UNIQUE (show_id, category),
    CONSTRAINT fk_show_prices_show FOREIGN KEY (show_id) REFERENCES shows (id) ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE TABLE bookings (
    id              BINARY(16)  NOT NULL DEFAULT (UUID_TO_BIN(UUID())) PRIMARY KEY,
    user_id         BINARY(16)  NOT NULL,
    show_id         BINARY(16)  NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'PENDING'
                        CHECK (status IN ('PENDING', 'CONFIRMED', 'CANCELLED', 'EXPIRED')),
    total_paise     BIGINT      NOT NULL CHECK (total_paise >= 0),
    hold_expires_at DATETIME(6) NOT NULL,
    created_at      DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at      DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    INDEX idx_bookings_user_created (user_id, created_at DESC),
    -- MySQL has no partial indexes; leading on status keeps the PENDING-expiry sweep a range scan.
    INDEX idx_bookings_status_expiry (status, hold_expires_at),
    CONSTRAINT fk_bookings_user FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT fk_bookings_show FOREIGN KEY (show_id) REFERENCES shows (id)
) ENGINE = InnoDB;

CREATE TABLE show_seats (
    id         BINARY(16)  NOT NULL DEFAULT (UUID_TO_BIN(UUID())) PRIMARY KEY,
    show_id    BINARY(16)  NOT NULL,
    seat_id    BINARY(16)  NOT NULL,
    status     VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE' CHECK (status IN ('AVAILABLE', 'BOOKED')),
    booking_id BINARY(16),
    version    BIGINT      NOT NULL DEFAULT 0,
    CONSTRAINT uk_show_seats UNIQUE (show_id, seat_id),
    INDEX idx_show_seats_show_status (show_id, status),
    CONSTRAINT fk_show_seats_show FOREIGN KEY (show_id) REFERENCES shows (id) ON DELETE CASCADE,
    CONSTRAINT fk_show_seats_seat FOREIGN KEY (seat_id) REFERENCES seats (id),
    CONSTRAINT fk_show_seats_booking FOREIGN KEY (booking_id) REFERENCES bookings (id)
) ENGINE = InnoDB;

CREATE TABLE booking_seats (
    booking_id   BINARY(16) NOT NULL,
    show_seat_id BINARY(16) NOT NULL,
    PRIMARY KEY (booking_id, show_seat_id),
    CONSTRAINT fk_booking_seats_booking FOREIGN KEY (booking_id) REFERENCES bookings (id) ON DELETE CASCADE,
    CONSTRAINT fk_booking_seats_show_seat FOREIGN KEY (show_seat_id) REFERENCES show_seats (id)
) ENGINE = InnoDB;

CREATE TABLE payments (
    id                  BINARY(16)   NOT NULL DEFAULT (UUID_TO_BIN(UUID())) PRIMARY KEY,
    booking_id          BINARY(16)   NOT NULL,
    provider            VARCHAR(20)  NOT NULL,
    provider_order_id   VARCHAR(100) NOT NULL,
    provider_payment_id VARCHAR(100) UNIQUE,
    status              VARCHAR(20)  NOT NULL DEFAULT 'CREATED'
                            CHECK (status IN ('CREATED', 'CAPTURED', 'FAILED', 'REFUND_PENDING', 'REFUNDED')),
    amount_paise        BIGINT       NOT NULL CHECK (amount_paise >= 0),
    raw_payload         JSON,
    created_at          DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at          DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    INDEX idx_payments_booking (booking_id),
    CONSTRAINT uk_payments_provider_order UNIQUE (provider, provider_order_id),
    CONSTRAINT fk_payments_booking FOREIGN KEY (booking_id) REFERENCES bookings (id)
) ENGINE = InnoDB;

CREATE TABLE tickets (
    id          BINARY(16)  NOT NULL DEFAULT (UUID_TO_BIN(UUID())) PRIMARY KEY,
    booking_id  BINARY(16)  NOT NULL,
    ticket_code VARCHAR(40) NOT NULL UNIQUE,
    qr_payload  TEXT        NOT NULL,
    used_at     DATETIME(6),
    created_at  DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    INDEX idx_tickets_booking (booking_id),
    CONSTRAINT fk_tickets_booking FOREIGN KEY (booking_id) REFERENCES bookings (id)
) ENGINE = InnoDB;

CREATE TABLE audit_logs (
    id        BIGINT      NOT NULL AUTO_INCREMENT PRIMARY KEY,
    actor_id  BINARY(16),
    action    VARCHAR(60) NOT NULL,
    entity    VARCHAR(60) NOT NULL,
    entity_id VARCHAR(64),
    at        DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
) ENGINE = InnoDB;
