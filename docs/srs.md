# TicketHub: Software Requirements Specification

> Toolchain update: the project targets **Java 25 (LTS)** and **Spring Boot 4.1** instead of Java 21. Docker images and CI use Temurin 25. Everything else follows the original plan below.

TicketHub lets users browse events, pick exact seats, hold them for 5 minutes and pay, with no seat ever sold twice. That guarantee is the project's headline feature.

**Vision:** For people booking concerts, movies and talks, TicketHub is a seat-level booking platform that stays correct under concurrent demand, unlike simple CRUD booking demos.

## Stakeholders and roles

| Role | Can do |
|---|---|
| Guest | Browse and search events, view seat maps |
| Customer (USER) | Everything a guest can, plus book, pay, cancel, view tickets |
| Organizer | Create venues, events, shows and pricing; view sales for own events |
| Admin | Manage users and roles, approve organizers, view platform stats |

## Functional requirements

| ID | Requirement | Priority |
|---|---|---|
| FR-01 | Register with email + password; verify email by link | Must |
| FR-02 | Log in, receive a JWT access token (15 min) and refresh token (7 days); log out revokes refresh token | Must |
| FR-03 | Reset forgotten password by emailed token | Should |
| FR-04 | Organizer creates venues with a seat layout (rows, seats, category: Silver, Gold, Platinum) | Must |
| FR-05 | Organizer creates events and shows (date, time, venue) with price per category | Must |
| FR-06 | Anyone lists events with search (title), filters (city, category, date range) and pagination | Must |
| FR-07 | Anyone views a show's live seat map: available, held, booked | Must |
| FR-08 | Customer selects up to 6 seats and holds them for 5 minutes | Must |
| FR-09 | Held seats auto-release when the hold expires or the user abandons checkout | Must |
| FR-10 | Customer pays through Razorpay (or Stripe) test mode; booking confirms only on verified webhook | Must |
| FR-11 | Confirmed booking generates a ticket with a unique QR code, emailed as PDF | Must |
| FR-12 | Customer views booking history and downloads tickets | Must |
| FR-13 | Customer cancels up to 24 hours before a show; refund is recorded | Should |
| FR-14 | Seat map updates live for all viewers when seats are held or booked (WebSocket / SSE) | Should |
| FR-15 | Organizer dashboard: tickets sold, revenue, occupancy per show | Should |
| FR-16 | Admin manages users, approves organizer accounts | Should |
| FR-17 | Venue staff scans a QR code to validate entry once | Could |
| FR-18 | Coupon codes (flat or percent) | Could |

## Non-functional requirements

| ID | Category | Target |
|---|---|---|
| NFR-01 | Correctness | Zero double bookings under 100 concurrent requests for one seat (proven by a test) |
| NFR-02 | Performance | p95 latency under 300 ms for read APIs; event list cached in Redis |
| NFR-03 | Security | BCrypt passwords, JWT, role-based access, OWASP Top 10 checks, login rate limit (5/min/IP) |
| NFR-04 | Availability | Health endpoint `/actuator/health`; auto-restart on host |
| NFR-05 | Maintainability | Service-layer test coverage ≥ 70%, Sonar quality gate passed |
| NFR-06 | Usability | Responsive from 360 px, keyboard accessible, WCAG AA contrast |
| NFR-07 | Observability | Structured JSON logs, correlation id per request, Prometheus metrics |
| NFR-08 | Portability | Whole stack starts with `docker compose up` |

## Key user stories

**TH-08 Hold seats.** As a customer, I want to hold seats while I pay so nobody else takes them.
- Given seats A5 and A6 are available, when I hold them, then they show as held to everyone and I see a 5:00 countdown.
- Given another user holds A5, when I try to hold A5, then I get HTTP 409 "Seat no longer available".
- Given my hold expires, then A5 and A6 become available again within 10 seconds.

**TH-10 Pay and confirm.** As a customer, I want my booking confirmed only after payment succeeds.
- Given a valid hold, when payment succeeds and the webhook signature verifies, then the booking becomes CONFIRMED and seats BOOKED.
- Given payment fails or the hold expired, then no booking is confirmed and any captured payment is marked for refund.
- Given the same webhook arrives twice, then the booking is processed once (idempotent).

**TH-11 Receive ticket.** As a customer, I want a ticket with a QR code by email within 1 minute of payment.

**TH-05 Create show.** As an organizer, I want to create a show with category prices so customers can book it.

**TH-06 Find events.** As a guest, I want to filter events by city and date so I find something to attend.

## Risks

| Risk | Mitigation |
|---|---|
| Concurrency bugs are hard to reproduce | Write the concurrency test in Sprint 3 before polishing features |
| Payment webhooks cannot reach localhost | Use ngrok or the Razorpay/Stripe CLI to forward webhooks |
| Free hosting sleeps after inactivity | Mention cold starts in README; ping health endpoint before demos |
| Scope creep | "Could" items only after v1.0.0 is live |

## Design

Modular monolith: one Spring Boot app split into feature modules (`auth, user, venue, event, booking, payment, ticket, notification`), PostgreSQL for truth, Redis for seat holds and caching. Modules talk through service interfaces or Spring application events (`BookingConfirmedEvent`), never through each other's repositories. The schema lives in `backend/src/main/resources/db/migration/V1__init.sql`.

### REST API (v1)

