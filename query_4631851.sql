WITH AllDebt AS (
    -- 計算每個 symbol 的總借款 (Borrow - Repay)
    SELECT 
        symbol,
        SUM(CASE WHEN type = 'Borrow' THEN tokens ELSE 0 END) -
        SUM(CASE WHEN type = 'Repay' THEN tokens ELSE 0 END) AS total_debt_token
    FROM dune.yei.result_all_tx
    GROUP BY symbol
),
LoopingUsers AS (
    -- 計算每個 symbol 的 Looping User 相關數據
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
        br.debt_value
    FROM SupplyWithdraw sw
    LEFT JOIN BorrowRepay br
    ON sw.symbol = br.symbol AND sw.user_address = br.user_address
    WHERE COALESCE(sw.atoken,0) >= COALESCE(br.debt_token, 0) -- 只取出 Looping User
),
LoopingDebt AS (
    SELECT 
        symbol,
        SUM(debt_token) AS looping_debt,
        SUM(atoken) AS total_atoken
    FROM LoopingUsers
    GROUP BY symbol
)
SELECT 
    a.symbol,
    l.looping_debt AS looping_debt,
    ROUND((a.total_debt_token - COALESCE(l.looping_debt, 0)), 3) AS non_looping_debt,
    ROUND(a.total_debt_token,3) AS total_debt
    -- ROUND((l.looping_debt / a.total_debt_token), 3) AS looping_debt_ratio,
    -- ROUND((l.looping_debt / l.total_atoken), 3) AS looping_ratio
FROM AllDebt a
LEFT JOIN LoopingDebt l
ON a.symbol = l.symbol
ORDER BY a.symbol ASC;
