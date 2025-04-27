WITH SupplyWithdraw AS (
    SELECT 
        symbol,
        user_address,
        SUM(CASE WHEN type = 'Supply' THEN tokens ELSE 0 END) AS total_supply,
        SUM(CASE WHEN type = 'Withdraw' THEN tokens ELSE 0 END) AS total_withdraw,
        SUM(CASE WHEN type = 'Supply' THEN tokens ELSE 0 END) -
        SUM(CASE WHEN type = 'Withdraw' THEN tokens ELSE 0 END) AS atoken
    FROM query_4274200
    GROUP BY symbol, user_address
),
BorrowRepay AS (
    SELECT 
        symbol,
        user_address,
        SUM(CASE WHEN type = 'Borrow' THEN tokens ELSE 0 END) AS total_borrow,
        SUM(CASE WHEN type = 'Repay' THEN tokens ELSE 0 END) AS total_repay,
        SUM(CASE WHEN type = 'Borrow' THEN tokens ELSE 0 END) -
        SUM(CASE WHEN type = 'Repay' THEN tokens ELSE 0 END) AS debt_token
    FROM dune.yei.result_all_tx
    GROUP BY symbol, user_address
),
Users AS (
    SELECT 
        sw.symbol,
        sw.user_address,
        sw.atoken,
        br.debt_token,
        LEAST(sw.atoken, COALESCE(br.debt_token, 0)) AS looping_portion
    FROM SupplyWithdraw sw
    LEFT JOIN BorrowRepay br
    ON sw.symbol = br.symbol AND sw.user_address = br.user_address
),
LoopingSummary AS (
    SELECT 
        symbol,
        SUM(looping_portion) AS total_looped_token,
        SUM(COALESCE(debt_token, 0)) AS total_debt_token
    FROM Users
    GROUP BY symbol
)
SELECT 
    symbol,
    ROUND(total_looped_token, 3) AS looped_token,
    ROUND((total_debt_token - total_looped_token),3) AS non_looped_token,
    ROUND(total_debt_token, 3) AS total_debt,
    ROUND(total_looped_token / NULLIF(total_debt_token, 0), 3) AS looping_ratio
FROM LoopingSummary
ORDER BY looping_ratio;
