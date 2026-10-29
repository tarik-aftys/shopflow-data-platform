






CREATE EXTENSION IF NOT EXISTS "uuid-ossp";




CREATE TABLE categories (
    category_id   SERIAL       PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description   TEXT,
    parent_category_id INTEGER  REFERENCES categories(category_id),
    created_at    TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMP    NOT NULL DEFAULT NOW()
);




CREATE TABLE brands (
    brand_id   SERIAL       PRIMARY KEY,
    brand_name VARCHAR(100) NOT NULL UNIQUE,
    logo_url   VARCHAR(500),
    country    VARCHAR(100),
    created_at TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP    NOT NULL DEFAULT NOW()
);




CREATE TABLE products (
    product_id  SERIAL        PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    sku          VARCHAR(50)  NOT NULL UNIQUE,
    description  TEXT,
    unit_price   NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0),
    cost_price   NUMERIC(12,2) CHECK (cost_price >= 0),
    weight_kg    NUMERIC(8,3),
    category_id  INTEGER      NOT NULL REFERENCES categories(category_id),
    brand_id     INTEGER      REFERENCES brands(brand_id),
    is_active    BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_brand    ON products(brand_id);
CREATE INDEX idx_products_sku      ON products(sku);




CREATE TABLE customers (
    customer_id SERIAL       PRIMARY KEY,
    first_name  VARCHAR(100) NOT NULL,
    last_name   VARCHAR(100) NOT NULL,
    email       VARCHAR(255) NOT NULL UNIQUE,
    phone       VARCHAR(30),
    date_of_birth DATE,
    gender      VARCHAR(10)  CHECK (gender IN ('Male', 'Female', 'Other')),
    created_at  TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_customers_email ON customers(email);




CREATE TABLE addresses (
    address_id    SERIAL       PRIMARY KEY,
    customer_id   INTEGER      NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    address_type  VARCHAR(20)  NOT NULL CHECK (address_type IN ('billing', 'shipping')),
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    city          VARCHAR(100) NOT NULL,
    state         VARCHAR(100),
    postal_code   VARCHAR(20)  NOT NULL,
    country       VARCHAR(100) NOT NULL DEFAULT 'United States',
    is_default    BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_addresses_customer ON addresses(customer_id);




CREATE TABLE orders (
    order_id     SERIAL       PRIMARY KEY,
    order_number VARCHAR(30)  NOT NULL UNIQUE,
    customer_id  INTEGER      NOT NULL REFERENCES customers(customer_id),
    order_date   TIMESTAMP    NOT NULL DEFAULT NOW(),
    status       VARCHAR(30)  NOT NULL DEFAULT 'pending'
                              CHECK (status IN ('pending', 'confirmed', 'processing',
                                                 'shipped', 'delivered', 'cancelled', 'refunded')),
    shipping_address_id INTEGER REFERENCES addresses(address_id),
    billing_address_id  INTEGER REFERENCES addresses(address_id),
    subtotal     NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (subtotal >= 0),
    tax_amount   NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (tax_amount >= 0),
    shipping_cost NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (shipping_cost >= 0),
    discount_amount NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),
    total_amount NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (total_amount >= 0),
    notes        TEXT,
    created_at   TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_orders_customer   ON orders(customer_id);
CREATE INDEX idx_orders_date       ON orders(order_date);
CREATE INDEX idx_orders_status     ON orders(status);




CREATE TABLE order_items (
    order_item_id SERIAL       PRIMARY KEY,
    order_id      INTEGER      NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id    INTEGER      NOT NULL REFERENCES products(product_id),
    quantity      INTEGER      NOT NULL CHECK (quantity > 0),
    unit_price    NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0),
    discount_pct  NUMERIC(5,2) NOT NULL DEFAULT 0 CHECK (discount_pct >= 0 AND discount_pct <= 100),
    line_total    NUMERIC(12,2) NOT NULL CHECK (line_total >= 0),
    created_at    TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_order_items_order   ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);




CREATE TABLE payments (
    payment_id     SERIAL       PRIMARY KEY,
    order_id       INTEGER      NOT NULL REFERENCES orders(order_id),
    payment_method VARCHAR(50)  NOT NULL
                               CHECK (payment_method IN ('credit_card', 'debit_card', 'paypal',
                                                          'bank_transfer', 'gift_card', 'crypto')),
    payment_status VARCHAR(30)  NOT NULL DEFAULT 'pending'
                               CHECK (payment_status IN ('pending', 'completed', 'failed', 'refunded')),
    amount         NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    transaction_id VARCHAR(100),
    payment_date   TIMESTAMP    NOT NULL DEFAULT NOW(),
    created_at     TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_payments_order ON payments(order_id);




CREATE TABLE shipping (
    shipping_id     SERIAL       PRIMARY KEY,
    order_id        INTEGER      NOT NULL REFERENCES orders(order_id),
    carrier         VARCHAR(100) NOT NULL,
    tracking_number VARCHAR(100),
    shipping_method VARCHAR(50)  NOT NULL
                                CHECK (shipping_method IN ('standard', 'express', 'overnight', 'pickup')),
    shipping_status VARCHAR(30)  NOT NULL DEFAULT 'pending'
                                CHECK (shipping_status IN ('pending', 'in_transit', 'out_for_delivery',
                                                            'delivered', 'returned')),
    estimated_delivery DATE,
    actual_delivery    DATE,
    shipped_date       TIMESTAMP,
    created_at         TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_shipping_order ON shipping(order_id);






INSERT INTO categories (category_name, description, parent_category_id) VALUES
    ('Electronics',       'Electronic devices and accessories', NULL),
    ('Clothing',          'Apparel and fashion items',          NULL),
    ('Home & Kitchen',    'Home goods and kitchen supplies',    NULL),
    ('Sports & Outdoors', 'Sports equipment and outdoor gear',  NULL),
    ('Books',             'Books and publications',             NULL),
    ('Smartphones',       'Mobile phones and accessories',      1),
    ('Laptops',           'Laptop computers',                   1),
    ('Headphones',        'Audio headphones and earbuds',       1),
    ('Men''s Clothing',   'Men''s apparel',                     2),
    ('Women''s Clothing', 'Women''s apparel',                   2);


INSERT INTO brands (brand_name, country) VALUES
    ('TechNova',    'United States'),
    ('UrbanStyle',  'Italy'),
    ('HomeComfort', 'Germany'),
    ('SportPeak',   'United States'),
    ('ReadWell',    'United Kingdom'),
    ('ElectroPro',  'Japan'),
    ('FashionPlus', 'France'),
    ('KitchenAid',  'United States');


INSERT INTO products (product_name, sku, description, unit_price, cost_price, weight_kg, category_id, brand_id) VALUES
    ('Smartphone X Pro',        'TECH-SP-001', 'Flagship smartphone with 6.7" display',   999.99, 650.00, 0.189, 6, 1),
    ('Laptop UltraBook 15',     'TECH-LT-001', '15" ultrabook with 16GB RAM, 512GB SSD',  1299.99, 850.00, 1.800, 7, 1),
    ('Wireless Noise-Cancel Headphones', 'TECH-HP-001', 'Premium ANC headphones', 349.99, 180.00, 0.254, 8, 6),
    ('Men''s Classic Polo',     'CLO-MP-001',  'Cotton polo shirt, various colors',        59.99, 22.00, 0.250, 9, 2),
    ('Women''s Running Jacket', 'CLO-WJ-001',  'Lightweight waterproof running jacket',    89.99, 35.00, 0.350, 10, 7),
    ('Stainless Steel Cookware Set', 'HK-CW-001', '10-piece stainless steel cookware',    199.99, 95.00, 8.500, 3, 8),
    ('Yoga Mat Premium',        'SPT-YM-001',  'Non-slip yoga mat 6mm thick',              39.99, 12.00, 1.200, 4, 4),
    ('Trail Running Shoes',     'SPT-RS-001',  'All-terrain trail running shoes',          129.99, 55.00, 0.680, 4, 4),
    ('Data Engineering Guide',  'BK-DE-001',   'Complete guide to modern data engineering', 49.99, 15.00, 0.750, 5, 5),
    ('Smart Watch Series 5',    'TECH-SW-001', 'Fitness & health tracking smartwatch',     279.99, 140.00, 0.045, 6, 1),
    ('Bluetooth Speaker',       'TECH-BS-001', 'Portable waterproof bluetooth speaker',    79.99, 35.00, 0.540, 1, 6),
    ('Men''s Slim Fit Jeans',   'CLO-MJ-001',  'Premium denim slim-fit jeans',             79.99, 30.00, 0.650, 9, 2),
    ('Coffee Maker Deluxe',     'HK-CM-001',   '12-cup programmable coffee maker',         89.99, 40.00, 3.200, 3, 8),
    ('Resistance Bands Set',    'SPT-RB-001',  '5-piece resistance band set',              24.99, 8.00, 0.350, 4, 4),
    ('Python Programming Book', 'BK-PY-001',   'Advanced Python programming handbook',     44.99, 12.00, 0.680, 5, 5);


INSERT INTO customers (first_name, last_name, email, phone, date_of_birth, gender) VALUES
    ('Alice',   'Johnson',   'alice.johnson@email.com',   '+1-555-0101', '1990-03-15', 'Female'),
    ('Bob',     'Smith',     'bob.smith@email.com',       '+1-555-0102', '1985-07-22', 'Male'),
    ('Carol',   'Williams',  'carol.williams@email.com',  '+1-555-0103', '1992-11-08', 'Female'),
    ('David',   'Brown',     'david.brown@email.com',     '+1-555-0104', '1988-01-30', 'Male'),
    ('Emma',    'Davis',     'emma.davis@email.com',       '+1-555-0105', '1995-06-12', 'Female'),
    ('Frank',   'Miller',    'frank.miller@email.com',    '+1-555-0106', '1982-09-25', 'Male'),
    ('Grace',   'Wilson',    'grace.wilson@email.com',    '+1-555-0107', '1993-04-18', 'Female'),
    ('Henry',   'Moore',     'henry.moore@email.com',     '+1-555-0108', '1991-12-03', 'Male'),
    ('Ivy',     'Taylor',    'ivy.taylor@email.com',      '+1-555-0109', '1987-08-14', 'Female'),
    ('Jack',    'Anderson',  'jack.anderson@email.com',   '+1-555-0110', '1994-02-28', 'Male'),
    ('Karen',   'Thomas',    'karen.thomas@email.com',    '+1-555-0111', '1989-05-20', 'Female'),
    ('Leo',     'Jackson',   'leo.jackson@email.com',     '+1-555-0112', '1996-10-07', 'Male'),
    ('Mia',     'White',     'mia.white@email.com',       '+1-555-0113', '1991-01-16', 'Female'),
    ('Noah',    'Harris',    'noah.harris@email.com',     '+1-555-0114', '1986-07-09', 'Male'),
    ('Olivia',  'Martin',    'olivia.martin@email.com',   '+1-555-0115', '1993-11-22', 'Female');


INSERT INTO addresses (customer_id, address_type, address_line1, city, state, postal_code, country, is_default) VALUES
    (1,  'shipping', '123 Elm Street',       'New York',      'NY', '10001', 'United States', TRUE),
    (1,  'billing',  '123 Elm Street',       'New York',      'NY', '10001', 'United States', TRUE),
    (2,  'shipping', '456 Oak Avenue',       'Los Angeles',   'CA', '90001', 'United States', TRUE),
    (3,  'shipping', '789 Pine Road',        'Chicago',       'IL', '60601', 'United States', TRUE),
    (4,  'shipping', '321 Maple Drive',      'Houston',       'TX', '77001', 'United States', TRUE),
    (5,  'shipping', '654 Cedar Lane',       'Phoenix',       'AZ', '85001', 'United States', TRUE),
    (6,  'shipping', '987 Birch Boulevard',  'Philadelphia',  'PA', '19101', 'United States', TRUE),
    (7,  'shipping', '147 Walnut Court',     'San Antonio',   'TX', '78201', 'United States', TRUE),
    (8,  'shipping', '258 Spruce Way',       'San Diego',     'CA', '92101', 'United States', TRUE),
    (9,  'shipping', '369 Ash Place',        'Dallas',        'TX', '75201', 'United States', TRUE),
    (10, 'shipping', '480 Willow Street',    'San Jose',      'CA', '95101', 'United States', TRUE),
    (11, 'shipping', '591 Poplar Avenue',    'Austin',        'TX', '73301', 'United States', TRUE),
    (12, 'shipping', '602 Chestnut Road',    'Jacksonville',  'FL', '32099', 'United States', TRUE),
    (13, 'shipping', '713 Hickory Lane',     'San Francisco', 'CA', '94101', 'United States', TRUE),
    (14, 'shipping', '824 Cypress Drive',    'Columbus',      'OH', '43085', 'United States', TRUE),
    (15, 'shipping', '935 Redwood Court',    'Charlotte',     'NC', '28201', 'United States', TRUE);


INSERT INTO orders (order_number, customer_id, order_date, status, shipping_address_id, billing_address_id, subtotal, tax_amount, shipping_cost, discount_amount, total_amount) VALUES
    ('ORD-2024-00001', 1,  '2024-01-05 10:30:00', 'delivered',  1,  2,  999.99,  80.00,  0.00,  0.00,  1079.99),
    ('ORD-2024-00002', 2,  '2024-01-12 14:15:00', 'delivered',  3,  3,  1359.98, 108.80, 12.99, 0.00,  1481.77),
    ('ORD-2024-00003', 3,  '2024-01-20 09:45:00', 'delivered',  4,  4,  89.98,   7.20,   5.99,  0.00,  103.17),
    ('ORD-2024-00004', 4,  '2024-02-03 16:00:00', 'delivered',  5,  5,  199.99,  16.00,  0.00,  20.00, 195.99),
    ('ORD-2024-00005', 5,  '2024-02-14 11:20:00', 'delivered',  6,  6,  349.99,  28.00,  0.00,  0.00,  377.99),
    ('ORD-2024-00006', 1,  '2024-02-28 13:50:00', 'delivered',  1,  2,  129.98,  10.40,  5.99,  0.00,  146.37),
    ('ORD-2024-00007', 6,  '2024-03-05 08:30:00', 'delivered',  7,  7,  1299.99, 104.00, 0.00,  0.00,  1403.99),
    ('ORD-2024-00008', 7,  '2024-03-15 17:45:00', 'delivered',  8,  8,  94.98,   7.60,   5.99,  0.00,  108.57),
    ('ORD-2024-00009', 8,  '2024-03-22 10:10:00', 'delivered',  9,  9,  279.99,  22.40,  0.00,  0.00,  302.39),
    ('ORD-2024-00010', 3,  '2024-04-01 12:00:00', 'delivered',  4,  4,  1049.98, 84.00,  0.00,  50.00, 1083.98),
    ('ORD-2024-00011', 9,  '2024-04-10 15:30:00', 'delivered',  10, 10, 169.98,  13.60,  5.99,  0.00,  189.57),
    ('ORD-2024-00012', 10, '2024-04-18 09:00:00', 'delivered',  11, 11, 79.99,   6.40,   5.99,  0.00,  92.38),
    ('ORD-2024-00013', 2,  '2024-05-02 14:20:00', 'delivered',  3,  3,  449.98,  36.00,  0.00,  0.00,  485.98),
    ('ORD-2024-00014', 11, '2024-05-15 11:45:00', 'delivered',  12, 12, 89.99,   7.20,   5.99,  0.00,  103.18),
    ('ORD-2024-00015', 12, '2024-05-28 16:30:00', 'delivered',  13, 13, 259.98,  20.80,  0.00,  0.00,  280.78),
    ('ORD-2024-00016', 5,  '2024-06-05 10:00:00', 'delivered',  6,  6,  1299.99, 104.00, 0.00,  100.00,1303.99),
    ('ORD-2024-00017', 13, '2024-06-12 13:15:00', 'delivered',  14, 14, 139.98,  11.20,  5.99,  0.00,  157.17),
    ('ORD-2024-00018', 14, '2024-06-20 08:45:00', 'delivered',  15, 15, 524.98,  42.00,  0.00,  0.00,  566.98),
    ('ORD-2024-00019', 4,  '2024-07-03 15:00:00', 'delivered',  5,  5,  79.99,   6.40,   5.99,  0.00,  92.38),
    ('ORD-2024-00020', 15, '2024-07-10 12:30:00', 'delivered',  16, 16, 999.99,  80.00,  0.00,  0.00,  1079.99),
    ('ORD-2024-00021', 1,  '2024-07-18 09:20:00', 'delivered',  1,  2,  349.99,  28.00,  0.00,  35.00, 342.99),
    ('ORD-2024-00022', 7,  '2024-08-01 14:00:00', 'delivered',  8,  8,  199.99,  16.00,  0.00,  0.00,  215.99),
    ('ORD-2024-00023', 8,  '2024-08-12 11:40:00', 'delivered',  9,  9,  1649.98, 132.00, 0.00,  0.00,  1781.98),
    ('ORD-2024-00024', 6,  '2024-08-25 16:15:00', 'shipped',    7,  7,  89.99,   7.20,   5.99,  0.00,  103.18),
    ('ORD-2024-00025', 10, '2024-09-03 10:30:00', 'shipped',    11, 11, 379.98,  30.40,  0.00,  0.00,  410.38),
    ('ORD-2024-00026', 13, '2024-09-15 13:00:00', 'processing', 14, 14, 129.99,  10.40,  5.99,  0.00,  146.38),
    ('ORD-2024-00027', 11, '2024-09-22 08:50:00', 'processing', 12, 12, 44.99,   3.60,   5.99,  0.00,  54.58),
    ('ORD-2024-00028', 9,  '2024-10-01 15:20:00', 'confirmed',  10, 10, 999.99,  80.00,  0.00,  0.00,  1079.99),
    ('ORD-2024-00029', 14, '2024-10-08 12:10:00', 'pending',    15, 15, 59.99,   4.80,   5.99,  0.00,  70.78),
    ('ORD-2024-00030', 12, '2024-10-15 09:30:00', 'pending',    13, 13, 279.99,  22.40,  0.00,  0.00,  302.39);


INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount_pct, line_total) VALUES
    
    (1,  1,  1, 999.99, 0,  999.99),
    
    (2,  2,  1, 1299.99, 0, 1299.99),
    (2,  4,  1, 59.99,   0, 59.99),
    
    (3,  7,  1, 39.99,   0, 39.99),
    (3,  9,  1, 49.99,   0, 49.99),
    
    (4,  6,  1, 199.99,  10, 179.99),
    
    (5,  3,  1, 349.99,  0, 349.99),
    
    (6,  8,  1, 129.99,  0, 129.99),
    (6,  7,  1, 39.99,   0, 39.99),  
    
    (7,  2,  1, 1299.99, 0, 1299.99),
    
    (8,  4,  1, 59.99,   0, 59.99),
    (8,  14, 1, 24.99,   0, 24.99),
    
    (9,  10, 1, 279.99,  0, 279.99),
    
    (10, 1,  1, 999.99,  5, 949.99),
    (10, 9,  1, 49.99,   0, 49.99),
    
    (11, 8,  1, 129.99,  0, 129.99),
    (11, 7,  1, 39.99,   0, 39.99),
    
    (12, 11, 1, 79.99,   0, 79.99),
    
    (13, 3,  1, 349.99,  0, 349.99),
    (13, 9,  1, 49.99,   0, 49.99),
    
    (14, 5,  1, 89.99,   0, 89.99),
    
    (15, 6,  1, 199.99,  0, 199.99),
    (15, 4,  1, 59.99,   0, 59.99),
    
    (16, 2,  1, 1299.99, 0, 1299.99),
    
    (17, 5,  1, 89.99,   0, 89.99),
    (17, 15, 1, 44.99,   0, 44.99),
    
    (18, 1,  1, 999.99,  0, 999.99),  
    (18, 3,  1, 349.99,  0, 349.99),  
    
    (19, 11, 1, 79.99,   0, 79.99),
    
    (20, 1,  1, 999.99,  0, 999.99),
    
    (21, 3,  1, 349.99,  0, 349.99),
    
    (22, 6,  1, 199.99,  0, 199.99),
    
    (23, 2,  1, 1299.99, 0, 1299.99),
    (23, 3,  1, 349.99,  0, 349.99),
    
    (24, 5,  1, 89.99,   0, 89.99),
    
    (25, 10, 1, 279.99,  0, 279.99),
    (25, 11, 1, 79.99,   0, 79.99),
    
    (26, 8,  1, 129.99,  0, 129.99),
    
    (27, 15, 1, 44.99,   0, 44.99),
    
    (28, 1,  1, 999.99,  0, 999.99),
    
    (29, 4,  1, 59.99,   0, 59.99),
    
    (30, 10, 1, 279.99,  0, 279.99);


INSERT INTO payments (order_id, payment_method, payment_status, amount, transaction_id, payment_date) VALUES
    (1,  'credit_card',   'completed', 1079.99, 'TXN-20240105-001', '2024-01-05 10:31:00'),
    (2,  'credit_card',   'completed', 1481.77, 'TXN-20240112-001', '2024-01-12 14:16:00'),
    (3,  'paypal',        'completed', 103.17,  'TXN-20240120-001', '2024-01-20 09:46:00'),
    (4,  'debit_card',    'completed', 195.99,  'TXN-20240203-001', '2024-02-03 16:01:00'),
    (5,  'credit_card',   'completed', 377.99,  'TXN-20240214-001', '2024-02-14 11:21:00'),
    (6,  'paypal',        'completed', 146.37,  'TXN-20240228-001', '2024-02-28 13:51:00'),
    (7,  'credit_card',   'completed', 1403.99, 'TXN-20240305-001', '2024-03-05 08:31:00'),
    (8,  'debit_card',    'completed', 108.57,  'TXN-20240315-001', '2024-03-15 17:46:00'),
    (9,  'credit_card',   'completed', 302.39,  'TXN-20240322-001', '2024-03-22 10:11:00'),
    (10, 'credit_card',   'completed', 1083.98, 'TXN-20240401-001', '2024-04-01 12:01:00'),
    (11, 'paypal',        'completed', 189.57,  'TXN-20240410-001', '2024-04-10 15:31:00'),
    (12, 'debit_card',    'completed', 92.38,   'TXN-20240418-001', '2024-04-18 09:01:00'),
    (13, 'credit_card',   'completed', 485.98,  'TXN-20240502-001', '2024-05-02 14:21:00'),
    (14, 'bank_transfer', 'completed', 103.18,  'TXN-20240515-001', '2024-05-15 11:46:00'),
    (15, 'credit_card',   'completed', 280.78,  'TXN-20240528-001', '2024-05-28 16:31:00'),
    (16, 'credit_card',   'completed', 1303.99, 'TXN-20240605-001', '2024-06-05 10:01:00'),
    (17, 'paypal',        'completed', 157.17,  'TXN-20240612-001', '2024-06-12 13:16:00'),
    (18, 'credit_card',   'completed', 566.98,  'TXN-20240620-001', '2024-06-20 08:46:00'),
    (19, 'debit_card',    'completed', 92.38,   'TXN-20240703-001', '2024-07-03 15:01:00'),
    (20, 'credit_card',   'completed', 1079.99, 'TXN-20240710-001', '2024-07-10 12:31:00'),
    (21, 'paypal',        'completed', 342.99,  'TXN-20240718-001', '2024-07-18 09:21:00'),
    (22, 'credit_card',   'completed', 215.99,  'TXN-20240801-001', '2024-08-01 14:01:00'),
    (23, 'credit_card',   'completed', 1781.98, 'TXN-20240812-001', '2024-08-12 11:41:00'),
    (24, 'debit_card',    'completed', 103.18,  'TXN-20240825-001', '2024-08-25 16:16:00'),
    (25, 'credit_card',   'completed', 410.38,  'TXN-20240903-001', '2024-09-03 10:31:00'),
    (26, 'paypal',        'pending',   146.38,  NULL,               '2024-09-15 13:01:00'),
    (27, 'bank_transfer', 'pending',   54.58,   NULL,               '2024-09-22 08:51:00'),
    (28, 'credit_card',   'pending',   1079.99, NULL,               '2024-10-01 15:21:00'),
    (29, 'debit_card',    'pending',   70.78,   NULL,               '2024-10-08 12:11:00'),
    (30, 'credit_card',   'pending',   302.39,  NULL,               '2024-10-15 09:31:00');


INSERT INTO shipping (order_id, carrier, tracking_number, shipping_method, shipping_status, estimated_delivery, actual_delivery, shipped_date) VALUES
    (1,  'FedEx',  'FDX-100001', 'express',   'delivered',       '2024-01-08', '2024-01-07', '2024-01-05 18:00:00'),
    (2,  'UPS',    'UPS-200001', 'standard',  'delivered',       '2024-01-19', '2024-01-18', '2024-01-13 10:00:00'),
    (3,  'USPS',   'USP-300001', 'standard',  'delivered',       '2024-01-27', '2024-01-26', '2024-01-21 09:00:00'),
    (4,  'FedEx',  'FDX-100002', 'express',   'delivered',       '2024-02-06', '2024-02-05', '2024-02-03 20:00:00'),
    (5,  'UPS',    'UPS-200002', 'express',   'delivered',       '2024-02-17', '2024-02-16', '2024-02-14 15:00:00'),
    (6,  'USPS',   'USP-300002', 'standard',  'delivered',       '2024-03-07', '2024-03-06', '2024-02-28 17:00:00'),
    (7,  'FedEx',  'FDX-100003', 'overnight', 'delivered',       '2024-03-06', '2024-03-06', '2024-03-05 12:00:00'),
    (8,  'UPS',    'UPS-200003', 'standard',  'delivered',       '2024-03-22', '2024-03-21', '2024-03-16 10:00:00'),
    (9,  'FedEx',  'FDX-100004', 'express',   'delivered',       '2024-03-25', '2024-03-24', '2024-03-22 14:00:00'),
    (10, 'UPS',    'UPS-200004', 'express',   'delivered',       '2024-04-04', '2024-04-03', '2024-04-01 16:00:00'),
    (11, 'USPS',   'USP-300003', 'standard',  'delivered',       '2024-04-17', '2024-04-16', '2024-04-11 09:00:00'),
    (12, 'FedEx',  'FDX-100005', 'standard',  'delivered',       '2024-04-25', '2024-04-24', '2024-04-19 10:00:00'),
    (13, 'UPS',    'UPS-200005', 'express',   'delivered',       '2024-05-05', '2024-05-04', '2024-05-02 18:00:00'),
    (14, 'USPS',   'USP-300004', 'standard',  'delivered',       '2024-05-22', '2024-05-21', '2024-05-16 09:00:00'),
    (15, 'FedEx',  'FDX-100006', 'express',   'delivered',       '2024-05-31', '2024-05-30', '2024-05-28 20:00:00'),
    (16, 'UPS',    'UPS-200006', 'overnight', 'delivered',       '2024-06-06', '2024-06-06', '2024-06-05 14:00:00'),
    (17, 'USPS',   'USP-300005', 'standard',  'delivered',       '2024-06-19', '2024-06-18', '2024-06-13 09:00:00'),
    (18, 'FedEx',  'FDX-100007', 'express',   'delivered',       '2024-06-23', '2024-06-22', '2024-06-20 12:00:00'),
    (19, 'UPS',    'UPS-200007', 'standard',  'delivered',       '2024-07-10', '2024-07-09', '2024-07-04 10:00:00'),
    (20, 'FedEx',  'FDX-100008', 'express',   'delivered',       '2024-07-13', '2024-07-12', '2024-07-10 16:00:00'),
    (21, 'USPS',   'USP-300006', 'express',   'delivered',       '2024-07-21', '2024-07-20', '2024-07-18 13:00:00'),
    (22, 'UPS',    'UPS-200008', 'standard',  'delivered',       '2024-08-08', '2024-08-07', '2024-08-02 10:00:00'),
    (23, 'FedEx',  'FDX-100009', 'express',   'delivered',       '2024-08-15', '2024-08-14', '2024-08-12 15:00:00'),
    (24, 'USPS',   'USP-300007', 'standard',  'in_transit',      '2024-09-01', NULL,         '2024-08-26 09:00:00'),
    (25, 'UPS',    'UPS-200009', 'express',   'in_transit',      '2024-09-06', NULL,         '2024-09-04 10:00:00'),
    (26, 'FedEx',  'FDX-100010', 'standard',  'pending',         '2024-09-22', NULL,         NULL),
    (27, 'USPS',   'USP-300008', 'standard',  'pending',         '2024-09-29', NULL,         NULL),
    (28, 'UPS',    'UPS-200010', 'express',   'pending',         '2024-10-04', NULL,         NULL),
    (29, 'FedEx',  'FDX-100011', 'standard',  'pending',         '2024-10-15', NULL,         NULL),
    (30, 'UPS',    'UPS-200011', 'express',   'pending',         '2024-10-18', NULL,         NULL);
