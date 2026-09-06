# Data Normalization: 1NF, 2NF, 3NF, BCNF

Normalization is the process of organizing a schema to reduce duplication and prevent data inconsistency. Each Normal Form builds on and tightens the rules of the one before it.

## 1NF (First Normal Form)
- Every column must hold **a single atomic value**, not a list or multiple values crammed together.
- Wrong: a `phone_numbers` column containing `"0901111111, 0902222222"`
- Correct: split into a separate table `user_phones`, one row per phone number.

## 2NF (Second Normal Form)
- Must already satisfy 1NF, and **every non-key column must depend on the entire primary key** (this rule applies when the primary key is a composite key).
- Example violation: table `enrollments (student_id, course_id, student_name)`: `student_name` only depends on `student_id`, not on the full primary key, so it should be moved into a separate `students` table.

## 3NF (Third Normal Form)
- Must already satisfy 2NF, and **no non-key column may depend on another non-key column** (no transitive dependency).
- Example violation: table `orders (id, user_id, user_email)`: `user_email` depends on `user_id`, not on the primary key `id`, so it should be removed from `orders` and retrieved via a join with `users`.

## BCNF (Boyce-Codd Normal Form)
- A stricter version of 3NF: **for every functional dependency X → Y in the table, X must be a candidate key** (a column or column set that could serve as the primary key).
- 3NF allows one small exception that BCNF does not: a non-key column may still determine part of the primary key. BCNF removes that exception entirely.
- Example violation: table `class_schedule (student_id, subject, teacher)` with the business rule "each teacher teaches only one subject." The primary key is `(student_id, subject)`, but there's a functional dependency `teacher → subject` (knowing the teacher tells you the subject), and `teacher` is not a candidate key, so this violates BCNF even though it satisfies 3NF.
- Fix: split into two tables: `teachers (teacher, subject)` and `enrollments (student_id, teacher)`.
- **Note:** BCNF only differs from 3NF in cases with overlapping candidate keys (fairly rare in practice). Beginners should master 3NF first; BCNF is deeper theoretical ground on functional dependencies.

**General rule of thumb:** *"each piece of information should live in exactly one place, and every column must depend on the whole primary key, nothing more, nothing less."* If you see data repeated across rows, or one value that needs updating in multiple places, that's a sign more normalization is needed.

---

## Examples

### Example 1: Spotting a 1NF violation

| order_id | customer_name | products |
|---|---|---|
| 1 | John Smith | T-shirt, Jeans, Cap |
| 2 | Jane Doe | Shoes |

**Solution:**

| order_id | customer_name |
|---|---|
| 1 | John Smith |
| 2 | Jane Doe |

| order_id | product |
|---|---|
| 1 | T-shirt |
| 1 | Jeans |
| 1 | Cap |
| 2 | Shoes |

**Why:** the `products` column packs multiple values into one field, violating atomicity. Splitting it into a separate `order_products` table with one product per row makes each field atomic, and lets you query, filter, or count individual products without string parsing.

---

### Example 2: Spotting a 2NF violation

Table `order_items` with primary key `(order_id, product_id)`:

| order_id | product_id | product_name | quantity | unit_price |
|---|---|---|---|---|

**Solution:** split into two tables.

`products (product_id, product_name, unit_price)`

`order_items (order_id, product_id, quantity)`

**Why:** `product_name` and `unit_price` depend only on `product_id`, not on the full composite key `(order_id, product_id)`. Keeping them in `order_items` means the same product's name and price get duplicated across every order line, and if the price changes, every historical row would have to be updated (or worse, would silently disagree with each other).

---

### Example 3: Spotting a 3NF violation

Table `employees`:

| employee_id | employee_name | department_id | department_name | department_location |
|---|---|---|---|---|

**Solution:** split into two tables.

`departments (department_id, department_name, department_location)`

`employees (employee_id, employee_name, department_id)`

**Why:** `department_name` and `department_location` depend on `department_id`, not directly on the primary key `employee_id`, this is a transitive dependency (`employee_id → department_id → department_name`). Without splitting, renaming a department requires updating every employee row in that department, risking inconsistency.

---

### Example 4: Spotting a BCNF violation

Table `course_bookings (room, time_slot, course)` with primary key `(room, time_slot)`, and the business rule: "each course is always held in exactly one fixed room."

**Solution:**

1. Functional dependencies present: `(room, time_slot) → course` (the primary key determines the course), and additionally `course → room` (each course always maps to one room).
2. The table satisfies 3NF (there's no non-key column depending on another non-key column outside the key), but it does **not** satisfy BCNF, because in `course → room`, `course` is not a candidate key.
3. Split into:

   `course_rooms (course, room)`

   `bookings (course, time_slot)`

**Why:** without splitting, if a course's room needs to change, you'd have to update every time-slot row for that course; miss one and the data becomes inconsistent (the same course pointing to two different rooms across rows).

---

### Example 5: Full walkthrough

Table `invoice (invoice_id, customer_id, customer_address, product_id, product_name, quantity, invoice_date)`.

**Solution:**

Step 1, 1NF: all columns are already atomic, no repeating groups, so 1NF is satisfied as-is.

Step 2, 2NF: choose primary key `(invoice_id, product_id)` (an invoice can list multiple products). `customer_id`, `customer_address`, and `invoice_date` depend only on `invoice_id`, not on the full key, so split them out:

`invoices (invoice_id, customer_id, customer_address, invoice_date)`

`invoice_items (invoice_id, product_id, quantity)`

Step 3, 3NF: in `invoices`, `customer_address` depends on `customer_id`, not on `invoice_id` directly (transitive dependency), so split further:

`customers (customer_id, customer_address)`

`invoices (invoice_id, customer_id, invoice_date)`

`invoice_items (invoice_id, product_id, quantity)`

Also, `product_name` in the original table depends on `product_id`, so it belongs in its own table:

`products (product_id, product_name)`

**Why each step matters:** each split removes one specific kind of duplication risk. Keeping the customer's address inline with every invoice means it's repeated on every purchase and can drift out of sync if the customer moves; keeping the product name inline with every line item means renaming a product would require rewriting every historical invoice line. The final structure (`customers`, `invoices`, `invoice_items`, `products`) stores each fact exactly once.

---

*This file is part of the PostgreSQL self-study roadmap, Step 1: Data normalization.*
