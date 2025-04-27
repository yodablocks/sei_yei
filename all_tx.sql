-- This table shows all transaction record.

WITH
transfer_symbol AS (
    SELECT
    symbol,
    a_token AS supply_contract,
    debt_token AS borrow_contract,
    decimal
    FROM query_4261812
),

all_tx AS(
    SELECT
        'Borrow' AS type,
        evt_block_time AS date,
        contract_address,
        "to" AS user_address,
        transfer_symbol.symbol AS symbol,
        "value" AS value
    FROM erc20_sei.evt_Transfer
    -- find contract address from yei_contract query result
    LEFT JOIN transfer_symbol
    ON erc20_sei.evt_Transfer.contract_address = transfer_symbol.borrow_contract
    WHERE contract_address IN (
        SELECT debt_token
        FROM query_4261812
    )AND
    -- filter out data with user_address = 0x00000
    "to" != 0x0000000000000000000000000000000000000000
    
    UNION ALL

        SELECT
        'Repay' AS type,
        evt_block_time AS date,
        contract_address,
        "from" AS user_address,
        transfer_symbol.symbol AS symbol,
        "value" AS value
    FROM erc20_sei.evt_Transfer
    -- find contract address from yei_contract query result
    LEFT JOIN transfer_symbol
    ON erc20_sei.evt_Transfer.contract_address = transfer_symbol.borrow_contract
    WHERE contract_address IN (
        SELECT debt_token
        FROM query_4261812
    )AND
    -- filter out data with user_address = 0x00000
    "from" != 0x0000000000000000000000000000000000000000
    
    UNION ALL

    SELECT
        'Supply' AS type,
        evt_block_time AS date,
        contract_address,
        "to" AS user_address,
        transfer_symbol.symbol AS symbol,
        "value" AS value
    FROM erc20_sei.evt_Transfer
    -- find contract address from yei_contract query result
    LEFT JOIN transfer_symbol
    ON erc20_sei.evt_Transfer.contract_address = transfer_symbol.supply_contract
    WHERE contract_address IN (
        SELECT a_token
        FROM query_4261812
    )AND
    -- filter out data with user_address = 0x00000
    "to" != 0x0000000000000000000000000000000000000000

    UNION ALL

    SELECT
        'Withdraw' AS type,
        evt_block_time AS date,
        contract_address,
        "from" AS user_address,
        transfer_symbol.symbol AS symbol,
        "value" AS value
    FROM erc20_sei.evt_Transfer
    -- find contract address from yei_contract query result
    LEFT JOIN transfer_symbol
    ON erc20_sei.evt_Transfer.contract_address = transfer_symbol.supply_contract
    WHERE contract_address IN (
        SELECT a_token
        FROM query_4261812
    )AND
    -- filter out data with user_address = 0x00000
    "from" != 0x0000000000000000000000000000000000000000
)


SELECT
    all_tx.type, all_tx.date, all_tx.user_address, all_tx.symbol,
    CAST(all_tx.value AS DOUBLE) / POWER(10, s.decimal) AS tokens,  -- 調整小數點後的交易金額
    (CAST(all_tx.value AS DOUBLE) / POWER(10, s.decimal)) * u.usd_price AS usd_value  -- 調整後的金額乘以匯率計算美元金額
FROM all_tx
LEFT JOIN query_4280480 u
ON 
    all_tx.symbol = u.symbol
    AND DATE(all_tx.date) = u.date
JOIN transfer_symbol s
ON
    all_tx.symbol = s.symbol

ORDER BY date DESC
