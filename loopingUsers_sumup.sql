WITH SupplyWithdraw AS (
    SELECT 
        symbol,
        user_address,
        SUM(CASE WHEN type = 'Supply' THEN tokens ELSE 0 END) AS total_supply,
        SUM(CASE WHEN type = 'Withdraw' THEN tokens ELSE 0 END) AS total_withdraw,
        SUM(CASE WHEN type = 'Supply' THEN usd_value ELSE 0 END) AS total_supply_usd,
        SUM(CASE WHEN type = 'Withdraw' THEN usd_value ELSE 0 END) AS total_withdraw_usd,
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
        SUM(CASE WHEN type = 'Borrow' THEN tokens ELSE 0 END) AS total_borrow,
        SUM(CASE WHEN type = 'Repay' THEN tokens ELSE 0 END) AS total_repay,
        SUM(CASE WHEN type = 'Borrow' THEN usd_value ELSE 0 END) AS total_borrow_usd,
        SUM(CASE WHEN type = 'Repay' THEN usd_value ELSE 0 END) AS total_repay_usd,
        SUM(CASE WHEN type = 'Borrow' THEN tokens ELSE 0 END) -
        SUM(CASE WHEN type = 'Repay' THEN tokens ELSE 0 END) AS debt_token,
        SUM(CASE WHEN type = 'Borrow' THEN usd_value ELSE 0 END) -
        SUM(CASE WHEN type = 'Repay' THEN usd_value ELSE 0 END) AS debt_value
    FROM dune.yei.result_all_tx
    GROUP BY symbol, user_address
),
Users AS (
    SELECT 
        sw.symbol,
        sw.user_address,
        sw.total_supply,
        sw.total_withdraw,
        sw.total_supply_usd,
        sw.total_withdraw_usd,
        br.total_borrow,
        br.total_repay,
        br.total_borrow_usd,
        br.total_repay_usd,
        sw.atoken,
        sw.a_usd_value,
        br.debt_token,
        br.debt_value,
        CASE 
            WHEN sw.atoken >= COALESCE(br.debt_token, 0) THEN TRUE
            ELSE FALSE
        END AS is_loopingUser
    FROM SupplyWithdraw sw
    LEFT JOIN BorrowRepay br
    ON sw.symbol = br.symbol AND sw.user_address = br.user_address
),
LoopingUsers AS (
    SELECT *
    FROM Users
    WHERE is_loopingUser = TRUE
),
AllUsersAggregated AS (
    SELECT 
        symbol,
        SUM(total_supply) AS total_supply,
        SUM(total_withdraw) AS total_withdraw,
        SUM(total_borrow) AS total_borrow,
        SUM(total_repay) AS total_repay
    FROM Users
    GROUP BY symbol
),
LoopingUsersAggregated AS (
    SELECT 
        symbol,
        SUM(total_supply) AS looping_supply,
        SUM(total_withdraw) AS looping_withdraw,
        SUM(total_borrow) AS looping_borrow,
        SUM(total_repay) AS looping_repay,
        SUM(atoken) AS looping_atoken,
        SUM(a_usd_value) AS looping_a_usd_value,
        SUM(debt_token) AS looping_debt_token,
        SUM(debt_value) AS looping_debt_value
    FROM LoopingUsers
    GROUP BY symbol
)
SELECT 
    a.symbol,
    l.looping_supply,
    l.looping_withdraw,
    l.looping_atoken,
    l.looping_a_usd_value,
    a.total_supply,
    a.total_withdraw,
    l.looping_borrow,
    l.looping_repay,
    l.looping_debt_token,
    l.looping_debt_value,
    a.total_borrow,
    a.total_repay
FROM AllUsersAggregated a
LEFT JOIN LoopingUsersAggregated l
ON a.symbol = l.symbol
ORDER BY a.symbol ASC;
