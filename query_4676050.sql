WITH contract_addresses AS (
  SELECT
    0xDCC0CfA48eCaD4ce2fB35d259964eEBF7D38FFA7 AS eth_address,
    0x5461fEc48EC5048200Bc47f37028D075eCdA6e58 AS arb_address,
    0x1995C946cB7c74c3EbDA3BE5EEcBD6559CfFdce4 AS op_address,
    0xe78625491B358873516CeEd3450ba547585193bF AS avax_address,
    0xDCC0CfA48eCaD4ce2fB35d259964eEBF7D38FFA7 as polygon_address,
    0xDCC0CfA48eCaD4ce2fB35d259964eEBF7D38FFA7 as base_address
),
usdc_addresses AS (
  SELECT
    0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48 AS eth_usdc, /* Ethereum USDC */
    0xaf88d065e77c8cC2239327C5EDb3A432268e5831 AS arb_usdc, /* Arbitrum USDC */
    0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85 AS op_usdc, /* Optimism USDC */
    0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E as avax_usdc, /* Avalanche C-Chain USDC */
    0x3c499c542cef5e3811e1192ce70d8cc03d5c3359 as polygon_usdc, /* Polygon PoS USDC */
    0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913 as base_usdc /* Base USDC */
),
all_transactions AS (
  SELECT
    evt_block_time AS block_time,
    "from",
    "to",
    value / 1e6 AS usdc_value, /* USDC has 6 decimals */
    'ethereum' AS chain
  FROM erc20_ethereum.evt_Transfer
  WHERE
    contract_address = (
      SELECT
        eth_usdc
      FROM usdc_addresses
    )
    AND "to" = (
      SELECT
        eth_address
      FROM contract_addresses
    )
  UNION ALL
  SELECT
    evt_block_time AS block_time,
    "from",
    "to",
    value / 1e6 AS usdc_value,
    'arbitrum' AS chain
  FROM erc20_arbitrum.evt_Transfer
  WHERE
    contract_address = (
      SELECT
        arb_usdc
      FROM usdc_addresses
    )
    AND "to" = (
      SELECT
        arb_address
      FROM contract_addresses
    )
  UNION ALL
  SELECT
    evt_block_time AS block_time,
    "from",
    "to",
    value / 1e6 AS usdc_value,
    'optimism' AS chain
  FROM erc20_optimism.evt_Transfer
  WHERE
    contract_address = (
      SELECT
        op_usdc
      FROM usdc_addresses
    )
    AND "to" = (
      SELECT
        op_address
      FROM contract_addresses
    )
  UNION ALL
  SELECT
    evt_block_time AS block_time,
    "from",
    "to",
    value / 1e6 AS usdc_value,
    'avalanche' AS chain
  FROM erc20_avalanche_c.evt_Transfer
  WHERE
    contract_address = (
      SELECT
        avax_usdc
      FROM usdc_addresses
    )
    AND "to" = (
      SELECT
        avax_address
      FROM contract_addresses
    )
  UNION ALL
  SELECT
    evt_block_time AS block_time,
    "from",
    "to",
    value / 1e6 AS usdc_value,
    'polygon' AS chain
  FROM erc20_polygon.evt_Transfer
  WHERE
    contract_address = (
      SELECT
        polygon_usdc
      FROM usdc_addresses
    )
    AND "to" = (
      SELECT
        polygon_address
      FROM contract_addresses
    )
  UNION ALL
  SELECT
    evt_block_time AS block_time,
    "from",
    "to",
    value / 1e6 AS usdc_value,
    'base' AS chain
  FROM erc20_base.evt_Transfer
  WHERE
    contract_address = (
      SELECT
        base_usdc
      FROM usdc_addresses
    )
    AND "to" = (
      SELECT
        base_address
      FROM contract_addresses
    )
),
daily_users_by_chain AS (
  SELECT
    DATE_TRUNC('day', block_time) AS date,
    chain,
    COUNT(DISTINCT "from") AS unique_users
  FROM all_transactions
  GROUP BY
    1,
    2
  ORDER BY
    1,
    2
),
total_daily_users AS (
  SELECT
    DATE_TRUNC('day', block_time) AS date,
    COUNT(
      DISTINCT CONCAT(
        CAST(COALESCE(CAST(COALESCE(TRY_CAST("from" AS VARCHAR), '') AS VARCHAR), '') AS VARCHAR),
        CAST(COALESCE(CAST(COALESCE(TRY_CAST(chain AS VARCHAR), '') AS VARCHAR), '') AS VARCHAR)
      )
    ) AS total_unique_users,
    COUNT(DISTINCT "from") AS cross_chain_unique_users
  FROM all_transactions
  GROUP BY
    1
),
daily_volume_by_chain AS (
  SELECT
    DATE_TRUNC('day', block_time) AS date,
    chain,
    COUNT(*) AS num_transactions,
    SUM(usdc_value) AS volume
  FROM all_transactions
  GROUP BY
    1,
    2
  ORDER BY
    1,
    2
),
daily_metrics AS (
  SELECT
    d.date,
    d.chain,
    d.unique_users AS chain_users,
    t.cross_chain_unique_users,
    v.num_transactions,
    ROUND(v.volume, 2) AS usdc_volume
  FROM daily_users_by_chain AS d
  LEFT JOIN total_daily_users AS t
    ON d.date = t.date
  LEFT JOIN daily_volume_by_chain AS v
    ON d.date = v.date AND d.chain = v.chain
)
SELECT
  date,
  SUM(usdc_volume) AS total_usdc_volume,
  SUM(SUM(usdc_volume)) OVER (ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS accumulated_volume
FROM daily_metrics
GROUP BY
  date
ORDER BY
  date DESC;
