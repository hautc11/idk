# Safe Migrations with Rollback: Beginner BE Foundations

A migration is a versioned, repeatable script that changes a database schema (adding a column, creating a table, adding an index, etc.) so the change can be applied consistently across environments (local, staging, production) and reverted if something goes wrong.

## 1. Migration tools

Most frameworks use a migration tool that tracks which scripts have already run, in what order, using a version table in the database itself.

- Node/Go projects: golang-migrate, node-pg-migrate
- Java/Kotlin projects: Flyway, Liquibase
- Python projects: Alembic

Each migration typically has two parts: an "up" script (apply the change) and a "down" script (revert it). The down script is what makes rollback possible.

## 2. Transactional DDL in Postgres

Postgres allows DDL statements (CREATE TABLE, ALTER TABLE, etc.) to run inside a transaction. If a migration has multiple steps and one fails partway through, the whole transaction rolls back automatically, so the schema never ends up half-changed.

This is different from MySQL, where DDL statements auto-commit and cannot be rolled back mid-transaction. A beginner coming from a MySQL background should be aware that Postgres migrations can safely wrap multiple DDL statements in one transaction block.

## 3. Backward-compatible migration (Expand-Contract pattern)

Never change a column's meaning or remove it in a single migration while the old application code is still running against it. Instead, migrate in stages:

1. **Expand:** add the new column or table alongside the old one. Old code keeps working unchanged.
2. **Migrate:** backfill data and update application code to read/write the new column.
3. **Contract:** once all code has switched over and it's confirmed safe, remove the old column in a later migration.

This avoids downtime and avoids a scenario where a deploy of new code and a migration have to happen at the exact same instant.

## 4. ALTER TABLE lock behavior

Some `ALTER TABLE` operations in Postgres take an `ACCESS EXCLUSIVE` lock, which blocks all reads and writes to the table for the duration of the operation. On a large, actively used table, this can cause a production outage even for what looks like a "simple" change.

Operations that are usually fast and safe (metadata-only changes):
- Adding a column with no default value, or with a default that doesn't require rewriting existing rows (Postgres 11+)
- Dropping a column

Operations that can lock the table for a long time on large tables:
- Adding a column with a `NOT NULL` constraint and a volatile default (forces a full table rewrite in older Postgres versions)
- Adding a foreign key constraint (must scan and validate all existing rows)
- Changing a column's data type

## 5. CREATE INDEX CONCURRENTLY

By default, `CREATE INDEX` takes a lock that blocks writes to the table while the index is being built. On a large table, this can take minutes and blocks all inserts/updates during that time.

`CREATE INDEX CONCURRENTLY` builds the index without blocking writes, at the cost of taking longer and not being able to run inside a transaction block.

## 6. Rollback strategy

- Every migration should have a corresponding down-script that reverses its effect.
- A rollback is only truly safe if the down-script doesn't lose data that was written after the up-script ran (e.g., dropping a column you just added, but data may have already been written to it).
- For destructive changes (dropping a column or table), consider a "soft" rollback plan: rename the column instead of dropping it immediately, keep it for a grace period, then remove it in a later migration once you're confident it's safe.

---

## Examples

### Example 1: Identifying a risky ALTER TABLE

You need to add a `status` column to a `users` table with 10 million rows, and the application requires every row to have a `status` value.

Migration A:
```sql
ALTER TABLE users ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'active';
```

**Solution:** split into a safer, staged approach.

```sql
-- Step 1: add the column as nullable, no default
ALTER TABLE users ADD COLUMN status VARCHAR(20);

-- Step 2: backfill in small batches (application code or a separate script), not in one giant UPDATE
UPDATE users SET status = 'active' WHERE status IS NULL AND id BETWEEN 1 AND 100000;
-- repeat in batches...

-- Step 3: once fully backfilled, add the NOT NULL constraint
ALTER TABLE users ALTER COLUMN status SET NOT NULL;
```

**Why:** in older Postgres versions, adding a column with a `NOT NULL` and a constant default forces a full table rewrite, holding a heavy lock for the entire duration on a 10-million-row table, this can lock out the whole application for minutes. Splitting into nullable-add, batched backfill, then constrain avoids a single long-held lock and lets you pause between batches if something looks wrong.

### Example 2: Identifying an unsafe rollback

A migration renames `orders.total` to `orders.total_amount`:

```sql
-- up
ALTER TABLE orders RENAME COLUMN total TO total_amount;

-- down
ALTER TABLE orders RENAME COLUMN total_amount TO total;
```

This gets deployed, but the old application code (which still writes to `orders.total`) is still running on some servers during the rollout, and it errors out because the column no longer exists.

**Solution:** apply Expand-Contract instead of a direct rename.

```sql
-- Migration 1 (expand): add the new column, keep the old one
ALTER TABLE orders ADD COLUMN total_amount NUMERIC;
UPDATE orders SET total_amount = total;

-- Deploy application code that writes to both columns, reads from total_amount

-- Migration 2 (contract, later, after confirming all instances are updated):
ALTER TABLE orders DROP COLUMN total;
```

**Why:** a direct rename is not backward-compatible: any code still referencing the old column name breaks the instant the migration runs, even if the rollback script exists, because the failure happens in the window between deploying the migration and deploying the new code, not after. Splitting into expand and contract phases means the old code keeps working throughout the middle stage of the rollout.

### Example 3: Choosing between CREATE INDEX and CREATE INDEX CONCURRENTLY

You need to add an index on `orders.customer_id` in production, where the `orders` table receives constant inserts throughout the day.

```sql
-- Option A
CREATE INDEX idx_orders_customer_id ON orders (customer_id);

-- Option B
CREATE INDEX CONCURRENTLY idx_orders_customer_id ON orders (customer_id);
```

**Solution:** use Option B (`CONCURRENTLY`), and run it outside of a transaction block, since Postgres doesn't allow `CREATE INDEX CONCURRENTLY` inside one.

**Why:** Option A takes a lock that blocks writes to `orders` for as long as the index build takes, which could be minutes on a large table, causing failed or delayed requests during that window. Option B avoids blocking writes at the cost of a longer build time and slightly more complexity (it can leave behind an invalid index if it fails partway, which needs to be dropped and retried).

---

*This file is part of the PostgreSQL self-study roadmap, Step 2: Safe migrations with rollback.*
