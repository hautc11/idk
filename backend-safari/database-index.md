# Database Indexes

## 1. What I did

- Learned the **purpose of an index**: speeding up search/query operations, avoiding full table scans on large datasets.
- Learned the two common **index structures**: B-tree (balanced tree, supports fast lookups, inserts, and range queries) and Hash table (fast for exact-match queries, not suitable for range queries).
- Distinguished **Primary Index** (auto-created with a PK) vs **Secondary Index** (manually added on other columns).
- Learned the **trade-offs** of indexing: faster reads vs. slower writes, plus extra disk space (space overhead).
- Learned the different **types** of indexes: Single-Column, Composite (Multi-Column), Unique, Full-Text.
- Learned **when to use indexes** and some **best practices** around indexing strategy.

## 2. What differed from my initial assumptions/understanding

- **Primary Index creation isn't identical across all databases.** says "Automatically created when a PK is defined on a table (searching a record based on the PK is fast)" - this is true in the sense that a unique index is always created for the PK, but whether that index is *clustered* (i.e., the table's physical row order follows the PK) depends on the database engine. For example, in MySQL/InnoDB the PK index is clustered by default, while in PostgreSQL a PK just gets a regular unique B-tree index - the table itself isn't physically reordered by it. Worth keeping in mind when reasoning about performance across different DB engines.

- **Composite Index order matters - worth naming the underlying rule.** says "the order of columns in a composite index matters," but it's worth explicitly naming *why*: this is the **leftmost prefix rule** - a composite index on `(A, B, C)` can efficiently serve queries filtering on `A`, `(A, B)`, or `(A, B, C)`, but **not** a query filtering only on `B` or `C` alone. This detail is often the actual reason a composite index "isn't being used" in practice.

- **Full-Text Index** - correct as a concept, but it's useful to note this is a *different indexing mechanism* from B-tree/Hash (it typically uses inverted indexes internally), rather than just "another type" alongside single-column/composite/unique.

## 3. Lessons learned that I can reapply

- Before adding an index, check **query patterns first** (WHERE, JOIN, ORDER BY columns) - indexing without a real query pattern to support is wasted overhead.
- For composite indexes, always design **column order based on the leftmost prefix rule** - put the column most commonly filtered alone or first in range/equality conditions at the leftmost position.
- Favor indexing columns with **high cardinality** (many distinct values) - indexes on low-cardinality columns (e.g., a boolean flag) often give little benefit since the database may still choose a full scan.
- Be mindful of the **write-performance cost**: every INSERT/UPDATE/DELETE has to update all relevant indexes, so over-indexing a write-heavy table can hurt performance more than it helps reads.
- When troubleshooting "why isn't my index being used," check the **actual execution plan** (ties back to earlier execution-plan notes) rather than assuming the index alone guarantees performance - the optimizer may still choose not to use it depending on statistics, selectivity, or data distribution.

## 4. Composite Index vs. Covering Index

These two terms describe **different aspects** of an index, not two alternative types in the same category:

- **Composite Index** - describes the **structure**: an index built on more than one column, e.g. `INDEX(customer_id, order_date)`. It answers "*which columns is this index built on?*"`
- **Covering Index** - describes a **property relative to a specific query**: an index "covers" a query when the index alone already contains every column the query needs (both filter columns and selected columns), so the engine never has to go back to the table to fetch more data. It answers "*does this index contain everything this query needs?*"

A composite index is only a covering index for queries whose needed columns are a subset of the index's columns - for a different query it may not be covering at all.

```sql
CREATE INDEX idx_orders ON orders (customer_id, order_date);

-- Query A: needs only customer_id and order_date
SELECT customer_id, order_date FROM orders WHERE customer_id = 5;
-- → uses the composite index, AND it IS covering for Query A
--   (nothing needed beyond what's already in the index)

-- Query B: also needs total_amount
SELECT customer_id, order_date, total_amount FROM orders WHERE customer_id = 5;
-- → still uses the same composite index to filter,
--   but it is NOT covering for Query B
--   (total_amount isn't in the index, so the engine must look up the base table)
```

In the execution plan, a covering index typically shows up as `Index Only Scan` (PostgreSQL) or `Using index` (MySQL EXPLAIN) - signaling no extra table lookup was needed.

## 5. Single-Column Index vs. Multi-Column (Composite) Index - physical organization

For a **single-column index**, the index is a separate structure (typically a B-tree) where each leaf entry is a pair: `(indexed_column_value, pointer_to_row)`. The tree is sorted by that one value, and each lookup walks the tree to find the value, then follows the pointer to the actual row (in the table heap, or to the clustered index key if the table is clustered).

For a **composite/multi-column index**, it is still **one single B-tree**, not several linked single-column indexes. The difference is in the **key**: each leaf entry stores a **concatenated key made of all indexed columns, in the order they were declared**, plus one pointer to the row: `(col1_value, col2_value, col3_value, ..., pointer_to_row)`.

- The tree is sorted **hierarchically**: first by `col1`, and only *within* rows sharing the same `col1` value is it further sorted by `col2`, and so on - similar to how a phone book is sorted by last name first, then by first name within the same last name.
- This is exactly why the **leftmost prefix rule** exists: the tree is only meaningfully sorted starting from the first column, so a query filtering on `col2` alone can't binary-search this tree efficiently - it would have to scan across many unrelated `col1` groups.
- There's still only **one pointer per row** in this index, not one pointer per column - the multiple columns just make up a longer composite key, not multiple parallel indexes glued together.

