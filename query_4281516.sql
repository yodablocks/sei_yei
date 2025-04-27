-- ref: https://docs.dune.com/data-catalog/curated/prices/overview#price-tables
-- https://dune.com/data/prices.day
-- NOTE: 如果在 'sei' 沒有資料，就改查詢 'ethereum'，且 'ethereum' 必須有價格資料
-- NOTE: 有些值失真(2024-11-04 USDT 是 697426000000000000)

WITH daily_price AS (
    SELECT
        timestamp AS date,
        symbol,
        AVG(price) AS usd_price
    FROM
        prices.day
    WHERE
    -- NOTE: curated_data 沒有 'iSEI', 'fastUSD' -> 用 SEI 的值當 iSEI, fastUSD 用 1 USD 計算
        symbol IN ('USDC', 'USDT', 'SEI','WSEI','ETH','WETH','FRAX','BTC', 'WBTC', 'fastUSD', 'sfastUSD', 'frxUSD', 'sfrxUSD', 'sfrxETH', 'SolvBTC', 'frxETH')
        AND (
            blockchain = 'sei' 
            OR (blockchain = 'ethereum' AND price IS NOT NULL)
        )  -- 如果在 'sei' 沒有資料，就改查詢 'ethereum'，且 'ethereum' 必須有價格資料
        AND year >= 2024
    GROUP BY
        timestamp, symbol
)

SELECT
    date,
    symbol,
    usd_price
FROM
    daily_price
UNION ALL

SELECT DISTINCT
    date,
    'fastUSD' AS symbol,
    1 AS usd_price
FROM
    daily_price
GROUP BY
    date
UNION ALL

SELECT DISTINCT
    date,
    'iSEI' AS symbol,
    usd_price
FROM
    daily_price
WHERE
    symbol = 'SEI'

ORDER BY date DESC, symbol
