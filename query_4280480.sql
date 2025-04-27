-- https://dune.com/data/prices.usd_forward_fill(legacy)

WITH yei_contracts AS (
    SELECT 
        symbol,
        underlying_token
    FROM query_4261812
)

, price_by_token AS (
    SELECT
        CAST(p.minute AS DATE) AS date,
        y.symbol,
        AVG(p.price) AS usd_price
    FROM
        prices.usd_forward_fill p
    INNER JOIN
        yei_contracts y
    ON
        p.contract_address = y.underlying_token
    WHERE
        p.minute >= CURRENT_DATE - INTERVAL '1' YEAR
    GROUP BY
        CAST(p.minute AS DATE), y.symbol
)

, price_by_symbol AS (
    SELECT
        CAST(minute AS DATE) AS date,
        symbol,
        AVG(price) AS usd_price
    FROM
        prices.usd_forward_fill
    WHERE
        symbol IN ('USDC','kavaUSDT', 'SEI', 'WSEI', 'ETH', 'WETH', 'FRAX', 'BTC', 'WBTC', 
                   'fastUSD', 'sfastUSD', 'frxUSD', 'sfrxUSD', 'sfrxETH', 'SolvBTC', 
                   'frxETH', 'wstETH', 'xSolvBTC', 'USDT0')
        AND (symbol <> 'ETH' OR price > 1)
        AND minute >= CURRENT_DATE - INTERVAL '1' YEAR
    GROUP BY
        CAST(minute AS DATE), symbol
)

, combined_prices AS (
    SELECT
        p.date,
        p.symbol,
        p.usd_price,
        'token_address' AS source
    FROM
        price_by_token p
    
    UNION ALL
    
    SELECT
        s.date,
        s.symbol,
        s.usd_price,
        'symbol' AS source
    FROM
        price_by_symbol s
    WHERE NOT EXISTS (
        SELECT 1
        FROM price_by_token pt
        WHERE pt.date = s.date
          AND pt.symbol = s.symbol
    )
)

, manual_override AS (
    SELECT date, 'sfastUSD' AS symbol, usd_price, 'manual_override' AS source FROM combined_prices WHERE symbol = 'frxUSD'
    UNION ALL
    SELECT date, 'fastUSD' AS symbol, usd_price, 'manual_override' AS source FROM combined_prices WHERE symbol = 'frxUSD'
    UNION ALL
    SELECT DISTINCT date, 'sfrxUSD' AS symbol, 1 AS usd_price, 'manual_override' AS source FROM combined_prices
    UNION ALL
    SELECT date, 'sFRAX' AS symbol, usd_price, 'manual_override' AS source FROM combined_prices WHERE symbol = 'FRAX'
    UNION ALL
    SELECT date, 'iSEI' AS symbol, usd_price, 'manual_override' AS source FROM combined_prices WHERE symbol = 'SEI'
    UNION ALL
    SELECT date, 'sfrxETH' AS symbol, usd_price, 'manual_override' AS source FROM combined_prices WHERE symbol = 'ETH'
)

SELECT
    date,
    symbol,
    usd_price,
    source
FROM (
    SELECT * FROM combined_prices
    UNION ALL
    SELECT * FROM manual_override
) final

ORDER BY
    date DESC, symbol;
