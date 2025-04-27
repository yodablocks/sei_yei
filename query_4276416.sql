WITH wallet_first_tx AS (
    -- 找出每位交易人的首次交易日期
    SELECT 
        user_address,
        MIN(DATE(date)) AS first_tx_date
    FROM 
        query_4274200
    WHERE
        type = 'Supply'
        AND usd_value > 10
    GROUP BY 
        user_address
),
monthly_transactions AS (
    SELECT 
        DATE_TRUNC('month', DATE(t.date)) AS month_start_date,  -- 將日期截取為每週的開始日期
        t.user_address,
        ft.first_tx_date
    FROM 
        query_4274200 t
    JOIN 
        wallet_first_tx ft 
    ON 
        t.user_address = ft.user_address
)

SELECT 
    month_start_date,
    COUNT(DISTINCT CASE 
        WHEN month_start_date = DATE_TRUNC('month', first_tx_date) THEN user_address
        END) AS new_users,
    COUNT(DISTINCT CASE 
        WHEN month_start_date > DATE_TRUNC('month', first_tx_date) THEN user_address
        END) AS existing_users
FROM 
    monthly_transactions
GROUP BY 
    month_start_date
ORDER BY 
    month_start_date DESC;
