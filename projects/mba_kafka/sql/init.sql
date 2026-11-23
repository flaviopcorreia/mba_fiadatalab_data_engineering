-- Criação da tabela de estoque
CREATE TABLE estoque (
    product_id SERIAL PRIMARY KEY,
    nome_produto VARCHAR(150) NOT NULL,
    quantidade INT NOT NULL DEFAULT 0,
    preco_unitario DECIMAL(10, 2) NOT NULL
);

INSERT INTO estoque (nome_produto, quantidade, preco_unitario) 
VALUES 
    ('Camiseta Básica Preta', 50, 49.90),
    ('Tênis de Corrida XYZ', 15, 299.99),
    ('Mochila Impermeável', 30, 150.00),
    ('Garrafa Térmica 500ml', 100, 85.50),
    ('Fone de Ouvido Bluetooth', 25, 199.90),
    ('Óculos de Sol Vintage', 12, 120.00),
    ('Relógio Digital Smart', 40, 350.75),
    ('Caneca de Cerâmica ShopVibe', 80, 25.00);

-- Criação da tabela de orders
CREATE TABLE orders (
    orders_id SERIAL PRIMARY KEY,
    cliente_id VARCHAR(150) NOT NULL,
    total DECIMAL(10, 2) NOT NULL,
    status_orders VARCHAR(150) NOT NULL,
    data_orders TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO orders (cliente_id, total, status_orders) 
VALUES 
    ('CLI-001', 150.50, 'Aprovado'),
    ('CLI-002', 89.90, 'Pendente'),
    ('CLI-003', 1250.00, 'Enviado'),
    ('CLI-001', 349.99, 'Entregue'),
    ('CLI-004', 45.00, 'Cancelado'),
    ('CLI-005', 210.75, 'Aprovado'),
    ('CLI-002', 599.90, 'Em Separação'),
    ('CLI-006', 120.00, 'Entregue');

-- Criação da tabela de itens do orders
CREATE TABLE itens_pedido (
    item_id SERIAL PRIMARY KEY,
    orders_id INT NOT NULL REFERENCES orders(orders_id),
    product_id INT NOT NULL REFERENCES estoque(product_id),
    quantidade INT NOT NULL,
    preco_unitario DECIMAL(10, 2) NOT NULL
);

INSERT INTO itens_pedido (orders_id, product_id, quantidade, preco_unitario) 
VALUES 
    -- orders 1 (Total: 150.50) -> 1 Mochila Impermeável
    (1, 3, 1, 150.00),
    
    -- orders 2 (Total: 89.90) -> 1 Garrafa Térmica
    (2, 4, 1, 85.50),
    
    -- orders 3 (Total: 1250.00) -> 4 Tênis de Corrida
    (3, 2, 4, 299.99),
    
    -- orders 4 (Total: 349.99) -> 1 Tênis + 1 Camiseta (Exemplo com 2 itens no mesmo orders)
    (4, 2, 1, 299.99),
    (4, 1, 1, 49.90),
    
    -- orders 5 (Total: 45.00) -> 2 Canecas de Cerâmica
    (5, 8, 2, 25.00),
    
    -- orders 7 (Total: 599.90) -> 3 Fones de Ouvido
    (7, 5, 3, 199.90),
    
    -- orders 8 (Total: 120.00) -> 1 Óculos de Sol
    (8, 6, 1, 120.00);

-- Criação da tabela de carrinho
CREATE TABLE carrinho (
    carrinho_id SERIAL PRIMARY KEY,
    session_id VARCHAR(150) NOT NULL,
    product_id INT NOT NULL REFERENCES estoque(product_id),
    cliente_id VARCHAR(150) NOT NULL,
    action VARCHAR(150) NOT NULL,
    data_acao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