| Method | Path | Role | Purpose |
|---|---|---|---|
| POST | /api/v1/auth/register | Public | Create account, send verification email |
| GET | /api/v1/auth/verify?token= | Public | Verify email |
| POST | /api/v1/auth/login | Public | Return access + refresh tokens |
| POST | /api/v1/auth/refresh | Public | Rotate refresh token |
| POST | /api/v1/auth/logout | USER | Revoke refresh token |
| GET | /api/v1/users/me | USER | Profile |
| POST | /api/v1/venues | ORGANIZER | Create venue with seat layout |
| POST | /api/v1/events | ORGANIZER | Create event |
| POST | /api/v1/events/{id}/shows | ORGANIZER | Create show with prices |
| GET | /api/v1/events?city=&genre=&from=&to=&q=&page=&size= | Public | Search and paginate |
| GET | /api/v1/events/{id} | Public | Event detail with shows |
| GET | /api/v1/shows/{id}/seats | Public | Seat map with status |
| POST | /api/v1/shows/{id}/holds | USER | Hold seats `{seatIds:[...]}`, returns bookingId + expiresAt |
| DELETE | /api/v1/bookings/{id}/hold | USER | Release hold |
| POST | /api/v1/bookings/{id}/payment-order | USER | Create gateway order |
| POST | /api/v1/payments/webhook | Gateway (signature) | Confirm or fail payment |
| GET | /api/v1/bookings/me | USER | Booking history |
| POST | /api/v1/bookings/{id}/cancel | USER | Cancel and record refund |
| GET | /api/v1/tickets/{id}/pdf | USER | Download ticket |
| POST | /api/v1/tickets/validate | ORGANIZER | Scan QR at entry |
| GET | /api/v1/organizer/shows/{id}/stats | ORGANIZER | Sales and occupancy |
| GET | /api/v1/shows/{id}/seats/stream | Public | SSE live seat updates |

Errors are ProblemDetail `{type, title, status, detail, instance, correlationId}`: 400 validation, 401 unauthenticated, 403 wrong role, 404 missing, 409 seat conflict, 422 business rule, 429 rate limit.

### Seat hold algorithm

1. Validate: show is in the future, 1 to 6 seats, all seats belong to the show.
2. For each seat, `SET hold:{showId}:{seatId} {userId} NX EX 300`. NX means only one user can win.
3. If any seat fails, delete the keys just set and return 409 with the seat numbers taken.
4. Create a PENDING booking with `hold_expires_at = now + 5 min`; publish a seat-update event to SSE subscribers.
5. The seat map merges DB BOOKED seats with Redis `hold:*` keys to show held seats.
6. A `@Scheduled` job every 30 s marks overdue PENDING bookings EXPIRED; Redis TTL has already freed the seats.
7. On confirmation, in one `@Transactional` method, update `show_seats` to BOOKED where status = AVAILABLE. The `@Version` column makes a concurrent writer fail with `OptimisticLockException`, the second safety net behind Redis.

### Payment flow

1. Client calls payment-order; backend checks the hold is still valid and creates a gateway order for the server-computed total.
2. Frontend opens Razorpay Checkout in test mode.
3. Gateway calls `/payments/webhook`. Backend verifies the HMAC signature, then looks up the payment by `provider_payment_id`; already processed means 200 and stop.
4. On success and valid hold: seats BOOKED, booking CONFIRMED, delete Redis keys, publish `BookingConfirmedEvent`.
5. `@Async` listener generates ticket code, QR (ZXing), PDF (OpenPDF) and sends email.
6. On success but expired hold: payment REFUND_PENDING and email the user. On failure: booking stays PENDING until expiry.

### Security

- Stateless filter chain; `JwtAuthFilter` validates HS256 access tokens (256-bit secret from env).
- Refresh tokens: random 256-bit, stored hashed, rotated on every refresh, revoked on logout; sent as HttpOnly, Secure, SameSite cookie.
- `@PreAuthorize("hasRole('ORGANIZER')")` plus ownership checks.
- BCrypt strength 12; Bucket4j + Redis rate limits on login and register.
- CORS allows only the frontend origin; secrets only in env vars; webhook rejects requests without a valid signature.

## Sprint plan

| Sprint | Goal | Scope | Release |
|---|---|---|---|
| 0 | Foundation | Repo, compose, Flyway V1, CI, Vite app, hello-world deploy | v0.1.0 |
| 1 | Auth | FR-01 to FR-03, JWT, refresh rotation, auth pages, Axios interceptor | v0.2.0 |
| 2 | Catalogue | FR-04 to FR-06, Specifications search, Redis cache, event pages, organizer wizard | v0.3.0 |
| 3 | Booking core | FR-07 to FR-09, Redis holds, expiry job, optimistic locking, 100-thread concurrency test, seat map | v0.4.0 |
| 4 | Payment + tickets | FR-10 to FR-12, Razorpay webhook, QR + PDF + email, checkout | v0.5.0 |
| 5 | Live + dashboards | FR-13 to FR-16, SSE, organizer stats, admin panel, rate limiting | v0.6.0 |
| 6 | Hardening | Playwright E2E, Sonar, coverage ≥ 70%, Grafana, seed data, README, demo | v1.0.0 |

Backend build order per feature: Flyway migration → entity + repository (`@DataJpaTest` + Testcontainers) → DTO records + MapStruct → service (Mockito) → controller (MockMvc) → frontend API/hook/page/test → CHANGELOG, tag, deploy.

## Java 25 notes

- Virtual threads are on (`spring.threads.virtual.enabled`); JEP 491 removed synchronized pinning, so JDBC and Redis clients are safe.
- Concurrency test: `Executors.newVirtualThreadPerTaskExecutor()` + `CountDownLatch`, 100 threads on one seat.
- Records for DTOs; sealed interfaces + pattern-matching `switch` for domain outcomes (hold result, payment outcome).
- Compact object headers (JEP 519) enabled in the container to cut heap use.
- No preview features (structured concurrency is still preview in 25).
