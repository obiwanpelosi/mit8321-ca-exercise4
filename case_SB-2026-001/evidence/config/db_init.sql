CREATE DATABASE IF NOT EXISTS securebank;
USE securebank;

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    password VARCHAR(50) NOT NULL,
    email VARCHAR(100)
);

INSERT INTO users (username, password, email) VALUES
('admin', 'admin123', 'admin@securebank.com'),
('john', 'password123', 'john@securebank.com'),
('jane', 'securepass', 'jane@securebank.com');

CREATE TABLE accounts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    account_type VARCHAR(50),
    balance DECIMAL(10, 2),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

INSERT INTO accounts (user_id, account_type, balance) VALUES
(1, 'Savings', 10000.00),
(1, 'Checking', 5000.00),
(2, 'Savings', 2500.00),
(3, 'Investment', 50000.00);
