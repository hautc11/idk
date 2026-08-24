CREATE TABLE customers (
    id BIGSERIAL PRIMARY KEY,
    email TEXT NOT NULL,
    country TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE products (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    price NUMERIC(10,2) NOT NULL
);

CREATE TABLE orders (
    id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(id),
    status TEXT NOT NULL,          -- 'pending','paid','shipped','cancelled'
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    total NUMERIC(10,2) NOT NULL
);

CREATE TABLE order_items (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(id),
    product_id BIGINT NOT NULL REFERENCES products(id),
    quantity INT NOT NULL,
    unit_price NUMERIC(10,2) NOT NULL
);

INSERT INTO customers (email, country, created_at)
SELECT 'user' || g || '@example.com',
       (ARRAY['VN','US','SG','JP','TH'])[floor(random()*5+1)],
       now() - (random() * interval '730 days')
FROM generate_series(1, 50000) g;

INSERT INTO products (name, category, price)
SELECT 'Product ' || g,
       (ARRAY['electronics','fashion','home','books','toys'])[floor(random()*5+1)],
       round((random()*500 + 5)::numeric, 2)
FROM generate_series(1, 5000) g;

INSERT INTO orders (customer_id, status, created_at, total)
SELECT floor(random()*50000+1),
       (ARRAY['pending','paid','shipped','cancelled'])[floor(random()*4+1)],
       now() - (random() * interval '730 days'),
       round((random()*1000 + 10)::numeric, 2)
FROM generate_series(1, 1000000) g;

INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT floor(random()*1000000+1),
       floor(random()*5000+1),
       floor(random()*5+1),
       round((random()*500 + 5)::numeric, 2)
FROM generate_series(1, 3000000) g;

ANALYZE;

EXPLAIN ANALYZE
SELECT id, customer_id, total, created_at
FROM orders
WHERE status = 'paid'
ORDER BY created_at DESC
LIMIT 50;

CREATE INDEX idx_orders_status_created_at 
ON orders (status, created_at DESC);

EXPLAIN ANALYZE
SELECT o.id, o.created_at, p.name, oi.quantity, oi.unit_price
FROM orders o
JOIN order_items oi ON oi.order_id = o.id
JOIN products p ON p.id = oi.product_id
WHERE o.customer_id = 777;

CREATE INDEX idx_orders_customer_id ON orders (customer_id);
CREATE INDEX idx_order_items_order_id ON order_items (order_id);

SHOW work_mem;

SET work_mem = '64MB';
EXPLAIN ANALYZE
SELECT date_trunc('month', created_at) AS month, SUM(total) AS revenue
FROM orders
WHERE created_at >= '2024-01-01' AND status = 'paid'
GROUP BY 1
ORDER BY 1;

CREATE INDEX idx_customers_email ON customers (email);

CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_customers_email_trgm 
ON customers USING GIN (email gin_trgm_ops);

EXPLAIN ANALYZE
SELECT * FROM customers WHERE email ILIKE '%user1234%';

CREATE INDEX idx_customers_country ON customers (country);

EXPLAIN ANALYZE
SELECT c.id, c.email,
  (SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.id) AS order_count
FROM customers c
WHERE c.country = 'VN';

CREATE INDEX idx_orders_created_at ON orders (created_at);

EXPLAIN ANALYZE
SELECT * FROM orders 
WHERE created_at >= '2024-06-01' AND created_at < '2024-06-02';