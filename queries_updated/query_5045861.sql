WITH
-- Define the symbols, contracts and decimals once
transfer_symbol AS (
    SELECT
        symbol,
        a_token AS supply_contract,
        debt_token AS borrow_contract,
        decimal
    FROM query_5045834
),

-- Create a unified view of all transactions with their types
all_tx AS (
    -- Borrow transactions (debt token transfers to users)
    SELECT
        'Borrow' AS type,
        evt_block_time AS date,
        contract_address,
        "to" AS user_address,
        ts.symbol,
        "value" AS value
    FROM erc20_sei.evt_Transfer et
    JOIN transfer_symbol ts ON et.contract_address = ts.borrow_contract
    WHERE "to" != 0x0000000000000000000000000000000000000000
    
    UNION ALL
    
    -- Repay transactions (debt token transfers from users)
    SELECT
        'Repay' AS type,
        evt_block_time AS date,
        contract_address,
        "from" AS user_address,
        ts.symbol,
        "value" AS value
    FROM erc20_sei.evt_Transfer et
    JOIN transfer_symbol ts ON et.contract_address = ts.borrow_contract
    WHERE "from" != 0x0000000000000000000000000000000000000000
    
    UNION ALL
    
    -- Supply transactions (supply token transfers to users)
    SELECT
        'Supply' AS type,
        evt_block_time AS date,
        contract_address,
        "to" AS user_address,
        ts.symbol,
        "value" AS value
    FROM erc20_sei.evt_Transfer et
    JOIN transfer_symbol ts ON et.contract_address = ts.supply_contract
    WHERE "to" != 0x0000000000000000000000000000000000000000
    
    UNION ALL
    
    -- Withdraw transactions (supply token transfers from users)
    SELECT
        'Withdraw' AS type,
        evt_block_time AS date,
        contract_address,
        "from" AS user_address,
        ts.symbol,
        "value" AS value
    FROM erc20_sei.evt_Transfer et
    JOIN transfer_symbol ts ON et.contract_address = ts.supply_contract
    WHERE "from" != 0x0000000000000000000000000000000000000000
)

-- Calculate token amounts and USD values
SELECT
    tx.type, 
    tx.date, 
    tx.user_address, 
    tx.symbol,
    CAST(tx.value AS DOUBLE) / POWER(10, ts.decimal) AS tokens,
    (CAST(tx.value AS DOUBLE) / POWER(10, ts.decimal)) * u.usd_price AS usd_value
FROM all_tx tx
JOIN transfer_symbol ts ON tx.symbol = ts.symbol
LEFT JOIN query_4280480 u ON tx.symbol = u.symbol AND DATE(tx.date) = u.date
ORDER BY date DESC
