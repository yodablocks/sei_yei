SELECT
    type,
    date,
    user_address,
    symbol,
    tokens,
    usd_value
FROM query_4274200
WHERE symbol = 'USDT0'
  -- AND DATE(date) BETWEEN DATE('2025-04-15') AND DATE('2025-04-17')
  AND type IN ('Withdraw')
  
ORDER BY tokens DESC;
