# Execution Plan

## 1. What I did?

- Learned about **execution plan**: the roadmap the database engine generates describing, step by step, how it will execute a query
- Distinguished between **Estimated Plan** (generated/predicted before the query actually runs) and **Actual Plans** (generated during or after the query execution).
- Learned about **Table Scan** and **Clustered Index Scan** : two data-retrieval methods that affect query performance.
- Distinguished between **Logical Operations - WHAT** (represent the high-level operations required by the query - describe the user's query structurally) and **Physical Operations - HOW** (represent the low-level - algorithms and execution routines used by the database engine to process the data and produce the logical result).

## 2. What differed from my initial understanding?

- *one Logical Operation can be implemented by different Physical Operations*, depending on which one the optimizer estimates to be cheapest (based on statistics, data size, available indexes, etc.).

## 3. Lesson learned áp dụng lại được

- When reading an execution plan, always **compare Estimated vs. Actual**. If the estimated row counts differ significantly from actual counts, that's a signal to check statistics or indexes first - don't rush to optimize the query before investigating this root cause.
Seeing a **Table Scan** or **Clustered Index Scan** on a large table in an execution plan is a warning sign that an appropriate index may be missing for the WHERE/JOIN conditions.
- When analyzing JOINs in an execution plan, look at the **Physical Operator** (Nested Loops / Hash Match / Merge Join), not just the logical operation:
    - Nested Loops → good when one side is small and there's a supporting index.
    - Hash Match → commonly appears when joining two large tables without a good index to join on.
    - Merge Join → efficient when both inputs are already sorted on the join key.
