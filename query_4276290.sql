WITH wallet_first_tx AS (
    -- 找出每位交易人的首次交易日期
    SELECT 
        user_address,
        MIN(DATE(date)) AS first_tx_date
    FROM 
        query_4274200
    GROUP BY 
        user_address
)

SELECT 
    DATE(query_4274200.date) AS date,
    COUNT(DISTINCT CASE 
        WHEN DATE(query_4274200.date) = wallet_first_tx.first_tx_date THEN query_4274200.user_address
        END) AS new_wallets,
    COUNT(DISTINCT CASE 
        WHEN DATE(query_4274200.date) > wallet_first_tx.first_tx_date THEN query_4274200.user_address
        END) AS existing_wallets
FROM 
    query_4274200
JOIN 
    wallet_first_tx
ON 
    query_4274200.user_address = wallet_first_tx.user_address
GROUP BY 
    DATE(query_4274200.date)
ORDER BY 
    DATE(query_4274200.date) DESC;
