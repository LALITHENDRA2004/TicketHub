# Runbook

Short, actionable fixes for production incidents. Fill in each section as the feature ships.

## Payment webhook failing (Sprint 4)
## Redis down (Sprint 3)
## DB migration failed
1. Check API logs for the Flyway error and the failing version.
2. Fix forward with a new `V<n+1>__fix.sql`; never edit an applied migration.
3. If a migration half-applied on Postgres, it rolled back (transactional DDL): fix and redeploy.
