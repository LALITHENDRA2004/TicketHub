# Changelog

All notable changes to this project are documented here. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versions follow [SemVer](https://semver.org/).

## [Unreleased]

### Added
- `run.bat`: one double-click starts the local MySQL service, the API and the web app without Docker.

### Changed
- Database switched from PostgreSQL 17 to MySQL 8 (driver, Flyway module, `V1__init.sql`, docker compose, Testcontainers).

## [0.1.0] - Sprint 0: Foundation

### Added
- Spring Boot 4.1 API on Java 25 with virtual threads, structured JSON logs, correlation-id filter and ProblemDetail errors.
- Flyway `V1__init.sql` with the full TicketHub schema.
- Actuator health, info and Prometheus endpoints; OpenAPI UI at `/swagger-ui.html`.
- React 19 + TypeScript + Vite frontend with Tailwind v4, shadcn/ui, TanStack Query and React Router.
- `docker compose up` for Postgres 17, Redis 7.4, Mailpit, API and web (Prometheus + Grafana via the `observability` profile).
- GitHub Actions CI for backend and frontend, Dependabot.
