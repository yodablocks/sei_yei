SELECT
    type,
    date,
    user_address,
    symbol,
    tokens,
    usd_value
FROM dune.yei.result_all_tx
WHERE symbol = 'FRAX'
  -- AND DATE(date) BETWEEN DATE('2025-01-22') AND DATE('2025-01-23')
  -- AND type IN ('Borrow', 'Repay')
  AND type IN ('Supply', 'Withdraw')
  -- AND user_address = from_hex('78ec6878fce16aad4ea556843fc383285f1ee2f1') USDT
  AND user_address = from_hex('278b6d79c430c3e1a6893160cf66a0d0cd03ec43')

ORDER BY tokens DESC;
