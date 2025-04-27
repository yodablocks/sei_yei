WITH SupplyWithdraw AS (
    SELECT 
        symbol,
        user_address,
        SUM(CASE WHEN type = 'Supply' THEN tokens ELSE 0 END) -
        SUM(CASE WHEN type = 'Withdraw' THEN tokens ELSE 0 END) AS atoken,
        SUM(CASE WHEN type = 'Supply' THEN usd_value ELSE 0 END) -
        SUM(CASE WHEN type = 'Withdraw' THEN usd_value ELSE 0 END) AS a_usd_value
    FROM dune.yei.result_all_tx
    GROUP BY symbol, user_address
),
BorrowRepay AS (
    SELECT 
        symbol,
        user_address,
        SUM(CASE WHEN type = 'Borrow' THEN tokens ELSE 0 END) -
        SUM(CASE WHEN type = 'Repay' THEN tokens ELSE 0 END) AS debt_token,
        SUM(CASE WHEN type = 'Borrow' THEN usd_value ELSE 0 END) -
        SUM(CASE WHEN type = 'Repay' THEN usd_value ELSE 0 END) AS debt_value
    FROM dune.yei.result_all_tx
    GROUP BY symbol, user_address
)
SELECT 
    sw.symbol,
    sw.user_address,
    sw.atoken,
    sw.a_usd_value,
    br.debt_token,
    br.debt_value,
    CASE 
        -- WHEN sw.atoken >= br.debt_token THEN TRUE
        WHEN sw.atoken >= 0 THEN TRUE
        ELSE FALSE
    END AS is_loopingUser
FROM SupplyWithdraw sw
LEFT JOIN BorrowRepay br
ON sw.symbol = br.symbol AND sw.user_address = br.user_address
WHERE br.debt_token < 0
ORDER BY symbol ASC;
