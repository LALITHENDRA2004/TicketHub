# Changelog

All notable changes to this project are documented here. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versions follow [SemVer](https://semver.org/).

## [Unreleased]

## [0.1.0] - Sprint 0: Foundation

### Added
- Spring Boot 4.1 API on Java 25 with virtual threads, structured JSON logs, correlation-id filter and ProblemDetail errors.
- Flyway `V1__init.sql` with the full TicketHub schema.
- Actuator health, info and Prometheus endpoints; OpenAPI UI at `/swagger-ui.html`.
- React 19 + TypeScript + Vite frontend with Tailwind v4, shadcn/ui, TanStack Query and React Router.
- `docker compose up` for Postgres 17, Redis 7.4, Mailpit, API and web (Prometheus + Grafana via the `observability` profile).
- GitHub Actions CI for backend and frontend, Dependabot.
