WITH wallet_first_tx AS (
    -- 找出每位交易人的首次交易日期
    SELECT 
        user_address,
        MIN(DATE(date)) AS first_tx_date
    FROM 
        dune.yei.result_all_tx
    WHERE usd_value > 10
    GROUP BY 
        user_address
),
daily_new_users AS (
    SELECT 
        DATE(dune.yei.result_all_tx.date) AS date,
        COUNT(DISTINCT CASE 
            WHEN DATE(dune.yei.result_all_tx.date) = wallet_first_tx.first_tx_date THEN dune.yei.result_all_tx.user_address
        END) AS new_wallets
    FROM 
        dune.yei.result_all_tx
    LEFT JOIN 
        wallet_first_tx
    ON 
        dune.yei.result_all_tx.user_address = wallet_first_tx.user_address
    GROUP BY 
        DATE(dune.yei.result_all_tx.date)
),
accumulative_users AS (
    SELECT 
        date,
        SUM(new_wallets) OVER (ORDER BY date) AS accumulative_wallets
    FROM 
        daily_new_users
)

SELECT 
    daily_new_users.date,
    daily_new_users.new_wallets,
    accumulative_users.accumulative_wallets
FROM 
    daily_new_users
JOIN 
    accumulative_users
ON 
    daily_new_users.date = accumulative_users.date
ORDER BY 
    daily_new_users.date DESC;
