CREATE TABLE IF NOT EXISTS customer_finance_transactions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    transaction_type VARCHAR(30) NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    balance_before DECIMAL(15,2) NOT NULL,
    balance_after DECIMAL(15,2) NOT NULL,
    currency VARCHAR(3) NOT NULL,
    effective_date DATE NOT NULL,
    reference VARCHAR(120) NULL,
    note TEXT NULL,
    created_by VARCHAR(100) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_customer_finance_tx_customer (customer_id),
    INDEX idx_customer_finance_tx_type (transaction_type),
    INDEX idx_customer_finance_tx_effective_date (effective_date),
    CONSTRAINT fk_customer_finance_tx_customer FOREIGN KEY (customer_id) REFERENCES customers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
