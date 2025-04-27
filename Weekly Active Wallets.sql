WITH wallet_first_tx AS (
    -- 找出每位交易人的首次交易日期
    SELECT 
        user_address,
        MIN(DATE(date)) AS first_tx_date
    FROM 
        query_4274200
    GROUP BY 
        user_address
),
weekly_transactions AS (
    SELECT 
        -- 将每周的起始日期调整为星期三
        DATE_ADD('day', 1, DATE_TRUNC('week', DATE(t.date))) AS week_start_date,  -- 将星期一的日期加2天，得到星期三
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
    week_start_date,
    COUNT(DISTINCT CASE 
        WHEN week_start_date = DATE_ADD('day', 1, DATE_TRUNC('week', first_tx_date)) THEN user_address
        END) AS new_users,
    COUNT(DISTINCT CASE 
        WHEN week_start_date > DATE_ADD('day', 1, DATE_TRUNC('week', first_tx_date)) THEN user_address
        END) AS existing_users
FROM 
    weekly_transactions
GROUP BY 
    week_start_date
ORDER BY 
    week_start_date DESC;
