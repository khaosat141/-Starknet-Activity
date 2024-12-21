WITH strk_tx_summary AS (
    SELECT block_date, block_time, block_number, hash, block_l1_da_mode, block_l1_data_gas_price_in_fri, block_l1_data_gas_price_in_wei,
           block_l1_gas_price_in_fri, block_l1_gas_price_in_wei, actual_fee_amount, actual_fee_unit, sender_address,
           p.symbol, p.price,
           p.price * actual_fee_amount / pow(10, 18) AS fee_usd,
           actual_fee_amount / pow(10, 18) AS fee_adj,
           p.symbol AS fee_token
    FROM starknet.transactions t 
    LEFT JOIN prices.usd_daily p 
    ON p.contract_address IS NULL
       AND p.day = t.block_date
       AND (CASE 
                WHEN t.actual_fee_unit = 'FRI' THEN 'STRK' 
                WHEN t.actual_fee_unit = 'WEI' THEN 'ETH' 
            END) = p.symbol
    WHERE block_date >= DATE('2023-01-01')
),
daily_summary AS (
    SELECT date_trunc('day',block_date) as dt,
           SUM(fee_usd) AS fees_usd,
           SUM(CASE WHEN symbol = 'STRK' THEN fee_usd ELSE 0 END) AS fees_usd_paid_in_strk,
           SUM(CASE WHEN symbol = 'STRK' THEN fee_usd ELSE 0 END) / SUM(fee_usd) AS pct_value_paid_in_stark,
           SUM(CASE WHEN symbol = 'STRK' THEN CAST(1 AS double) ELSE CAST(0 AS double) END) / COUNT(*) AS pct_tx_paid_in_stark,
           COUNT(*) AS transactions,
           COUNT(DISTINCT sender_address) AS unique_senders,
           COUNT(sender_address) AS tx_with_sender
    FROM strk_tx_summary
    GROUP BY date_trunc('day',block_date)
),
rolling_summary AS (
    SELECT dt,
           fees_usd,
           fees_usd/transactions as cost_per_tx,
           fees_usd_paid_in_strk,
           pct_value_paid_in_stark,
           pct_tx_paid_in_stark,
           transactions,
           transactions/(24*60*60.0) as tps,
           unique_senders,
           tx_with_sender,
           SUM(fees_usd_paid_in_strk) OVER (
               ORDER BY dt
               ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
           ) / SUM(fees_usd) OVER (
               ORDER BY dt
               ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
           ) AS weighted_rolling_7d_avg_pct_value_paid_in_stark
    FROM daily_summary
)
SELECT * 
FROM rolling_summary
WHERE dt < date_trunc('day',now())
ORDER BY dt;
