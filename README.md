# TicketHub -> A springBoot project

Seat-level event ticket booking: browse events, pick exact seats, hold them for 5 minutes and pay, with **no seat ever sold twice**, even under concurrent demand.

> Status: Sprint 0 (foundation) · v0.1.0. See [CHANGELOG](CHANGELOG.md) and the [SRS](docs/srs.md).

## Stack

| Layer | Tech |
|---|---|
| API | Java 25 (LTS), Spring Boot 4.1, Spring Security, Spring Data JPA (Hibernate 7), Flyway, virtual threads |
| Data | MySQL 8 (source of truth), Redis 7.4 (seat holds, cache) |
| Web | React 19, TypeScript, Vite, Tailwind v4, shadcn/ui, TanStack Query, React Router |
| Ops | Docker Compose, GitHub Actions, Actuator + Prometheus + Grafana, Mailpit (dev email) |

## Quick start

### Without Docker (Windows)

Prerequisites: JDK 25, Node 24 and MySQL 8.0.16+ installed as a Windows service.

1. Double-click `run.bat`. The first time, it creates `.env` from `.env.example` and stops.
2. Set `DB_USERNAME` and `DB_PASSWORD` in `.env` to your MySQL login (and `MYSQL_SERVICE` if your service isn't `MySQL80`).
3. Double-click `run.bat` again. It starts MySQL if needed, opens the API and web app in their own windows, and opens the browser once the API is healthy. The `tickethub` database and schema are created on first start.

Close the "TicketHub API" and "TicketHub Web" windows to stop. Redis and Mailpit aren't needed until the features that use them land.

### With Docker

Prerequisites: Docker Desktop.

```bash
cp .env.example .env
docker compose up --build
```

| URL | What |
|---|---|
| http://localhost:5173 | Web app |
| http://localhost:8080/actuator/health | API health |
| http://localhost:8080/swagger-ui.html | API docs |
| http://localhost:8025 | Mailpit inbox |

Observability (Prometheus on :9090, Grafana on :3000): `docker compose --profile observability up`.

### Local development

```bash
docker compose up -d mysql redis mailpit      # backing services only
cd backend && ./mvnw spring-boot:run          # API on :8080 (dev profile)
cd frontend && npm install && npm run dev     # web on :5173
```

Backend tests use Testcontainers, so Docker must be running: `cd backend && ./mvnw verify`.
Frontend: `npm run lint`, `npm run typecheck`, `npm test`, `npm run build`.
Regenerate API types from a running backend: `npm run gen:types`.

## Repository layout

```
backend/    Spring Boot modular monolith (com.tickethub.{auth,user,venue,event,booking,payment,ticket,notification})
frontend/   React SPA (src/{app,api,features,components,lib,pages,types})
docs/       SRS, architecture, runbook
ops/        Prometheus config
```

## Architecture

_Diagram and seat-hold design arrive with Sprint 3. Summary: holds are claimed in Redis with `SET NX EX 300`; confirmation commits to MySQL inside one transaction guarded by an optimistic-lock `@Version` column._

## Hosting (later)

Vercel (web), Render or Railway (API, Docker), a managed MySQL (e.g. Aiven or TiDB Cloud), Upstash (Redis), Brevo (email), Razorpay test mode. Free tiers sleep when idle, so the first request after a pause is slow.
